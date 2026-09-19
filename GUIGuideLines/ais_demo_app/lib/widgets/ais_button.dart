import 'package:flutter/material.dart';
import '../theme/ais_tokens.dart';
import '../theme/ais_theme.dart';

/// AIS Semantic Button (§2.2, §2.3)
///
/// Every button uses a semantic token with its required paired icon.
/// Color alone never carries meaning.

enum AisButtonType {
  primary,
  confirm,
  destructive,
  caution,
  neutral,
}

class AisButton extends StatelessWidget {
  final String label;
  final AisButtonType type;
  final VoidCallback? onPressed;
  final bool showIcon;
  final IconData? customIcon;
  final bool isLoading;

  const AisButton({
    super.key,
    required this.label,
    required this.type,
    this.onPressed,
    this.showIcon = true,
    this.customIcon,
    this.isLoading = false,
  });

  AisSemanticToken _getToken(AisTokens tokens) {
    switch (type) {
      case AisButtonType.primary:
        return tokens.actionPrimary;
      case AisButtonType.confirm:
        return tokens.actionConfirm;
      case AisButtonType.destructive:
        return tokens.actionDestructive;
      case AisButtonType.caution:
        return tokens.actionCaution;
      case AisButtonType.neutral:
        return tokens.actionNeutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final token = _getToken(tokens);
    final isDisabled = onPressed == null || isLoading;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: '${token.label}: $label',
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? tokens.stateUnavailable.color.withOpacity(0.5)
              : token.color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: tokens.stateUnavailable.color.withOpacity(0.3),
          disabledForegroundColor: tokens.onSurface.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AisTheme.spacingLg,
            vertical: AisTheme.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AisTheme.radiusMd),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AIS §2.3: Every token pairs with a required icon
                  if (showIcon) ...[
                    Icon(customIcon ?? token.icon, size: 18),
                    const SizedBox(width: AisTheme.spacingSm),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Outlined variant of AIS Button
class AisOutlinedButton extends StatelessWidget {
  final String label;
  final AisButtonType type;
  final VoidCallback? onPressed;
  final bool showIcon;
  final IconData? customIcon;

  const AisOutlinedButton({
    super.key,
    required this.label,
    required this.type,
    this.onPressed,
    this.showIcon = true,
    this.customIcon,
  });

  AisSemanticToken _getToken(AisTokens tokens) {
    switch (type) {
      case AisButtonType.primary:
        return tokens.actionPrimary;
      case AisButtonType.confirm:
        return tokens.actionConfirm;
      case AisButtonType.destructive:
        return tokens.actionDestructive;
      case AisButtonType.caution:
        return tokens.actionCaution;
      case AisButtonType.neutral:
        return tokens.actionNeutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.aisTokens;
    final token = _getToken(tokens);

    return Semantics(
      button: true,
      label: '${token.label}: $label',
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: token.color,
          side: BorderSide(color: token.color),
          padding: const EdgeInsets.symmetric(
            horizontal: AisTheme.spacingLg,
            vertical: AisTheme.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AisTheme.radiusMd),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(customIcon ?? token.icon, size: 18),
              const SizedBox(width: AisTheme.spacingSm),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
