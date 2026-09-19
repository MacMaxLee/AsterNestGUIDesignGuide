import 'package:flutter/material.dart';

/// AIS v1.0 Core Semantic Tokens
///
/// These tokens define the 9 core semantic meanings per AIS §2.2.
/// A Domain Profile may ADD tokens but never redefine or remove these.

class AisSemanticToken {
  final Color color;
  final IconData icon;
  final String label;

  const AisSemanticToken({
    required this.color,
    required this.icon,
    required this.label,
  });
}

/// AIS Token Set - All 9 core tokens with required paired icons (§2.3)
class AisTokens extends ThemeExtension<AisTokens> {
  // Action tokens
  final AisSemanticToken actionPrimary;
  final AisSemanticToken actionConfirm;
  final AisSemanticToken actionDestructive;
  final AisSemanticToken actionCaution;
  final AisSemanticToken actionNeutral;

  // State tokens
  final AisSemanticToken stateInfo;
  final AisSemanticToken stateWarning;
  final AisSemanticToken stateError;
  final AisSemanticToken stateUnavailable;

  // Surface colors
  final Color surface;
  final Color surfaceSecondary;
  final Color onSurface;
  final Color onSurfaceSecondary;

  const AisTokens({
    required this.actionPrimary,
    required this.actionConfirm,
    required this.actionDestructive,
    required this.actionCaution,
    required this.actionNeutral,
    required this.stateInfo,
    required this.stateWarning,
    required this.stateError,
    required this.stateUnavailable,
    required this.surface,
    required this.surfaceSecondary,
    required this.onSurface,
    required this.onSurfaceSecondary,
  });

  /// Light theme tokens
  static const AisTokens light = AisTokens(
    // Actions
    actionPrimary: AisSemanticToken(
      color: Color(0xFF2563EB), // Blue
      icon: Icons.arrow_forward_rounded,
      label: 'Primary Action',
    ),
    actionConfirm: AisSemanticToken(
      color: Color(0xFF16A34A), // Green
      icon: Icons.check_circle_rounded,
      label: 'Confirm',
    ),
    actionDestructive: AisSemanticToken(
      color: Color(0xFFDC2626), // Red
      icon: Icons.delete_forever_rounded,
      label: 'Destructive',
    ),
    actionCaution: AisSemanticToken(
      color: Color(0xFFD97706), // Amber
      icon: Icons.warning_amber_rounded,
      label: 'Caution',
    ),
    actionNeutral: AisSemanticToken(
      color: Color(0xFF6B7280), // Gray
      icon: Icons.close_rounded,
      label: 'Neutral',
    ),
    // States
    stateInfo: AisSemanticToken(
      color: Color(0xFF0EA5E9), // Sky blue
      icon: Icons.info_rounded,
      label: 'Info',
    ),
    stateWarning: AisSemanticToken(
      color: Color(0xFFF59E0B), // Yellow
      icon: Icons.warning_rounded,
      label: 'Warning',
    ),
    stateError: AisSemanticToken(
      color: Color(0xFFEF4444), // Red
      icon: Icons.error_rounded,
      label: 'Error',
    ),
    stateUnavailable: AisSemanticToken(
      color: Color(0xFF9CA3AF), // Light gray
      icon: Icons.block_rounded,
      label: 'Unavailable',
    ),
    // Surfaces
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF3F4F6),
    onSurface: Color(0xFF111827),
    onSurfaceSecondary: Color(0xFF6B7280),
  );

  /// Dark theme tokens
  static const AisTokens dark = AisTokens(
    // Actions
    actionPrimary: AisSemanticToken(
      color: Color(0xFF60A5FA), // Light blue
      icon: Icons.arrow_forward_rounded,
      label: 'Primary Action',
    ),
    actionConfirm: AisSemanticToken(
      color: Color(0xFF4ADE80), // Light green
      icon: Icons.check_circle_rounded,
      label: 'Confirm',
    ),
    actionDestructive: AisSemanticToken(
      color: Color(0xFFF87171), // Light red
      icon: Icons.delete_forever_rounded,
      label: 'Destructive',
    ),
    actionCaution: AisSemanticToken(
      color: Color(0xFFFBBF24), // Light amber
      icon: Icons.warning_amber_rounded,
      label: 'Caution',
    ),
    actionNeutral: AisSemanticToken(
      color: Color(0xFF9CA3AF), // Light gray
      icon: Icons.close_rounded,
      label: 'Neutral',
    ),
    // States
    stateInfo: AisSemanticToken(
      color: Color(0xFF38BDF8), // Light sky
      icon: Icons.info_rounded,
      label: 'Info',
    ),
    stateWarning: AisSemanticToken(
      color: Color(0xFFFCD34D), // Light yellow
      icon: Icons.warning_rounded,
      label: 'Warning',
    ),
    stateError: AisSemanticToken(
      color: Color(0xFFFCA5A5), // Light red
      icon: Icons.error_rounded,
      label: 'Error',
    ),
    stateUnavailable: AisSemanticToken(
      color: Color(0xFF6B7280), // Medium gray
      icon: Icons.block_rounded,
      label: 'Unavailable',
    ),
    // Surfaces
    surface: Color(0xFF1F2937),
    surfaceSecondary: Color(0xFF111827),
    onSurface: Color(0xFFF9FAFB),
    onSurfaceSecondary: Color(0xFF9CA3AF),
  );

  @override
  AisTokens copyWith({
    AisSemanticToken? actionPrimary,
    AisSemanticToken? actionConfirm,
    AisSemanticToken? actionDestructive,
    AisSemanticToken? actionCaution,
    AisSemanticToken? actionNeutral,
    AisSemanticToken? stateInfo,
    AisSemanticToken? stateWarning,
    AisSemanticToken? stateError,
    AisSemanticToken? stateUnavailable,
    Color? surface,
    Color? surfaceSecondary,
    Color? onSurface,
    Color? onSurfaceSecondary,
  }) {
    return AisTokens(
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionConfirm: actionConfirm ?? this.actionConfirm,
      actionDestructive: actionDestructive ?? this.actionDestructive,
      actionCaution: actionCaution ?? this.actionCaution,
      actionNeutral: actionNeutral ?? this.actionNeutral,
      stateInfo: stateInfo ?? this.stateInfo,
      stateWarning: stateWarning ?? this.stateWarning,
      stateError: stateError ?? this.stateError,
      stateUnavailable: stateUnavailable ?? this.stateUnavailable,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceSecondary: onSurfaceSecondary ?? this.onSurfaceSecondary,
    );
  }

  @override
  AisTokens lerp(ThemeExtension<AisTokens>? other, double t) {
    if (other is! AisTokens) return this;
    return copyWith(
      surface: Color.lerp(surface, other.surface, t),
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t),
      onSurface: Color.lerp(onSurface, other.onSurface, t),
      onSurfaceSecondary: Color.lerp(onSurfaceSecondary, other.onSurfaceSecondary, t),
    );
  }
}

/// Extension to easily access AIS tokens from BuildContext
extension AisTokensExtension on BuildContext {
  AisTokens get aisTokens {
    return Theme.of(this).extension<AisTokens>() ?? AisTokens.light;
  }
}
