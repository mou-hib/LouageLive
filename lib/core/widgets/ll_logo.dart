import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Where the logo is drawn; decides the tile and dot colours.
enum LLLogoVariant {
  /// Red tile, white dots: on light surfaces.
  onLight,

  /// Red tile, white dots, on dark surfaces (same red, it keeps its contrast
  /// on the dark surface; the dots stay white).
  onDark,

  /// White tile, red dots: on a brandRed background (splash).
  onRed,
}

/// The Louage Live mark: a rounded square holding the 8 seats of a louage
/// (2 rows of 4); the last seat is an empty ring — the one still free.
///
/// Drawn with a [CustomPainter], never mirrored in RTL (it is a brand mark).
class LLLogo extends StatelessWidget {
  const LLLogo({
    super.key,
    this.size = LLSize.logoHeader,
    this.variant,
    this.semanticLabel,
  });

  final double size;

  /// Null = [LLLogoVariant.onLight] or [LLLogoVariant.onDark] by brightness.
  final LLLogoVariant? variant;

  /// Read by screen readers; null = decorative (excluded from semantics).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final resolved =
        variant ??
        (Theme.of(context).brightness == Brightness.dark
            ? LLLogoVariant.onDark
            : LLLogoVariant.onLight);
    final (tile, dot) = switch (resolved) {
      LLLogoVariant.onLight ||
      LLLogoVariant.onDark => (c.brandRed, LLColors.onBrandRed),
      LLLogoVariant.onRed => (LLColors.onBrandRed, c.brandRed),
    };
    final logo = CustomPaint(
      size: Size.square(size),
      painter: LLLogoPainter(tile: tile, dot: dot),
    );
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: logo)
        : Semantics(label: label, image: true, child: logo);
  }
}

/// Paints [LLLogo]. Proportions are relative to the side, so the mark
/// scales cleanly from an app-bar icon to the splash.
class LLLogoPainter extends CustomPainter {
  const LLLogoPainter({required this.tile, required this.dot});

  final Color tile;
  final Color dot;

  static const _radius = 0.24; // tile corner radius
  static const _dot = 0.13; // dot diameter
  static const _gapX = 0.075; // horizontal gap between dots
  static const _gapY = 0.12; // vertical gap between the 2 rows
  static const _ring = 0.032; // stroke width of the empty seat

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & Size.square(s),
        Radius.circular(s * _radius),
      ),
      Paint()..color = tile,
    );
    final d = s * _dot;
    final rowW = 4 * d + 3 * s * _gapX;
    final colH = 2 * d + s * _gapY;
    final x0 = (s - rowW) / 2 + d / 2;
    final y0 = (s - colH) / 2 + d / 2;
    final fill = Paint()..color = dot;
    final ring = Paint()
      ..color = dot
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * _ring;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 4; col++) {
        final center = Offset(
          x0 + col * (d + s * _gapX),
          y0 + row * (d + s * _gapY),
        );
        final last = row == 1 && col == 3;
        canvas.drawCircle(
          center,
          last ? (d - s * _ring) / 2 : d / 2,
          last ? ring : fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(LLLogoPainter old) => old.tile != tile || old.dot != dot;
}
