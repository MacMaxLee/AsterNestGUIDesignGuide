import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS Validation Layer (§5)
///
/// Key requirements:
/// - One shared, platform-free layer (NO UI framework dependency)
/// - Validators return ALL failures, not the first
/// - No validator defaults to one country
/// - Money: exact decimal, never regex, never floating point
/// - Ambiguous dates rejected, not guessed
/// - Time without timezone is invalid

/// Validation result structure
class AisValidationResult {
  final bool isValid;
  final String? errorCode;
  final String? userMessage;
  final dynamic normalizedValue;

  const AisValidationResult({
    required this.isValid,
    this.errorCode,
    this.userMessage,
    this.normalizedValue,
  });

  const AisValidationResult.valid(this.normalizedValue)
      : isValid = true,
        errorCode = null,
        userMessage = null;

  const AisValidationResult.invalid(this.errorCode, this.userMessage)
      : isValid = false,
        normalizedValue = null;
}

/// Composable validation results
class AisCompositeValidationResult {
  final List<AisValidationResult> results;

  const AisCompositeValidationResult(this.results);

  bool get isValid => results.every((r) => r.isValid);

  List<AisValidationResult> get errors =>
      results.where((r) => !r.isValid).toList();
}

/// AIS Validators - Platform-free (§5.1)
/// NOTE: In a real app, this would be in a separate pure Dart package
/// with NO Flutter imports (enforced by source scan)
class AisValidators {
  // C-20: No validator defaults to one country
  static AisValidationResult validateEmail(String value) {
    // §5.2: Permissive pattern, reject clearly malformed
    // Real validation is confirmation message
    if (value.isEmpty) {
      return const AisValidationResult.invalid(
        'EMAIL_REQUIRED',
        'Email address is required',
      );
    }

    // Permissive check - must have @ and domain
    final atIndex = value.indexOf('@');
    if (atIndex < 1 || atIndex == value.length - 1) {
      return const AisValidationResult.invalid(
        'EMAIL_INVALID_FORMAT',
        'Please enter a valid email address',
      );
    }

    final domain = value.substring(atIndex + 1);
    if (!domain.contains('.') || domain.endsWith('.')) {
      return const AisValidationResult.invalid(
        'EMAIL_INVALID_DOMAIN',
        'Please enter a valid email address',
      );
    }

    return AisValidationResult.valid(value.toLowerCase().trim());
  }

  // §5.2: URL - Native parser, not regex
  static AisValidationResult validateUrl(String value) {
    if (value.isEmpty) {
      return const AisValidationResult.invalid(
        'URL_REQUIRED',
        'URL is required',
      );
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return const AisValidationResult.invalid(
        'URL_INVALID',
        'Please enter a valid URL',
      );
    }

    // Reject dangerous schemes
    if (uri.scheme == 'javascript' || uri.scheme == 'data') {
      return const AisValidationResult.invalid(
        'URL_DANGEROUS_SCHEME',
        'This URL scheme is not allowed',
      );
    }

    // Reject embedded credentials
    if (uri.userInfo.isNotEmpty) {
      return const AisValidationResult.invalid(
        'URL_EMBEDDED_CREDENTIALS',
        'URLs with embedded credentials are not allowed',
      );
    }

    return AisValidationResult.valid(uri.toString());
  }

  // §5.2: Phone - Library, not regex. Country REQUIRED.
  static AisValidationResult validatePhone(String value, {required String countryCode}) {
    if (value.isEmpty) {
      return const AisValidationResult.invalid(
        'PHONE_REQUIRED',
        'Phone number is required',
      );
    }

    // In a real implementation, use libphonenumber
    // This is a simplified demo

    final digits = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (digits.length < 7 || digits.length > 15) {
      return const AisValidationResult.invalid(
        'PHONE_INVALID_LENGTH',
        'Please enter a valid phone number',
      );
    }

    // Format based on country (simplified)
    String formatted;
    switch (countryCode) {
      case 'US':
        if (digits.length == 10) {
          formatted =
              '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
        } else {
          formatted = digits;
        }
        break;
      case 'GB':
        formatted = digits.replaceAllMapped(
          RegExp(r'(\d{4})(\d{3})(\d{4})'),
          (m) => '${m[1]} ${m[2]} ${m[3]}',
        );
        break;
      default:
        formatted = digits;
    }

    return AisValidationResult.valid(formatted);
  }

  // §5.2: Money - Exact decimal, NEVER regex, NEVER floating point
  // Currency REQUIRED, no default
  static AisValidationResult validateMoney(
    String value, {
    required String currency,
  }) {
    if (value.isEmpty) {
      return const AisValidationResult.invalid(
        'MONEY_REQUIRED',
        'Amount is required',
      );
    }

    // Remove currency symbols and whitespace
    final cleanValue =
        value.replaceAll(RegExp(r'[^\d.,\-]'), '').replaceAll(',', '.');

    // Parse using Decimal (in real app, use decimal package)
    final parsed = double.tryParse(cleanValue);
    if (parsed == null) {
      return const AisValidationResult.invalid(
        'MONEY_INVALID_FORMAT',
        'Please enter a valid amount',
      );
    }

    // Return with currency
    return AisValidationResult.valid({
      'amount': parsed,
      'currency': currency,
    });
  }

