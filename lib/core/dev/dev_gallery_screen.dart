import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../format/tarif.dart';
import '../theme/app_theme.dart';
import '../widgets/ll_app_bar.dart';
import '../widgets/ll_banner.dart';
import '../widgets/ll_button.dart';
import '../widgets/ll_skeleton.dart';
import '../widgets/ll_text_field.dart';
import '../widgets/live_badge.dart';
import '../widgets/louage_card.dart';
import '../widgets/plate_text.dart';
import '../widgets/seat_indicator.dart';
import '../widgets/seat_stepper.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_view.dart';

/// /dev/gallery (debug builds only): every shared widget in its states,
/// with dark mode, FR/AR and "no animations" toggles that apply to the
/// whole page.
class DevGalleryScreen extends StatefulWidget {
  const DevGalleryScreen({super.key});

  @override
  State<DevGalleryScreen> createState() => _DevGalleryScreenState();
}

class _DevGalleryScreenState extends State<DevGalleryScreen> {
  late bool _dark = Theme.of(context).brightness == Brightness.dark;
  late bool _arabic = Localizations.localeOf(context).languageCode == 'ar';
  bool _reduceMotion = false;
  bool _connected = true;
  bool _loading = false;
  int _seats = 5;
  final _lastUpdate = DateTime.now().subtract(const Duration(seconds: 12));

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Theme(
      data: _dark ? AppTheme.dark() : AppTheme.light(),
      child: Localizations.override(
        context: context,
        locale: Locale(_arabic ? 'ar' : 'fr'),
        child: MediaQuery(
          data: media.copyWith(disableAnimations: _reduceMotion),
          child: Builder(builder: _page),
        ),
      ),
    );
  }

  Widget _page(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final fare = formatTarif(l10n, 9.5);
    void noop() {}

    return Scaffold(
      backgroundColor: c.surface,
      appBar: LLAppBar(
        title: l10n.galleryTitle,
        subtitle: l10n.gallerySubtitle,
        board: true,
        trailing: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: LLSpace.s12),
            child: Center(
              child: LiveBadge(connected: _connected, lastUpdate: _lastUpdate),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(LLSpace.s16),
        children: [
          _Toggle(
            l10n.galleryDarkMode,
            _dark,
            (v) => setState(() => _dark = v),
          ),
          _Toggle(
            l10n.galleryArabic,
            _arabic,
            (v) => setState(() => _arabic = v),
          ),
          _Toggle(
            l10n.galleryReduceMotion,
            _reduceMotion,
            (v) => setState(() => _reduceMotion = v),
          ),
          _Toggle(
            l10n.galleryConnected,
            _connected,
            (v) => setState(() => _connected = v),
          ),
          _Toggle(
            l10n.galleryLoading,
            _loading,
            (v) => setState(() => _loading = v),
          ),

          _Section(l10n.galleryTypography),
          for (final (name, style) in const [
            ('boardXl 12/8', LLText.boardXl),
            ('boardLg 1234', LLText.boardLg),
            ('title1', LLText.title1),
            ('title2', LLText.title2),
            ('title3', LLText.title3),
            ('bodyLg', LLText.bodyLg),
            ('body', LLText.body),
            ('label', LLText.label),
            ('caption', LLText.caption),
          ])
            Text(name, style: style.copyWith(color: c.ink)),
          Text(
            LLText.overlineCase(context, l10n.queueHead),
            style: LLText.overline.copyWith(color: c.inkMuted),
          ),
          Text(l10n.galleryRoute, style: LLText.bodyLg.copyWith(color: c.ink)),
          Wrap(
            spacing: LLSpace.s16,
            children: [
              PlateText(
                '123 TU 4567',
                style: LLText.title3.copyWith(color: c.ink),
              ),
              PlateText(
                '123 تونس 4567',
                style: LLText.title3.copyWith(color: c.ink),
              ),
            ],
          ),

          _Section(l10n.galleryButtons),
          for (final (variant, label) in [
            (LLButtonVariant.primary, l10n.galleryPrimary),
            (LLButtonVariant.secondary, l10n.gallerySecondary),
            (LLButtonVariant.outline, l10n.galleryOutline),
            (LLButtonVariant.text, l10n.galleryText),
            (LLButtonVariant.destructive, l10n.galleryDestructive),
          ]) ...[
            LLButton(
              variant: variant,
              label: label,
              loading: _loading,
              onPressed: noop,
            ),
            const SizedBox(height: LLSpace.s8),
          ],
          LLButton(label: l10n.galleryPrimary, onPressed: null),
          const SizedBox(height: LLSpace.s8),
          LLButton(
            label: l10n.galleryDriver,
            icon: Icons.play_arrow_rounded,
            driver: true,
            loading: _loading,
            onPressed: noop,
          ),
          const SizedBox(height: LLSpace.s8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LLButton(
              label: l10n.retry,
              icon: Icons.refresh,
              loading: _loading,
              onPressed: noop,
            ),
          ),

          _Section(l10n.gallerySeats),
          Wrap(
            spacing: LLSpace.s24,
            runSpacing: LLSpace.s16,
            children: [
              for (final n in [0, 5, 6, 7, 8]) SeatIndicator(occupied: n),
            ],
          ),
          const SizedBox(height: LLSpace.s16),
          SeatIndicator(occupied: _seats, size: SeatIndicatorSize.large),

          _Section(l10n.galleryStepper),
          SeatStepper(
            value: _seats,
            max: 8,
            onChanged: (v) => setState(() => _seats = v),
          ),

          _Section(l10n.galleryChips),
          Wrap(
            spacing: LLSpace.s8,
            runSpacing: LLSpace.s8,
            children: [
              for (final state in ChipState.values) StatusChip(state: state),
            ],
          ),

          _Section(l10n.galleryCards),
          LouageCard(
            rank: 1,
            plate: '123 TU 4567',
            state: 'EN_REMPLISSAGE',
            occupied: _seats,
            eta: l10n.galleryEta,
            fare: fare,
            isHead: true,
          ),
          const SizedBox(height: LLSpace.s8),
          const LouageCard(
            rank: 2,
            plate: '204 تونس 8812',
            state: 'EN_ATTENTE',
            occupied: 0,
          ),
          const SizedBox(height: LLSpace.s8),
          const LouageCard(
            rank: 3,
            plate: '187 TU 1203',
            state: 'EN_ATTENTE',
            occupied: 0,
          ),
          const SizedBox(height: LLSpace.s8),
          const LouageCard(
            rank: 1,
            plate: '99 TU 777',
            state: 'COMPLET',
            occupied: 8,
            isHead: true,
          ),

          _Section(l10n.galleryLive),
          LiveBadge(connected: true, lastUpdate: _lastUpdate),
          const SizedBox(height: LLSpace.s8),
          LiveBadge(connected: false, lastUpdate: _lastUpdate),
          const SizedBox(height: LLSpace.s8),
          const LiveBadge(connected: false),

          _Section(l10n.galleryBanners),
          for (final (kind, message) in [
            (LLBannerKind.offline, l10n.galleryBannerOffline),
            (LLBannerKind.error, l10n.galleryBannerError),
            (LLBannerKind.warn, l10n.galleryBannerWarn),
            (LLBannerKind.ok, l10n.galleryBannerOk),
          ]) ...[
            LLBanner(
              kind: kind,
              message: message,
              actionLabel: kind == LLBannerKind.error ? l10n.retry : null,
              onAction: kind == LLBannerKind.error ? noop : null,
            ),
            const SizedBox(height: LLSpace.s8),
          ],

          _Section(l10n.galleryFields),
          LLTextField(label: l10n.phone, hint: l10n.phoneHint),
          const SizedBox(height: LLSpace.s16),
          LLTextField(label: l10n.email, errorText: l10n.emailInvalid),
          const SizedBox(height: LLSpace.s16),
          LLTextField(label: l10n.password, obscure: true),
          const SizedBox(height: LLSpace.s16),
          LLTextField(label: l10n.lastName, enabled: false),

          _Section(l10n.gallerySkeleton),
          const LLSkeleton(height: 72, radius: LLRadius.md),
          const SizedBox(height: LLSpace.s8),
          const LLSkeleton(width: 160, height: 16),

          _Section(l10n.galleryStatusView),
          for (final tone in StatusTone.values)
            Container(
              height: 420,
              margin: const EdgeInsetsDirectional.only(bottom: LLSpace.s8),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(LLRadius.md),
              ),
              child: StatusView(
                icon: switch (tone) {
                  StatusTone.neutral => Icons.no_transfer_outlined,
                  StatusTone.error => Icons.error_outline,
                  StatusTone.success => Icons.check_rounded,
                },
                tone: tone,
                title: l10n.galleryStatusTitle,
                message: l10n.galleryStatusMessage,
                primary: LLButton(label: l10n.retry, onPressed: noop),
                secondary: LLButton(
                  variant: LLButtonVariant.text,
                  label: l10n.cancel,
                  onPressed: noop,
                ),
              ),
            ),
          const SizedBox(height: LLSpace.s48),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: LLSpace.s32,
        bottom: LLSpace.s12,
      ),
      child: Text(
        LLText.overlineCase(context, title),
        style: LLText.overline.copyWith(color: c.inkMuted),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.label, this.value, this.onChanged);

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: value,
    onChanged: onChanged,
  );
}
