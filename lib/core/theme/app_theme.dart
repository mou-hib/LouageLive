import 'package:material_ui/material_ui.dart';

/// "Louage blanc" design system: tokens first, then the Material themes
/// built from them. Widgets read colours through [LLColors.of] so they get
/// the value for the current brightness.

// ---------------------------------------------------------------------------
// Colours
// ---------------------------------------------------------------------------

/// Colour tokens, exposed as a [ThemeExtension] on both themes.
@immutable
class LLColors extends ThemeExtension<LLColors> {
  const LLColors({
    required this.brandRed,
    required this.action,
    required this.onAction,
    required this.actionPressed,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.inkMuted,
    required this.seatOn,
    required this.seatFew,
    required this.seatFewTint,
    required this.seatFull,
    required this.seatFullTint,
    required this.success,
    required this.successTint,
    required this.neutralTint,
    required this.focusRing,
  });

  /// Logo, 6px board stripe, head-of-queue badge, live dot, full louage.
  /// Never a button colour.
  final Color brandRed;

  /// Primary button fill / its label / its pressed fill.
  final Color action;
  final Color onAction;
  final Color actionPressed;

  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color ink;
  final Color inkMuted;
  final Color seatOn;
  final Color seatFew;
  final Color seatFewTint;
  final Color seatFull;
  final Color seatFullTint;
  final Color success;
  final Color successTint;
  final Color neutralTint;
  final Color focusRing;

  /// Destructive button fill, the same in both themes so white text keeps
  /// its contrast.
  static const destructive = Color(0xFFB81D15);
  static const onDestructive = Color(0xFFFFFFFF);

  /// Text on a brandRed badge (head of queue rank).
  static const onBrandRed = Color(0xFFFFFFFF);

  static const light = LLColors(
    brandRed: Color(0xFFE1251B),
    action: Color(0xFF151515),
    onAction: Color(0xFFFFFFFF),
    actionPressed: Color(0xFF000000),
    surface: Color(0xFFFAF8F4),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF1EDE6),
    border: Color(0xFFE7E2D9),
    borderStrong: Color(0xFF8C857A),
    ink: Color(0xFF151515),
    inkMuted: Color(0xFF6B665E),
    seatOn: Color(0xFF151515),
    seatFew: Color(0xFF9C5205),
    seatFewTint: Color(0xFFF8EBD9),
    seatFull: Color(0xFFB81D15),
    seatFullTint: Color(0xFFFBE4E1),
    success: Color(0xFF23683F),
    successTint: Color(0xFFE3EEE5),
    neutralTint: Color(0xFFEDE8DF),
    focusRing: Color(0xFF2457C5),
  );

  static const dark = LLColors(
    brandRed: Color(0xFFE1251B),
    action: Color(0xFFF3EFE8),
    onAction: Color(0xFF151515),
    actionPressed: Color(0xFFD9D3C8),
    surface: Color(0xFF141414),
    surfaceRaised: Color(0xFF1E1E1D),
    surfaceSunken: Color(0xFF0C0C0C),
    border: Color(0xFF2C2B29),
    borderStrong: Color(0xFF6E685F),
    ink: Color(0xFFF3EFE8),
    inkMuted: Color(0xFFA8A196),
    seatOn: Color(0xFFF3EFE8),
    seatFew: Color(0xFFF0A04B),
    seatFewTint: Color(0xFF3A2810),
    seatFull: Color(0xFFFF6A5E),
    seatFullTint: Color(0xFF3D1714),
    success: Color(0xFF6FCF97),
    successTint: Color(0xFF12301F),
    neutralTint: Color(0xFF262523),
    focusRing: Color(0xFF8AB0FF),
  );

  /// The tokens of the current theme. Falls back to [light]/[dark] by
  /// brightness when the theme has no extension (e.g. bare test apps).
  static LLColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<LLColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  LLColors copyWith({
    Color? brandRed,
    Color? action,
    Color? onAction,
    Color? actionPressed,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? border,
    Color? borderStrong,
    Color? ink,
    Color? inkMuted,
    Color? seatOn,
    Color? seatFew,
    Color? seatFewTint,
    Color? seatFull,
    Color? seatFullTint,
    Color? success,
    Color? successTint,
    Color? neutralTint,
    Color? focusRing,
  }) => LLColors(
    brandRed: brandRed ?? this.brandRed,
    action: action ?? this.action,
    onAction: onAction ?? this.onAction,
    actionPressed: actionPressed ?? this.actionPressed,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    seatOn: seatOn ?? this.seatOn,
    seatFew: seatFew ?? this.seatFew,
    seatFewTint: seatFewTint ?? this.seatFewTint,
    seatFull: seatFull ?? this.seatFull,
    seatFullTint: seatFullTint ?? this.seatFullTint,
    success: success ?? this.success,
    successTint: successTint ?? this.successTint,
    neutralTint: neutralTint ?? this.neutralTint,
    focusRing: focusRing ?? this.focusRing,
  );

  @override
  LLColors lerp(LLColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return LLColors(
      brandRed: l(brandRed, other.brandRed),
      action: l(action, other.action),
      onAction: l(onAction, other.onAction),
      actionPressed: l(actionPressed, other.actionPressed),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      seatOn: l(seatOn, other.seatOn),
      seatFew: l(seatFew, other.seatFew),
      seatFewTint: l(seatFewTint, other.seatFewTint),
      seatFull: l(seatFull, other.seatFull),
      seatFullTint: l(seatFullTint, other.seatFullTint),
      success: l(success, other.success),
      successTint: l(successTint, other.successTint),
      neutralTint: l(neutralTint, other.neutralTint),
      focusRing: l(focusRing, other.focusRing),
    );
  }
}

