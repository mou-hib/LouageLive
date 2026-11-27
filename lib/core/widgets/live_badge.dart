import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Realtime status: a brandRed dot pulsing every 2 s + "En direct" when
/// [connected]; otherwise a muted dot + "Mis à jour il y a X s" counted
/// from [lastUpdate] (refreshed every second).
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, required this.connected, this.lastUpdate});

  final bool connected;
  final DateTime? lastUpdate;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(seconds: 2);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _period,
  );
  Timer? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LiveBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate = widget.connected && !LLMotion.reduced(context);
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!animate && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
    if (widget.connected) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String _text(AppLocalizations l10n) {
    if (widget.connected) return l10n.liveNow;
    final last = widget.lastUpdate;
    if (last == null) return l10n.liveOffline;
    final age = DateTime.now().difference(last);
    final seconds = age.inSeconds < 0 ? 0 : age.inSeconds;
    return seconds < 60
        ? l10n.liveUpdatedSecondsAgo(seconds)
        : l10n.liveUpdatedMinutesAgo(age.inMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final dotColor = widget.connected ? c.brandRed : c.inkMuted;
    const dot = 8.0;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: dot * 2.5,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                // Ring grows and fades over the first half of each period.
                final t = (_pulse.value * 2).clamp(0.0, 1.0);
                final eased = LLMotion.decel.transform(t);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.connected && _pulse.isAnimating)
                      Container(
                        width: dot + dot * 1.5 * eased,
                        height: dot + dot * 1.5 * eased,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.brandRed.withValues(alpha: 0.35 * (1 - t)),
                        ),
                      ),
                    Container(
                      width: dot,
                      height: dot,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: LLSpace.s4),
          Text(
            _text(AppLocalizations.of(context)),
            style: LLText.caption.copyWith(
              color: widget.connected ? c.ink : c.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
