import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

enum SeatIndicatorSize { list, large }

/// How full a louage is, by seats left.
enum SeatLevel {
  /// More than 2 seats left.
  open,

  /// 1 or 2 seats left.
  few,

  /// No seat left.
  full;

  static SeatLevel of(int occupied, int capacity) {
    final left = capacity - occupied;
    if (left <= 0) return full;
    if (left <= 2) return few;
    return open;
  }
}

/// Seats as two rows of dots plus an "occupied/capacity" count.
/// - filled dot = seatOn, empty = ring in borderStrong;
/// - full: every dot brandRed, count in seatFull;
/// - 1–2 seats left: only the count turns seatFew.
class SeatIndicator extends StatelessWidget {
  const SeatIndicator({
    super.key,
    required this.occupied,
    this.capacity = 8,
    this.size = SeatIndicatorSize.list,
  });

  final int occupied;
  final int capacity;
  final SeatIndicatorSize size;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final large = size == SeatIndicatorSize.large;
    final filled = occupied.clamp(0, capacity);
    final level = SeatLevel.of(filled, capacity);
    final perRow = (capacity / 2).ceil();
    final dot = large ? LLSize.seatDot * 2 : LLSize.seatDot;
    final gap = large ? LLSpace.s8 : LLSpace.s4;
    final ring = large ? 3.0 : 2.0;
    final duration = LLMotion.fast(context);

    Widget seat(int index) {
      final on = index < filled;
      final fillColor = level == SeatLevel.full ? c.brandRed : c.seatOn;
      return AnimatedContainer(
        key: ValueKey('seat-$index'),
        duration: duration,
        curve: LLMotion.standard,
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? fillColor : const Color(0x00000000),
          border: Border.all(
            color: on ? fillColor : c.borderStrong,
            width: ring,
          ),
        ),
      );
    }

    Widget row(int from) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = from; i < (from + perRow).clamp(0, capacity); i++) ...[
          if (i > from) SizedBox(width: gap),
          seat(i),
        ],
      ],
    );

    final countColor = switch (level) {
      SeatLevel.full => c.seatFull,
      SeatLevel.few => c.seatFew,
      SeatLevel.open => c.ink,
    };
    final countStyle = (large ? LLText.boardLg : LLText.label).copyWith(
      color: countColor,
    );

    return Semantics(
      label: AppLocalizations.of(context).seatsOccupiedA11y(filled, capacity),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                row(0),
                SizedBox(height: gap),
                row(perRow),
              ],
            ),
            SizedBox(width: large ? LLSpace.s16 : LLSpace.s8),
            AnimatedDefaultTextStyle(
              duration: duration,
              style: countStyle,
              // Numbers stay LTR so "6/8" never reads "8/6" in Arabic.
              child: Text(
                '$filled/$capacity',
                key: const ValueKey('seat-count'),
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