// ---------------------------------------------------------------------------
// Spacing, radius, sizes, motion
// ---------------------------------------------------------------------------

abstract final class LLSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

abstract final class LLRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 24;
  static const double full = 999;
}

abstract final class LLSize {
  static const double tapMin = 48;
  static const double buttonH = 56;
  static const double buttonHDriver = 72;
  static const double stepperDriver = 112;
  static const double seatDot = 14;
  static const double stripe = 6;
  static const double appBarH = 56;

  /// Max width of centred content (status screens) on tablets.
  static const double contentMaxW = 420;

  /// LLLogo: splash (A1) and screen headers (A2, B1, A8).
  static const double logoSplash = 112;
  static const double logoHeader = 36;

  /// Thin progress bar of the splash, and its distance from the bottom.
  static const double progressThin = 3;
  static const double progressThinW = 120;

  /// Toned circle + glyph at the top of a status view.
  static const double statusIcon = 72;
  static const double statusGlyph = 36;

  /// Icon of a password checklist row (A8).
  static const double checklistIcon = 20;
}

/// Durations are functions of the context: they drop to zero when the
/// system asks for no animations (MediaQuery.disableAnimations).
abstract final class LLMotion {
  static const _tap = Duration(milliseconds: 100);
  static const _fast = Duration(milliseconds: 150);
  static const _base = Duration(milliseconds: 250);
  static const _exit = Duration(milliseconds: 200);
  static const _screen = Duration(milliseconds: 300);

  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve decel = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve accel = Cubic(0.3, 0, 0.8, 0.15);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration _of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  static Duration tap(BuildContext context) => _of(context, _tap);
  static Duration fast(BuildContext context) => _of(context, _fast);
  static Duration base(BuildContext context) => _of(context, _base);
  static Duration exit(BuildContext context) => _of(context, _exit);
  static Duration screen(BuildContext context) => _of(context, _screen);
}

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------

/// Text styles without colour (the theme / widgets add it). Every style uses
/// tabular figures so counts, plates, fares and times line up.
abstract final class LLText {
  static const fontFamily = 'Rubik';
  static const _tnum = [FontFeature.tabularFigures()];