  // §5.2: Date - Explicit format, reject ambiguous
  // C-21: Ambiguous date without explicit format is REJECTED, not guessed
  static AisValidationResult validateDate(
    String value, {
    required String format,
  }) {
    if (value.isEmpty) {
      return const AisValidationResult.invalid(
        'DATE_REQUIRED',
        'Date is required',
      );
    }

    try {
      final formatter = DateFormat(format);
      final parsed = formatter.parseStrict(value);
      return AisValidationResult.valid(parsed);
    } catch (e) {
      return AisValidationResult.invalid(
        'DATE_INVALID_FORMAT',
        'Please enter date in format: $format',
      );
    }
  }

  // §5.2: Time - Timezone REQUIRED
  static AisValidationResult validateTime(
    String value, {
    required String timezone,
  }) {
    if (value.isEmpty) {
      return const AisValidationResult.invalid(
        'TIME_REQUIRED',
        'Time is required',
      );
    }

    // Simplified - in real app, use proper timezone library
    final timeRegex = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');
    final match = timeRegex.firstMatch(value);

    if (match == null) {
      return const AisValidationResult.invalid(
        'TIME_INVALID_FORMAT',
        'Please enter time in HH:MM format',
      );
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);

    if (hour > 23 || minute > 59) {
      return const AisValidationResult.invalid(
        'TIME_INVALID_VALUE',
        'Please enter a valid time',
      );
    }

    return AisValidationResult.valid({
      'time': value,
      'timezone': timezone,
    });
  }

  // §5.2: Postal code - Per-country, unknown accepts free text
  static AisValidationResult validatePostalCode(
    String value, {
    required String countryCode,
  }) {
    if (value.isEmpty) {
      return const AisValidationResult.invalid(
        'POSTAL_REQUIRED',
        'Postal code is required',
      );
    }

    // Country-specific validation
    switch (countryCode) {
      case 'US':
        if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(value)) {
          return const AisValidationResult.invalid(
            'POSTAL_INVALID_US',
            'Please enter a valid US ZIP code',
          );
        }
        break;
      case 'GB':
        if (!RegExp(r'^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$', caseSensitive: false)
            .hasMatch(value)) {
          return const AisValidationResult.invalid(
            'POSTAL_INVALID_GB',
            'Please enter a valid UK postcode',
          );
        }
        break;
      case 'CA':
        if (!RegExp(r'^[A-Z]\d[A-Z] ?\d[A-Z]\d$', caseSensitive: false)
            .hasMatch(value)) {
          return const AisValidationResult.invalid(
            'POSTAL_INVALID_CA',
            'Please enter a valid Canadian postal code',
          );
        }
        break;
      case 'JP':
        if (!RegExp(r'^\d{3}-?\d{4}$').hasMatch(value)) {
          return const AisValidationResult.invalid(
            'POSTAL_INVALID_JP',
            'Please enter a valid Japanese postal code',
          );
        }
        break;
      // Unknown country - accept free text
      default:
        break;
    }

    return AisValidationResult.valid(value.toUpperCase().trim());
  }

  // Compose multiple validators, return ALL failures (§5.1)
  static AisCompositeValidationResult compose(
    List<AisValidationResult Function()> validators,
  ) {
    final results = validators.map((v) => v()).toList();
    return AisCompositeValidationResult(results);
  }
}

/// Demo form field with AIS validation
class AisValidatedField extends StatefulWidget {
  final String label;
  final String? hint;
  final AisValidationResult Function(String value) validator;
  final void Function(String value)? onChanged;
  final String? initialValue;
  final TextInputType? keyboardType;

  const AisValidatedField({
    super.key,
    required this.label,
    required this.validator,
    this.hint,
    this.onChanged,
    this.initialValue,
    this.keyboardType,
  });

  @override
  State<AisValidatedField> createState() => _AisValidatedFieldState();
}

class _AisValidatedFieldState extends State<AisValidatedField> {
  late TextEditingController _controller;
  AisValidationResult? _result;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  void _validate() {
    if (!_hasInteracted) return;

    setState(() {
      _result = widget.validator(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final hasError = _result != null && !_result!.isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AisTheme.spacingXs),
        TextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: hasError ? _result!.userMessage : null,
            suffixIcon: _result != null
                ? Icon(
                    _result!.isValid
                        ? tokens.actionConfirm.icon
                        : tokens.stateError.icon,
                    color: _result!.isValid
                        ? tokens.actionConfirm.color
                        : tokens.stateError.color,
                    size: 18,
                  )
                : null,
          ),
          onChanged: (value) {
            _hasInteracted = true;
            _validate();
            widget.onChanged?.call(value);
          },
          onEditingComplete: () {
            _hasInteracted = true;
            _validate();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
