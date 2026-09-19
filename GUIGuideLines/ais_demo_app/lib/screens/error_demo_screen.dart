import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';
import '../widgets/ais_error_envelope.dart';
import '../widgets/ais_button.dart';

/// Demo screen for AIS Error Envelope and Diagnostics (§4)
class ErrorDemoScreen extends StatelessWidget {
  const ErrorDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    // Sample error with sensitive data that needs redaction
    final sampleError = AisErrorEnvelope(
      errorCode: 'VALIDATION_FAILED',
      userMessage:
          'Unable to save your changes. Please check the highlighted fields and try again.',
      technicalMessage: 'Constraint violation on field: amount',
      exceptionType: 'ValidationException',
      location: 'TransactionService.save:142',
      correlationId: 'abc-123-def-456',
      userId: 'user_12345',
      route: '/transactions/new',
      appVersion: '2.1.0',
      platform: 'iOS',
      osVersion: '17.2',
      locale: 'en-US',
      timestamp: DateTime.now(),
      requestId: 'req_789xyz',
      endpoint: '/api/v1/transactions',
      statusCode: 422,
      serverVersion: '3.0.1',
      // This raw context contains PII that MUST be redacted (C-15)
      rawContext: {
        'userEmail': 'john.doe@example.com', // Will be redacted
        'userName': 'John Doe', // Will be redacted
        'userPhone': '+1-555-123-4567', // Will be redacted
        'authToken': 'Bearer eyJhbGc...', // Will be redacted
        'password': 'secret123', // Will be redacted
        'fieldName': 'amount', // NOT redacted
        'fieldValue': '1000.00', // NOT redacted
        'errorType': 'constraint_violation', // NOT redacted
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error & Diagnostics Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AisTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Error Envelope
            _SectionHeader(
              title: 'Error Envelope',
              subtitle: 'AIS §4.1 - Structured error with all required fields',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            // Inline error
            AisInlineError(
              error: sampleError,
              onRetry: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Retry triggered')),
                );
              },
              onDismiss: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error dismissed')),
                );
              },
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Error Variants
            _SectionHeader(
              title: 'Error Presentation Variants',
              subtitle: 'AIS §4.1 - Inline, blocking, transient',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Wrap(
              spacing: AisTheme.spacingMd,
              runSpacing: AisTheme.spacingMd,
              children: [
                AisButton(
                  label: 'Show Blocking Error',
                  type: AisButtonType.primary,
                  onPressed: () => AisErrorDialog.show(context, sampleError),
                ),
                AisButton(
                  label: 'Show Transient Error',
                  type: AisButtonType.primary,
                  onPressed: () => AisTransientError.show(
                    context,
                    'Connection lost. Retrying...',
                  ),
                ),
              ],
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Redaction Demo
            _SectionHeader(
              title: 'Redaction Demo',
              subtitle: 'AIS §4.2, C-15 - Personal data MUST be redacted',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Container(
              padding: const EdgeInsets.all(AisTheme.spacingMd),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                border: Border.all(
                  color: tokens.onSurface.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        tokens.stateWarning.icon,
                        color: tokens.stateWarning.color,
                      ),
                      const SizedBox(width: AisTheme.spacingSm),
                      const Text(
                        'Raw Context (Before Redaction)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AisTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: tokens.stateError.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                    ),
                    child: Text(
                      'userEmail: john.doe@example.com\n'
                      'userName: John Doe\n'
                      'userPhone: +1-555-123-4567\n'
                      'authToken: Bearer eyJhbGc...\n'
                      'password: secret123',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: tokens.stateError.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: AisTheme.spacingMd),
                  Row(
                    children: [
                      Icon(
                        tokens.actionConfirm.icon,
                        color: tokens.actionConfirm.color,
                      ),
                      const SizedBox(width: AisTheme.spacingSm),
                      const Text(
                        'In Copyable Block (After Redaction)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AisTheme.spacingSm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AisTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: tokens.actionConfirm.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AisTheme.radiusSm),
                    ),
                    child: Text(
                      'userEmail: [REDACTED:email]\n'
                      'userName: [REDACTED:name]\n'
                      'userPhone: [REDACTED:phone]\n'
                      'authToken: [REDACTED:token]\n'
                      'password: [REDACTED:password]',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: tokens.actionConfirm.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Capture Preview
            _SectionHeader(
              title: 'Capture Preview',
              subtitle: 'AIS §4.3, C-17 - Preview MANDATORY before sharing',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            AisButton(
              label: 'Simulate Screen Capture',
              type: AisButtonType.caution,
              customIcon: Icons.screenshot_rounded,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AisCapturePreview(
                    capturedContent: Container(
                      padding: const EdgeInsets.all(AisTheme.spacingMd),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Screen Capture Preview',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tokens.onSurface,
                            ),
                          ),
                          const SizedBox(height: AisTheme.spacingSm),
                          Text(
                            'This preview shows what will be shared.\n\n'
                            'User: John Doe\n'
                            'Account: ****4567\n\n'
                            'Check for any sensitive data before sharing.',
                            style: TextStyle(color: tokens.onSurface),
                          ),
                        ],
                      ),
                    ),
                    onConfirm: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Capture shared')),
                      );
                    },
                    onCancel: () => Navigator.pop(context),
                  ),
                );
              },
            ),

            const SizedBox(height: AisTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AisTheme.spacingLg),

            // Section: Error Registry
            _SectionHeader(
              title: 'Error Code Registry',
              subtitle: 'AIS §4.1, C-13 - Every code has a localized message',
            ),
            const SizedBox(height: AisTheme.spacingMd),

            Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(AisTheme.radiusMd),
                border: Border.all(
                  color: tokens.onSurface.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  _ErrorCodeRow(
                    code: 'VALIDATION_FAILED',
                    message: 'Please check the highlighted fields and try again.',
                  ),
                  const Divider(height: 1),
                  _ErrorCodeRow(
                    code: 'NETWORK_ERROR',
                    message: 'Unable to connect. Please check your connection.',
                  ),
                  const Divider(height: 1),
                  _ErrorCodeRow(
                    code: 'AUTH_EXPIRED',
                    message: 'Your session has expired. Please sign in again.',
                  ),
                  const Divider(height: 1),
                  _ErrorCodeRow(
                    code: 'PERMISSION_DENIED',
                    message: 'You don\'t have permission for this action.',
                  ),
                  const Divider(height: 1),
                  _ErrorCodeRow(
                    code: 'SERVER_ERROR',
                    message: 'Something went wrong. Please try again later.',
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AisTheme.spacingXs),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: tokens.onSurfaceSecondary,
          ),
        ),
      ],
    );
  }
}

class _ErrorCodeRow extends StatelessWidget {
  final String code;
  final String message;

  const _ErrorCodeRow({
    required this.code,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;

    return Padding(
      padding: const EdgeInsets.all(AisTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AisTheme.spacingSm,
              vertical: AisTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: tokens.surfaceSecondary,
              borderRadius: BorderRadius.circular(AisTheme.radiusSm),
            ),
            child: Text(
              code,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                color: tokens.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AisTheme.spacingMd),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
