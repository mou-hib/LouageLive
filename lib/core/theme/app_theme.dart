import 'package:material_ui/material_ui.dart';

/// Material 3 theme with large touch targets (BNF-4: drivers use the app
/// with one hand, often in a hurry).
abstract final class AppTheme {
  static const _seed = Color(0xFF0B6E4F);
  static const _minTouch = Size.fromHeight(56);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _minTouch,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: _minTouch,
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }
}

/// Spacing scale for new screens, kept in one place so the coming redesign
/// can change it without touching widgets.
abstract final class AppSpacing {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}
