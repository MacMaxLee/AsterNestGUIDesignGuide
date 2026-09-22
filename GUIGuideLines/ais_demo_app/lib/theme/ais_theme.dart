import 'package:flutter/material.dart';
import 'ais_tokens.dart';

/// AIS v1.0 Theme Configuration
///
/// Builds Flutter ThemeData with AIS tokens as ThemeExtension.
/// Per AIS §10.2: Material's ColorScheme alone is NOT sufficient.

class AisTheme {
  /// AIS Breakpoints (§6.3)
  static const double compactBreakpoint = 600;
  static const double mediumBreakpoint = 900;
  static const double expandedBreakpoint = 1200;

  /// Typography scale
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );

  /// Spacing scale
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  /// Border radius scale
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;

  /// Light theme
  static ThemeData get light {
    const tokens = AisTokens.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: tokens.actionPrimary.color,
        secondary: tokens.actionConfirm.color,
        error: tokens.stateError.color,
        surface: tokens.surface,
        onSurface: tokens.onSurface,
      ),
      scaffoldBackgroundColor: tokens.surfaceSecondary,
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: tokens.onSurface.withOpacity(0.1)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      textTheme: _textTheme.apply(
        bodyColor: tokens.onSurface,
        displayColor: tokens.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: tokens.onSurface.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: tokens.onSurface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: tokens.actionPrimary.color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.onSurface.withOpacity(0.1),
        thickness: 1,
      ),
      extensions: const [tokens],
    );
  }

  /// Dark theme
  static ThemeData get dark {
    const tokens = AisTokens.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: tokens.actionPrimary.color,
        secondary: tokens.actionConfirm.color,
        error: tokens.stateError.color,
        surface: tokens.surface,
        onSurface: tokens.onSurface,
      ),
      scaffoldBackgroundColor: tokens.surfaceSecondary,
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: tokens.onSurface.withOpacity(0.1)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      textTheme: _textTheme.apply(
        bodyColor: tokens.onSurface,
        displayColor: tokens.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: tokens.onSurface.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: tokens.onSurface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: tokens.actionPrimary.color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.onSurface.withOpacity(0.1),
        thickness: 1,
      ),
      extensions: const [tokens],
    );
  }

  /// Get breakpoint type from width
  static AisBreakpoint getBreakpoint(double width) {
    if (width < compactBreakpoint) return AisBreakpoint.compact;
    if (width < mediumBreakpoint) return AisBreakpoint.medium;
    return AisBreakpoint.expanded;
  }
}

enum AisBreakpoint { compact, medium, expanded }

/// Extension to get breakpoint from context
extension AisBreakpointExtension on BuildContext {
  AisBreakpoint get breakpoint {
    final width = MediaQuery.of(this).size.width;
    return AisTheme.getBreakpoint(width);
  }

  bool get isCompact => breakpoint == AisBreakpoint.compact;
  bool get isMedium => breakpoint == AisBreakpoint.medium;
  bool get isExpanded => breakpoint == AisBreakpoint.expanded;
}
