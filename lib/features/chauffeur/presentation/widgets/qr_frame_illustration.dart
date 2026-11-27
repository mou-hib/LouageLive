import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';

/// C1 illustration: the corners of a scan frame around a stylised QR code,
/// crossed by the red scan line. Decorative (excluded from semantics),
/// never mirrored.
class QrFrameIllustration extends StatelessWidget {
  const QrFrameIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size.square(LLSize.qrIllustration),
        painter: _QrFramePainter(
          frame: c.ink,
          code: c.borderStrong,
          line: c.brandRed,
        ),
      ),
    );
  }
}

class _QrFramePainter extends CustomPainter {
  const _QrFramePainter({
    required this.frame,
    required this.code,
    required this.line,
  });

  final Color frame;
  final Color code;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = LLSize.scanLine;
    final arm = s * 0.22;
    final r = s * 0.08;
    final corners = Paint()
      ..color = frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final h = stroke / 2;
    // Four rounded corner brackets.
    for (final (dx, dy) in const [(0, 0), (1, 0), (0, 1), (1, 1)]) {
      final x = dx == 0 ? h : s - h;
      final y = dy == 0 ? h : s - h;
      final sx = dx == 0 ? 1.0 : -1.0;
      final sy = dy == 0 ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(x, y + sy * arm)
        ..lineTo(x, y + sy * r)
        ..quadraticBezierTo(x, y, x + sx * r, y)
        ..lineTo(x + sx * arm, y);
      canvas.drawPath(path, corners);
    }
    // Stylised code: three finder squares and a few modules.
    final fill = Paint()..color = code;
    final ring = Paint()
      ..color = code
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03;
    final inset = s * 0.2;
    final finder = s * 0.18;
    for (final o in [
      Offset(inset, inset),
      Offset(s - inset - finder, inset),
      Offset(inset, s - inset - finder),
    ]) {
      final rect = o & Size.square(finder);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(s * 0.015),
          Radius.circular(s * 0.02),
        ),
        ring,
      );
      canvas.drawRect(rect.deflate(finder * 0.32), fill);
    }
    final m = s * 0.05;
    for (final (i, j) in const [
      (0, 0),
      (1, 1),
      (2, 0),
      (0, 2),
      (2, 2),
      (1, 3),
      (3, 1),
      (3, 3),
    ]) {
      canvas.drawRect(
        Offset(s * 0.5 + i * m, s * 0.5 + j * m) & Size.square(m * 0.8),
        fill,
      );
    }
    // Red scan line across the middle.
    canvas.drawLine(
      Offset(s * 0.1, s / 2),
      Offset(s * 0.9, s / 2),
      Paint()
        ..color = line
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_QrFramePainter old) =>
      old.frame != frame || old.code != code || old.line != line;
}
