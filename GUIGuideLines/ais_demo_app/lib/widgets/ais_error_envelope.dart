import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS Error Envelope (§4)
///
/// Key requirements:
/// - Every error carries: errorCode, userMessage, technical, context, serverContext
/// - Every error code has a registered, localized user message
/// - No user message contains stack trace, class name, SQL, or "exception"
/// - Copyable diagnostics with REDACTION (§4.2)
/// - C-15: Redaction admits NO exception

/// Error envelope structure per AIS §4.1
class AisErrorEnvelope {
  final String errorCode;
  final String userMessage;
  final String? technicalMessage;
  final String? exceptionType;
  final String? location;
  final String correlationId;
  final String? userId;
  final String route;
  final String appVersion;
  final String platform;
  final String osVersion;
  final String locale;
  final DateTime timestamp;
  final String? requestId;
  final String? endpoint;
  final int? statusCode;
  final String? serverVersion;

  // Raw context that needs redaction
  final Map<String, dynamic>? rawContext;

  const AisErrorEnvelope({
    required this.errorCode,
    required this.userMessage,
    this.technicalMessage,
    this.exceptionType,
    this.location,
    required this.correlationId,
    this.userId,
    required this.route,
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.locale,
    required this.timestamp,
    this.requestId,
    this.endpoint,
    this.statusCode,
    this.serverVersion,
    this.rawContext,
  });

