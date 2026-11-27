import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'plate_text.dart';
import 'seat_indicator.dart';
import 'status_chip.dart';

/// One louage in a queue.
/// - [isHead]: the louage filling at the head of the queue — brandRed rank
///   badge, status chip, large seat indicator, fare/ETA footer.
/// - otherwise: a compact row for the louages waiting behind it.
class LouageCard extends StatelessWidget {
  const LouageCard({
    super.key,
    required this.rank,
    required this.plate,
    required this.state,
    required this.occupied,
    this.capacity = 8,
    this.eta,
    this.fare,
    this.isHead = false,
  });

  final int rank;
  final String plate;

  /// `etat_passage` value (EN_ATTENTE, EN_REMPLISSAGE, …).
  final String state;
  final int occupied;
  final int capacity;

  /// Already formatted (e.g. "≈ 10 min", "14:30").
  final String? eta;

  /// Already formatted (e.g. l10n.tarifDt(...)).
  final String? fare;
  final bool isHead;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final l10n = AppLocalizations.of(context);
    final chip = StatusChip.passage(
      state,
      occupied: occupied,
      capacity: capacity,
    );
    return Semantics(
      container: true,
      label: l10n.queueRankA11y(rank),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(LLRadius.md),
          border: Border.all(color: isHead ? c.borderStrong : c.border),
        ),
        padding: const EdgeInsetsDirectional.all(LLSpace.s16),
        child: isHead
            ? _head(context, c, l10n, chip)
            : _compact(context, c, chip),
      ),
    );
  }

  Widget _rankBadge(LLColors c, {required bool head}) => ExcludeSemantics(
    child: Container(
      width: head ? 40 : 32,
      height: head ? 40 : 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: head ? c.brandRed : c.neutralTint,
        borderRadius: BorderRadius.circular(LLRadius.sm),
      ),
      child: Text(
        '$rank',
        textDirection: TextDirection.ltr,
        style: (head ? LLText.title3 : LLText.label).copyWith(
          color: head ? LLColors.onBrandRed : c.ink,
        ),
      ),
    ),
  );

  Widget _head(
    BuildContext context,
    LLColors c,
    AppLocalizations l10n,
    Widget chip,
  ) {
    final footer = [
      if (eta case final eta?) (l10n.etaLabel, eta),
      if (fare case final fare?) (l10n.fareLabel, fare),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _rankBadge(c, head: true),
            const SizedBox(width: LLSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LLText.overlineCase(context, l10n.queueHead),
                    style: LLText.overline.copyWith(color: c.inkMuted),
                  ),
                  PlateText(plate, style: LLText.title2.copyWith(color: c.ink)),
                ],
              ),
            ),
            const SizedBox(width: LLSpace.s8),
            Flexible(child: chip),
          ],
        ),
        const SizedBox(height: LLSpace.s16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SeatIndicator(
            occupied: occupied,
            capacity: capacity,
            size: SeatIndicatorSize.large,
          ),
        ),
        if (footer.isNotEmpty) ...[
          const SizedBox(height: LLSpace.s16),
          Divider(height: 1, color: c.border),
          const SizedBox(height: LLSpace.s12),
          Row(
            children: [
              for (final (label, value) in footer)
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: LLText.caption.copyWith(color: c.inkMuted),
                        ),
                        Text(
                          value,
                          style: LLText.title3.copyWith(color: c.ink),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _compact(BuildContext context, LLColors c, Widget chip) => Row(
    children: [
      _rankBadge(c, head: false),
      const SizedBox(width: LLSpace.s12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PlateText(plate, style: LLText.label.copyWith(color: c.ink)),
            const SizedBox(height: LLSpace.s4),
            chip,
          ],
        ),
      ),
      const SizedBox(width: LLSpace.s12),
      SeatIndicator(occupied: occupied, capacity: capacity),
    ],
  );
}
