import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_validation.dart';
import '../widgets/ais_value_component.dart';

/// Demo screen for AIS Validation (§5)
class ValidationDemoScreen extends StatefulWidget {
  const ValidationDemoScreen({super.key});

  @override
  State<ValidationDemoScreen> createState() => _ValidationDemoScreenState();
}

class _ValidationDemoScreenState extends State<ValidationDemoScreen> {
  String _selectedCountry = 'US';

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AisTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Validation Layer
            _SectionHeader(
              title: 'Validation Layer',
              subtitle: 'AIS §5.1 - Platform-free, no UI framework dependency',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.stateInfo.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    tokens.stateInfo.icon,
                    color: tokens.stateInfo.color,
                  ),
                  const SizedBox(width: AisTheme.spacingSm),
                  const Expanded(
                    child: Text(
                      'Validators are pure Dart with no Flutter imports. '
                      'They can run on both client and server for C-18 parity.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),

            // Country selector (C-20: No validator defaults to one country)
            Row(
              children: [
                Text(
                  'Country Context (C-20):',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: tokens.onSurface,
                  ),
                ),
                const SizedBox(width: AisTheme.spacingMd),
                DropdownButton<String>(
                  value: _selectedCountry,
                  items: const [
                    DropdownMenuItem(value: 'US', child: Text('United States')),
                    DropdownMenuItem(value: 'GB', child: Text('United Kingdom')),
                    DropdownMenuItem(value: 'CA', child: Text('Canada')),
                    DropdownMenuItem(value: 'JP', child: Text('Japan')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCountry = value!);
                  },
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Email Validation
            _SectionHeader(
              title: 'Email Validation',
              subtitle: '§5.2 - Permissive pattern, real validation via confirmation',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            AisValidatedField(
              label: 'Email Address',
              hint: 'user@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) => AisValidators.validateEmail(value),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: URL Validation
            _SectionHeader(
              title: 'URL Validation',
              subtitle: '§5.2 - Native parser, scheme allowlist, reject credentials',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            AisValidatedField(
              label: 'Website URL',
              hint: 'https://example.com',
              keyboardType: TextInputType.url,
              validator: (value) => AisValidators.validateUrl(value),
            ),

            const SizedBox(height: AisTheme.spacingSm),
            Text(
              'Try: javascript:alert(1) or http://user:pass@example.com',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: tokens.onSurfaceSecondary,
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Phone Validation
            _SectionHeader(
              title: 'Phone Validation',
              subtitle: '§5.2 - Library-based, NOT regex. Country required.',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            AisValidatedField(
              label: 'Phone Number ($_selectedCountry)',
              hint: _getPhoneHint(_selectedCountry),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  AisValidators.validatePhone(value, countryCode: _selectedCountry),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Money Validation
            _SectionHeader(
              title: 'Money Validation',
              subtitle: '§5.2, C-19 - NEVER regex, NEVER floating point',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            AisValidatedField(
              label: 'Amount (USD)',
              hint: '1,234.56',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) =>
                  AisValidators.validateMoney(value, currency: 'USD'),
            ),

            const SizedBox(height: AisTheme.spacingMd),

            // Show value component with annotations
            Text(
              'Rendered with required annotations (§3.1):',
              style: TextStyle(
                fontSize: 12,
                color: tokens.onSurfaceSecondary,
              ),
            ),
            const SizedBox(height: AisTheme.spacingSm),
            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                border: Border.all(
                  color: tokens.onSurface.withOpacity(0.1),
                ),
              ),
              child: AisMonetaryValue(
                amount: 1234.56,
                currency: 'USD', // REQUIRED
                period: 'Q4 2024',
                basis: 'Accrual',
                isDraft: true,
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Date Validation
            _SectionHeader(
              title: 'Date Validation',
              subtitle: '§5.2, C-21 - Explicit format, reject ambiguous',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            AisValidatedField(
              label: 'Date (Format: yyyy-MM-dd)',
              hint: '2024-12-25',
              validator: (value) =>
                  AisValidators.validateDate(value, format: 'yyyy-MM-dd'),
            ),

            const SizedBox(height: AisTheme.spacingSm),
            Container(
              padding: const EdgeInsets.all(AisTheme.spacingSm),
              decoration: BoxDecoration(
                color: tokens.stateWarning.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AisTheme.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    tokens.stateWarning.icon,
                    size: 14,
                    color: tokens.stateWarning.color,
                  ),
                  const SizedBox(width: AisTheme.spacingXs),
                  Text(
                    'Ambiguous dates like "01/02/03" are REJECTED, not guessed',
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.stateWarning.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Time Validation
            _SectionHeader(
              title: 'Time Validation',
              subtitle: '§5.2 - Timezone REQUIRED',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Row(
              children: [
                Expanded(
                  child: AisValidatedField(
                    label: 'Time (HH:MM)',
                    hint: '14:30',
                    validator: (value) =>
                        AisValidators.validateTime(value, timezone: 'America/New_York'),
                  ),
                ),
                const SizedBox(width: AisTheme.spacingMd),
                Container(
                  padding: const EdgeInsets.all(AisTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                  ),
                  child: Text(
                    'TZ: America/New_York',
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.onSurfaceSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Postal Code Validation
            _SectionHeader(
              title: 'Postal Code Validation',
              subtitle: '§5.2 - Per-country rules, unknown accepts free text',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            AisValidatedField(
              label: 'Postal Code ($_selectedCountry)',
              hint: _getPostalHint(_selectedCountry),
              validator: (value) =>
                  AisValidators.validatePostalCode(value, countryCode: _selectedCountry),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Payment Card
            _SectionHeader(
              title: 'Payment Card',
              subtitle: '§5.4 - OUT OF SCOPE by default',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.stateError.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                border: Border.all(
                  color: tokens.stateError.color.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card_off_rounded,
                    color: tokens.stateError.color,
                  ),
                  const SizedBox(width: AisTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No card input field provided',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tokens.stateError.color,
                          ),
                        ),
                        const SizedBox(height: AisTheme.spacingXs),
                        Text(
                          'Per AIS §5.4: Accepting card numbers places the app in '
                          'payment-industry compliance scope. Use processor\'s '
                          'hosted fields or tokenization instead.',
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  String _getPhoneHint(String country) {
    switch (country) {
      case 'US':
        return '(555) 123-4567';
      case 'GB':
        return '07123 456789';
      case 'CA':
        return '(555) 123-4567';
      case 'JP':
        return '090-1234-5678';
      default:
        return 'Phone number';
    }
  }

  String _getPostalHint(String country) {
    switch (country) {
      case 'US':
        return '12345 or 12345-6789';
      case 'GB':
        return 'SW1A 1AA';
      case 'CA':
        return 'A1A 1A1';
      case 'JP':
        return '123-4567';
      default:
        return 'Postal code';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AisTheme.spacingXs),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: tokens.onSurfaceSecondary,
          ),
        ),
      ],
    );
  }
}