  /// Generate copyable diagnostic block with redaction (§4.2)
  String toCopyableBlock() {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('ERROR REPORT');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Error: $errorCode');
    buffer.writeln('Message: $userMessage');
    buffer.writeln();
    buffer.writeln('─── Context ───');
    buffer.writeln('Correlation ID: $correlationId'); // Retained for support
    buffer.writeln('Timestamp: ${timestamp.toIso8601String()}');
    buffer.writeln('Route: $route');
    buffer.writeln('App Version: $appVersion');
    buffer.writeln('Platform: $platform / $osVersion');
    buffer.writeln('Locale: $locale');

    if (requestId != null) {
      buffer.writeln();
      buffer.writeln('─── Server ───');
      buffer.writeln('Request ID: $requestId');
      if (endpoint != null) buffer.writeln('Endpoint: $endpoint');
      if (statusCode != null) buffer.writeln('Status: $statusCode');
      if (serverVersion != null) buffer.writeln('Server Version: $serverVersion');
    }

    if (technicalMessage != null) {
      buffer.writeln();
      buffer.writeln('─── Technical ───');
      buffer.writeln('Type: ${exceptionType ?? "Unknown"}');
      buffer.writeln('Location: ${location ?? "Unknown"}');
      buffer.writeln('Detail: $technicalMessage');
    }

    // Redacted context (§4.2)
    if (rawContext != null && rawContext!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('─── Context (Redacted) ───');
      for (final entry in rawContext!.entries) {
        buffer.writeln('${entry.key}: ${_redact(entry.key, entry.value)}');
      }
    }

    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  /// C-15: Redaction - personal data becomes typed markers
  String _redact(String key, dynamic value) {
    final keyLower = key.toLowerCase();

    // Email
    if (keyLower.contains('email')) {
      return '[REDACTED:email]';
    }

    // Phone
    if (keyLower.contains('phone') || keyLower.contains('mobile')) {
      return '[REDACTED:phone]';
    }

    // Password
    if (keyLower.contains('password') || keyLower.contains('pwd')) {
      return '[REDACTED:password]';
    }

    // Token/Secret
    if (keyLower.contains('token') ||
        keyLower.contains('secret') ||
        keyLower.contains('key') ||
        keyLower.contains('auth')) {
      return '[REDACTED:token]';
    }

    // Name
    if (keyLower.contains('name') &&
        !keyLower.contains('error') &&
        !keyLower.contains('field')) {
      return '[REDACTED:name]';
    }

    // Address
    if (keyLower.contains('address') ||
        keyLower.contains('street') ||
        keyLower.contains('city')) {
      return '[REDACTED:address]';
    }

    // SSN/ID numbers
    if (keyLower.contains('ssn') ||
        keyLower.contains('social') ||
        keyLower.contains('national_id')) {
      return '[REDACTED:id_number]';
    }

    // Credit card
    if (keyLower.contains('card') || keyLower.contains('credit')) {
      return '[REDACTED:payment]';
    }

    return value.toString();
  }
}

/// Error display widget - inline variant
class AisInlineError extends StatelessWidget {
  final AisErrorEnvelope error;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const AisInlineError({
    super.key,
    required this.error,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Semantics(
      label: 'Error: ${error.userMessage}',
      child: Container(
        margin: const EdgeInsets.all(AisTheme.spacingMd),
        decoration: BoxDecoration(
          color: tokens.stateError.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AisTheme.radiusMd),
          border: Border.all(
            color: tokens.stateError.color.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              child: Row(
                children: [
                  Icon(
                    tokens.stateError.icon,
                    color: tokens.stateError.color,
                  ),
                  const SizedBox(width: AisTheme.spacingSm),
                  Expanded(
                    child: Text(
                      error.userMessage,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: tokens.stateError.color,
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: tokens.stateError.color,
                        size: 18,
                      ),
                      onPressed: onDismiss,
                    ),
                ],
              ),
            ),

            // Technical details (collapsed by default - §4.1)
            _TechnicalDetailExpander(error: error),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Copy diagnostics
                  TextButton.icon(
                    onPressed: () => _copyDiagnostics(context),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Diagnostics'),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: AisTheme.spacingSm),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.actionPrimary.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyDiagnostics(BuildContext context) {
    final block = error.toCopyableBlock();
    Clipboard.setData(ClipboardData(text: block));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            const SizedBox(width: AisTheme.spacingSm),
            const Text('Diagnostics copied to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Technical detail expander - collapsed by default per §4.1
class _TechnicalDetailExpander extends StatefulWidget {
  final AisErrorEnvelope error;

  const _TechnicalDetailExpander({required this.error});

  @override
  State<_TechnicalDetailExpander> createState() =>
      _TechnicalDetailExpanderState();
}

class _TechnicalDetailExpanderState extends State<_TechnicalDetailExpander> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AisTheme.spacingMd,
              vertical: AisTheme.spacingSm,
            ),
            child: Row(
              children: [
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: tokens.onSurfaceSecondary,
                ),
                const SizedBox(width: AisTheme.spacingXs),
                Text(
                  'Technical Details',
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AisTheme.spacingMd),
            padding: const EdgeInsets.all(AisTheme.spacingSm),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(AisTheme.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Error Code', value: widget.error.errorCode),
                _DetailRow(
                  label: 'Correlation ID',
                  value: widget.error.correlationId,
                ),
                if (widget.error.technicalMessage != null)
                  _DetailRow(
                    label: 'Technical',
                    value: widget.error.technicalMessage!,
                  ),
                if (widget.error.requestId != null)
                  _DetailRow(
                    label: 'Request ID',
                    value: widget.error.requestId!,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: tokens.onSurfaceSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blocking error dialog
class AisErrorDialog extends StatelessWidget {
  final AisErrorEnvelope error;

  const AisErrorDialog({
    super.key,
    required this.error,
  });

  static Future<void> show(BuildContext context, AisErrorEnvelope error) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AisErrorDialog(error: error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            tokens.stateError.icon,
            color: tokens.stateError.color,
          ),
          const SizedBox(width: AisTheme.spacingSm),
          const Text('Error'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.userMessage),
          const SizedBox(height: AisTheme.spacingMd),
          _TechnicalDetailExpander(error: error),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final block = error.toCopyableBlock();
            Clipboard.setData(ClipboardData(text: block));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Diagnostics copied')),
            );
          },
          child: const Text('Copy Diagnostics'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Transient error (snackbar)
class AisTransientError {
  static void show(BuildContext context, String message) {
    final tokens = context.aisTokens;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              tokens.stateError.icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: AisTheme.spacingSm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: tokens.stateError.color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Capture preview dialog (§4.3)
/// C-17: Preview before it leaves the device is MANDATORY
class AisCapturePreview extends StatelessWidget {
  final Widget capturedContent;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AisCapturePreview({
    super.key,
    required this.capturedContent,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              child: Row(
                children: [
                  Icon(
                    tokens.stateWarning.icon,
                    color: tokens.stateWarning.color,
                  ),
                  const SizedBox(width: AisTheme.spacingSm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview Capture',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Review before sharing - may contain personal data',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Preview
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AisTheme.spacingMd),
                child: capturedContent,
              ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Row(
                      children: [
                        Icon(tokens.actionNeutral.icon, size: 16),
                        const SizedBox(width: AisTheme.spacingXs),
                        const Text('Cancel'),
                      ],
                    ),
                  ),
                  const SizedBox(width: AisTheme.spacingSm),
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.actionCaution.color,
                    ),
                    child: Row(
                      children: [
                        Icon(tokens.actionCaution.icon, size: 16),
                        const SizedBox(width: AisTheme.spacingXs),
                        const Text('Confirm & Share'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
