import 'package:flutter/material.dart';

class AppColors {
  // Primary – Hot Pink / Magenta
  static const Color primary = Color(0xFFE91E8C);
  static const Color primaryDark = Color(0xFF880E4F);
  static const Color primaryLight = Color(0xFFF48FB1);
  static const Color primaryContainer = Color(0xFFFCE4EC);

  // Secondary – Green (wellness)
  static const Color secondary = Color(0xFF22C55E);
  static const Color secondaryDark = Color(0xFF16A34A);
  static const Color secondaryLight = Color(0xFF86EFAC);
  static const Color secondaryContainer = Color(0xFFDCFCE7);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Priority
  static const Color priorityHigh = Color(0xFFE91E8C);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF94A3B8);

  // ── Light theme surfaces ───────────────────────────────────────────────────
  static const Color background = Color(0xFFFFF5FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFCE4EC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0D0D0D);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color iconDefault = Color(0xFF64748B);

  // ── Dark theme surfaces ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B0C1A);
  static const Color darkSurface = Color(0xFF161728);
  static const Color darkCard = Color(0xFF1E1F36);
  static const Color darkSurfaceVariant = Color(0xFF252742);
  static const Color darkPrimaryContainer = Color(0xFF2D1030);
  static const Color darkDivider = Color(0xFF2A2B45);
  static const Color darkTextPrimary = Color(0xFFF0F0F5);
  static const Color darkTextSecondary = Color(0xFF8A94A6);
  static const Color darkTextHint = Color(0xFF5A6375);
  static const Color darkIconDefault = Color(0xFF8A94A6);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFE91E8C), Color(0xFFFF6EB4)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF0F7), Color(0xFFFCE4EC)],
  );

  static const LinearGradient aiMessageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE91E8C), Color(0xFFFF4BAF)],
  );

  static const LinearGradient darkButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF880E4F), Color(0xFFAD1457)],
  );
}

/// Theme-aware color accessors resolved from the active [ThemeData].
///
/// Usage in any widget [build] method:
/// ```dart
/// Container(color: context.colCard, child: ...)
/// Text('hello', style: TextStyle(color: context.colText1))
/// ```
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get colBg => isDark ? AppColors.darkBackground : AppColors.background;
  Color get colSurface => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get colCard => isDark ? AppColors.darkCard : AppColors.cardSurface;
  Color get colSurfaceVar =>
      isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8F8F8);
  Color get colTaskDone =>
      isDark ? AppColors.darkSurface : const Color(0xFFF0F0F0);
  Color get colPrimaryC =>
      isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
  Color get colDivider => isDark ? AppColors.darkDivider : AppColors.divider;
  Color get colText1 =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get colText2 =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get colHint => isDark ? AppColors.darkTextHint : AppColors.textHint;
  Color get colIcon =>
      isDark ? AppColors.darkIconDefault : AppColors.iconDefault;

  LinearGradient get colAuthGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0818), Color(0xFF0B0C1A)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0F7), Color(0xFFFFFFFF)],
        );
}
