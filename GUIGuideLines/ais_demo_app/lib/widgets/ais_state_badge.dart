import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS State Badge (§2.2)
///
/// Displays state tokens with required paired icons.
/// state.unavailable must be distinguishable from zero by MORE than color (§2.3).

enum AisStateType {
  info,
  warning,
  error,
  unavailable,
}

class AisStateBadge extends StatelessWidget {
  final String label;
  final AisStateType type;
  final bool compact;

  const AisStateBadge({
    super.key,
    required this.label,
    required this.type,
    this.compact = false,
  });

  AisSemanticToken _getToken(AisTokens tokens) {
    switch (type) {
      case AisStateType.info:
        return tokens.stateInfo;
      case AisStateType.warning:
        return tokens.stateWarning;
      case AisStateType.error:
        return tokens.stateError;
      case AisStateType.unavailable:
        return tokens.stateUnavailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final token = _getToken(tokens);

    // AIS §2.3: state.unavailable must be distinguishable by MORE than color
    // Using dashed border and italic text for unavailable state
    final isUnavailable = type == AisStateType.unavailable;

    return Semantics(
      label: '${token.label}: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AisTheme.spacingSm : AisTheme.spacingMd,
          vertical: compact ? AisTheme.spacingXs : AisTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: token.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AisTheme.radiusSm),
          border: Border.all(
            color: token.color.withOpacity(0.5),
            width: isUnavailable ? 1.5 : 1,
            // Note: Flutter doesn't support dashed borders natively
            // We use different visual indicators for unavailable
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Always show icon per AIS §2.3
            Icon(
              token.icon,
              size: compact ? 14 : 16,
              color: token.color,
            ),
            SizedBox(width: compact ? AisTheme.spacingXs : AisTheme.spacingSm),
            Text(
              label,
              style: TextStyle(
                color: token.color,
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w500,
                // Italic for unavailable to provide additional non-color distinction
                fontStyle: isUnavailable ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AIS Unavailable Value Indicator (§2.2, §2.3)
///
/// Specifically for showing unavailable/no-value state.
/// MUST be distinguishable from zero by MORE than color.
class AisUnavailableValue extends StatelessWidget {
  final String? reason;

  const AisUnavailableValue({
    super.key,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final token = tokens.stateUnavailable;

    return Semantics(
      label: 'Value unavailable${reason != null ? ': $reason' : ''}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon provides non-color distinction
          Icon(
            token.icon,
            size: 16,
            color: token.color,
          ),
          const SizedBox(width: AisTheme.spacingXs),
          Text(
            '—', // Em dash, not zero
            style: TextStyle(
              color: token.color,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (reason != null) ...[
            const SizedBox(width: AisTheme.spacingXs),
            Text(
              '($reason)',
              style: TextStyle(
                color: token.color.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
