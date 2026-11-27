import 'package:material_ui/material_ui.dart';

/// A licence plate (e.g. "123 TU 4567" or "123 تونس 4567") rendered as a
/// bidi-isolated left-to-right span, so its parts never get reordered in an
/// Arabic (RTL) layout.
class PlateText extends StatelessWidget {
  const PlateText(this.plate, {super.key, this.style});

  final String plate;
  final TextStyle? style;

  /// LRI … PDI: isolates [text] as LTR inside any surrounding paragraph.
  static String isolate(String text) => '\u2066$text\u2069';

  @override
  Widget build(BuildContext context) => Text(
    isolate(plate),
    style: style,
    textDirection: TextDirection.ltr,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
