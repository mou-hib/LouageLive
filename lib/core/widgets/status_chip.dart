import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Every state a [StatusChip] can show. Passage states come from
/// `etat_passage`, reservation states from `etat_reservation`.
enum ChipState {
  /// The chauffeur's louage is in no queue (C1).
  horsFile,
  enAttente,
  enRemplissage,
  presqueComplet,
  complet,
  parti,
  retire,
  quitte,
  reservationEnAttente,
  reservationConfirmee,
  reservationAnnulee,
  reservationExpiree;

  /// `etat_passage` value (EN_ATTENTE…). EN_REMPLISSAGE becomes
  /// [presqueComplet] when 1–2 seats are left, [complet] when none (same
  /// thresholds as SeatIndicator).
  static ChipState fromPassage(String etat, {int? seatsLeft}) => switch (etat) {
    'EN_ATTENTE' => enAttente,
    'EN_REMPLISSAGE' => switch (seatsLeft) {
      final left? when left <= 0 => complet,
      final left? when left <= 2 => presqueComplet,
      _ => enRemplissage,
    },
    'COMPLET' => complet,
    'PARTI' => parti,
    'RETIRE' => retire,
    'QUITTE' => quitte,
    _ => throw FormatException('Unknown etat_passage: $etat'),
  };

  /// `etat_reservation` value (EN_ATTENTE, CONFIRMEE, ANNULEE, EXPIREE).
  static ChipState fromReservation(String etat) => switch (etat) {
    'EN_ATTENTE' => reservationEnAttente,
    'CONFIRMEE' => reservationConfirmee,
    'ANNULEE' => reservationAnnulee,
    'EXPIREE' => reservationExpiree,
    _ => throw FormatException('Unknown etat_reservation: $etat'),
  };

  /// Red live dot: the louage at the head that is filling right now.
  bool get live => this == enRemplissage || this == presqueComplet;

  String label(AppLocalizations l10n) => switch (this) {
    horsFile => l10n.statusHorsFile,
    enAttente => l10n.statusEnAttente,
    enRemplissage => l10n.statusEnRemplissage,
    presqueComplet => l10n.statusPresqueComplet,
    complet => l10n.statusComplet,
    parti => l10n.statusParti,
    retire => l10n.statusRetire,
    quitte => l10n.statusQuitte,
    reservationEnAttente => l10n.reservationEnAttente,
    reservationConfirmee => l10n.reservationConfirmee,
    reservationAnnulee => l10n.reservationAnnulee,
    reservationExpiree => l10n.reservationExpiree,
  };

  /// (background, foreground).
  (Color, Color) colors(LLColors c) => switch (this) {
    enRemplissage || reservationConfirmee => (c.successTint, c.success),
    presqueComplet || reservationEnAttente => (c.seatFewTint, c.seatFew),
    complet ||
    reservationAnnulee ||
    reservationExpiree => (c.seatFullTint, c.seatFull),
    horsFile ||
    enAttente ||
    parti ||
    retire ||
    quitte => (c.neutralTint, c.inkMuted),
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.state});

  /// From an `etat_passage` value and the seats currently occupied.
  factory StatusChip.passage(
    String etat, {
    Key? key,
    int? occupied,
    int capacity = 8,
  }) => StatusChip(
    key: key,
    state: ChipState.fromPassage(
      etat,
      seatsLeft: occupied == null ? null : capacity - occupied,
    ),
  );

  factory StatusChip.reservation(String etat, {Key? key}) =>
      StatusChip(key: key, state: ChipState.fromReservation(etat));

  final ChipState state;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final (bg, fg) = state.colors(c);
    return Container(
      height: 28,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: LLSpace.s8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LLRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.live) ...[
            Container(
              key: const ValueKey('status-live-dot'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: c.brandRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: LLSpace.s4),
          ],
          Flexible(
            child: Text(
              state.label(AppLocalizations.of(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LLText.caption.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