  static const boardXl = TextStyle(
    fontFamily: fontFamily,
    fontSize: 64,
    height: 64 / 64,
    fontWeight: FontWeight.w700,
    fontFeatures: _tnum,
  );
  static const boardLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w700,
    fontFeatures: _tnum,
  );
  static const overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
    fontFeatures: _tnum,
  );
  static const title1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w600,
    fontFeatures: _tnum,
  );
  static const title2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    fontFeatures: _tnum,
  );
  static const title3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    fontFeatures: _tnum,
  );
  static const bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w400,
    fontFeatures: _tnum,
  );
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    fontFeatures: _tnum,
  );
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w600,
    fontFeatures: _tnum,
  );
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    fontFeatures: _tnum,
  );

  /// Overline text is uppercased in French only (Arabic has no case).
  static String overlineCase(BuildContext context, String text) =>
      Localizations.localeOf(context).languageCode == 'fr'
      ? text.toUpperCase()
      : text;

  static TextTheme textTheme(Color ink) => const TextTheme(
    displayLarge: boardXl,
    displayMedium: boardLg,
    displaySmall: title1,
    headlineLarge: title1,
    headlineMedium: title1,
    headlineSmall: title2,
    titleLarge: title2,
    titleMedium: title3,
    titleSmall: label,
    bodyLarge: bodyLg,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: label,
    labelMedium: caption,
    labelSmall: overline,
  ).apply(bodyColor: ink, displayColor: ink);
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, LLColors.light);
  static ThemeData dark() => _build(Brightness.dark, LLColors.dark);

  static ThemeData _build(Brightness brightness, LLColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.action,
      onPrimary: c.onAction,
      primaryContainer: c.neutralTint,
      onPrimaryContainer: c.ink,
      secondary: c.brandRed,
      onSecondary: LLColors.onBrandRed,
      secondaryContainer: c.neutralTint,
      onSecondaryContainer: c.ink,
      tertiary: c.success,
      onTertiary: c.surface,
      tertiaryContainer: c.successTint,
      onTertiaryContainer: c.success,
      error: c.seatFull,
      onError: brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF151515),
      errorContainer: c.seatFullTint,
      onErrorContainer: c.seatFull,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceDim: c.surfaceSunken,
      surfaceBright: c.surfaceRaised,
      surfaceContainerLowest: c.surfaceRaised,
      surfaceContainerLow: c.surfaceRaised,
      surfaceContainer: c.surfaceRaised,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.neutralTint,
      outline: c.borderStrong,
      outlineVariant: c.border,
      inverseSurface: c.ink,
      onInverseSurface: c.surface,
      inversePrimary: c.surface,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      surfaceTint: const Color(0x00000000),
    );
    final text = LLText.textTheme(c.ink);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LLRadius.md),
    );
    const buttonMinSize = Size.fromHeight(LLSize.buttonH);
    const buttonPadding = EdgeInsetsDirectional.symmetric(
      horizontal: LLSpace.s24,
    );
    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(LLRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: LLText.fontFamily,
      textTheme: text,
      primaryTextTheme: LLText.textTheme(c.onAction),
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      dividerColor: c.border,
      focusColor: c.focusRing.withValues(alpha: 0.12),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [c],
      iconTheme: IconThemeData(color: c.ink),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.ink,
        selectionColor: c.focusRing.withValues(alpha: 0.3),
        selectionHandleColor: c.focusRing,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: const Color(0x00000000),
        centerTitle: false,
        toolbarHeight: LLSize.appBarH,
        titleTextStyle: LLText.title3.copyWith(color: c.ink),
        iconTheme: IconThemeData(color: c.ink),
        actionsIconTheme: IconThemeData(color: c.ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(buttonMinSize),
          padding: const WidgetStatePropertyAll(buttonPadding),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: const WidgetStatePropertyAll(LLText.label),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? c.neutralTint
                : s.contains(WidgetState.pressed)
                ? c.actionPressed
                : c.action,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.inkMuted : c.onAction,
          ),
          overlayColor: const WidgetStatePropertyAll(Color(0x00000000)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: LLText.label,
          foregroundColor: c.ink,
          disabledForegroundColor: c.inkMuted,
          side: BorderSide(color: c.borderStrong, width: 1.5),
          overlayColor: c.ink,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(LLSize.tapMin, LLSize.tapMin),
          shape: buttonShape,
          textStyle: LLText.label,
          foregroundColor: c.ink,
          overlayColor: c.ink,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(LLSize.tapMin, LLSize.tapMin),
          foregroundColor: c.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: c.surfaceRaised,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: LLSpace.s16,
          vertical: LLSpace.s16,
        ),
        border: inputBorder(c.borderStrong, 1.5),
        enabledBorder: inputBorder(c.borderStrong, 1.5),
        disabledBorder: inputBorder(c.border, 1.5),
        focusedBorder: inputBorder(c.focusRing, 2),
        errorBorder: inputBorder(c.seatFull, 1.5),
        focusedErrorBorder: inputBorder(c.seatFull, 2),
        labelStyle: LLText.body.copyWith(color: c.inkMuted),
        floatingLabelStyle: LLText.label.copyWith(color: c.ink),
        hintStyle: LLText.bodyLg.copyWith(color: c.inkMuted),
        helperStyle: LLText.caption.copyWith(color: c.inkMuted),
        errorStyle: LLText.caption.copyWith(color: c.seatFull),
        prefixIconColor: c.inkMuted,
        suffixIconColor: c.inkMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: LLText.body.copyWith(color: c.surface),
        actionTextColor: c.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LLRadius.sm),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceRaised,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LLRadius.md),
          side: BorderSide(color: c.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: const Color(0x00000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LLRadius.lg),
        ),
        titleTextStyle: LLText.title2.copyWith(color: c.ink),
        contentTextStyle: LLText.bodyLg.copyWith(color: c.ink),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.ink,
        linearTrackColor: c.neutralTint,
        circularTrackColor: const Color(0x00000000),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.ink,
        textColor: c.ink,
        titleTextStyle: LLText.bodyLg.copyWith(color: c.ink),
        subtitleTextStyle: LLText.body.copyWith(color: c.inkMuted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAction : c.borderStrong,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.action : c.neutralTint,
        ),
        trackOutlineColor: WidgetStatePropertyAll(c.borderStrong),
      ),
    );
  }
}

/// Spacing used by the screens written before the design system. Kept so
/// they compile unchanged; new code uses [LLSpace].
abstract final class AppSpacing {
  static const double sm = LLSpace.s8;
  static const double md = LLSpace.s16;
  static const double lg = LLSpace.s24;
}
