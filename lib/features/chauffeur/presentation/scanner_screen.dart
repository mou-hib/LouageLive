import 'package:app_settings/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/format/tarif.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ll_banner.dart';
import '../../../core/widgets/ll_button.dart';
import '../../../core/widgets/ll_text_field.dart';
import '../../../core/widgets/status_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/file_error.dart';
import '../data/station.dart';
import '../logic/chauffeur_providers.dart';
import 'file_error_message.dart';
import 'widgets/centered_message.dart';

enum _Etape { scan, chargement, lignes, erreur }

/// C2 — scan the station QR code (or type it), pick a line, join its
/// queue. Pops `true` once the louage has joined a queue.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _camera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  _Etape _etape = _Etape.scan;
  String? _code;
  Station? _station;

  /// Error of the current step (loading lines, or joining).
  FileError? _error;

  /// Line being joined; non-null disables every line (no double submit).
  String? _joiningLigneId;

  /// Line picked in the sheet.
  String? _ligneChoisie;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes
        .map((b) => b.rawValue?.trim() ?? '')
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    await _soumettre(code);
  }

  /// A scanned or typed station code.
  Future<void> _soumettre(String code) async {
    if (_etape != _Etape.scan || code.isEmpty) return;
    setState(() {
      _etape = _Etape.chargement;
      _code = code;
    });
    await _camera.stop();
    await _loadLignes();
  }

  Future<void> _loadLignes() async {
    setState(() {
      _etape = _Etape.chargement;
      _error = null;
    });
    try {
      final station = await ref
          .read(chauffeurRepositoryProvider)
          .lignesDeStation(_code!);
      if (!mounted) return;
      setState(() {
        _station = station;
        _ligneChoisie = station.lignes.length == 1
            ? station.lignes.single.id
            : null;
        _etape = _Etape.lignes;
      });
    } on FileAttenteException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.error;
        _etape = _Etape.erreur;
      });
    }
  }

  Future<void> _rescan() async {
    setState(() {
      _etape = _Etape.scan;
      _code = null;
      _station = null;
      _error = null;
      _ligneChoisie = null;
    });
    await _camera.start();
  }

  /// Unknown QR code → scan again; anything else (network...) → reload the
  /// same station.
  Future<void> _retry() =>
      _error == FileError.qrStationInvalide ? _rescan() : _loadLignes();

  Future<void> _join(Ligne ligne) async {
    if (_joiningLigneId != null) return;
    setState(() {
      _joiningLigneId = ligne.id;
      _error = null;
    });
    try {
      await ref
          .read(chauffeurRepositoryProvider)
          .rejoindreFile(_code!, ligne.id);
      if (mounted) context.pop(true);
    } on FileAttenteException catch (e) {
      if (mounted) setState(() => _error = e.error);
    } finally {
      if (mounted) setState(() => _joiningLigneId = null);
    }
  }

  Future<void> _saisirCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _CodeDialog(),
    );
    if (code != null && mounted) await _soumettre(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final station = _station;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.scrim,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Kept mounted: the camera is stopped/started, not rebuilt.
          LayoutBuilder(
            builder: (context, constraints) {
              final window = Rect.fromCenter(
                center: constraints.biggest.center(Offset.zero),
                width: LLSize.scanFrame,
                height: LLSize.scanFrame,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _camera,
                    scanWindow: window,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => _CameraError(
                      error: error,
                      onRetry: () => _camera.start(),
                    ),
                  ),
                  ScanWindowOverlay(
                    controller: _camera,
                    scanWindow: window,
                    borderColor: LLColors.onCamera,
                    borderWidth: LLSize.scanFrameBorder,
                    borderRadius: BorderRadius.circular(LLRadius.lg),
                    color: LLColors.cameraScrim,
                  ),
                  if (_etape == _Etape.scan)
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      top: window.bottom + LLSpace.s24,
                      child: const _Hint(),
                    ),
                  if (_etape == _Etape.chargement)
                    Positioned.fromRect(
                      rect: window,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: LLColors.onCamera,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (_etape == _Etape.lignes && station != null)
            Align(
              alignment: const Alignment(0, -0.6),
              child: _StationReconnue(nom: station.nom),
            ),
          // Close + torch, over the camera.
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(LLSpace.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoundButton(
                    icon: Icons.close,
                    tooltip: l10n.close,
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  if (_etape == _Etape.scan) _TorchButton(camera: _camera),
                ],
              ),
            ),
          ),
          if (_etape == _Etape.scan)
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(LLSpace.s24),
                  child: LLButton(
                    variant: LLButtonVariant.secondary,
                    icon: Icons.keyboard_outlined,
                    label: l10n.enterCode,
                    onPressed: _saisirCode,
                  ),
                ),
              ),
            ),
          if (_etape == _Etape.lignes && station != null)
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: _LignesSheet(
                station: station,
                error: _error,
                selected: _ligneChoisie,
                joiningLigneId: _joiningLigneId,
                online: ref.isOnline,
                onSelect: (id) => setState(() => _ligneChoisie = id),
                onJoin: _join,
                onRescan: _rescan,
              ),
            ),
          if (_etape == _Etape.erreur)
            Material(
              color: c.surface,
              child: SafeArea(
                child: CenteredMessage(
                  icon: Icons.error_outline,
                  tone: StatusTone.error,
                  text: fileErrorMessage(l10n, _error ?? FileError.inconnue),
                  action: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LLButton(
                        driver: true,
                        icon: Icons.refresh,
                        label: l10n.retry,
                        onPressed: _retry,
                      ),
                      const SizedBox(height: LLSpace.s8),
                      LLButton(
                        driver: true,
                        variant: LLButtonVariant.text,
                        label: l10n.close,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Green check + "Station X reconnue", over the camera.
class _StationReconnue extends StatelessWidget {
  const _StationReconnue({required this.nom});

  final String nom;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: LLSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: LLSize.statusIcon,
              height: LLSize.statusIcon,
              decoration: BoxDecoration(
                color: c.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: LLSize.statusGlyph,
                color: LLColors.onCamera,
              ),
            ),
            const SizedBox(height: LLSpace.s12),
            Text(
              AppLocalizations.of(context).stationRecognized(nom),
              textAlign: TextAlign.center,
              style: LLText.title2.copyWith(color: LLColors.onCamera),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet "Choisissez votre ligne": one radio row per line, then
/// "Entrer dans la file".
class _LignesSheet extends StatelessWidget {
  const _LignesSheet({
    required this.station,
    required this.error,
    required this.selected,
    required this.joiningLigneId,
    required this.online,
    required this.onSelect,
    required this.onJoin,
    required this.onRescan,
  });

  final Station station;
  final FileError? error;
  final String? selected;
  final String? joiningLigneId;
  final bool online;
  final ValueChanged<String> onSelect;
  final ValueChanged<Ligne> onJoin;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final busy = joiningLigneId != null;
    final ligne = station.lignes.where((l) => l.id == selected).firstOrNull;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: const BorderRadiusDirectional.vertical(
          top: Radius.circular(LLRadius.lg),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              LLSpace.s24,
              LLSpace.s12,
              LLSpace.s24,
              LLSpace.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: LLSize.sheetHandleW,
                    height: LLSize.sheetHandleH,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(LLRadius.full),
                    ),
                  ),
                ),
                const SizedBox(height: LLSpace.s16),
                Text(
                  l10n.chooseLine,
                  style: LLText.title2.copyWith(color: c.ink),
                ),
                Text(
                  station.nom,
                  style: LLText.bodyLg.copyWith(color: c.inkMuted),
                ),
                if (error case final error?) ...[
                  const SizedBox(height: LLSpace.s12),
                  LLBanner(
                    kind: LLBannerKind.error,
                    message: fileErrorMessage(l10n, error),
                  ),
                ],
                const SizedBox(height: LLSpace.s8),
                if (station.lignes.isEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: LLSpace.s16,
                    ),
                    child: Text(
                      l10n.noActiveLine,
                      style: LLText.bodyLg.copyWith(color: c.ink),
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: RadioGroup<String>(
                        groupValue: selected,
                        onChanged: (id) {
                          if (id != null && !busy) onSelect(id);
                        },
                        child: Column(
                          children: [
                            for (final l in station.lignes)
                              _LigneRow(
                                ligne: l,
                                ligneLabel: l10n.ligneLabel(
                                  station.ville,
                                  l.villeArrivee,
                                ),
                                tarif: formatTarif(l10n, l.tarif),
                                onTap: busy ? null : () => onSelect(l.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: LLSpace.s16),
                if (station.lignes.isNotEmpty)
                  LLButton(
                    driver: true,
                    label: l10n.enterQueue,
                    loading: busy,
                    onPressed: ligne != null && online
                        ? () => onJoin(ligne)
                        : null,
                  ),
                LLButton(
                  variant: LLButtonVariant.text,
                  icon: Icons.qr_code_scanner,
                  label: l10n.scanAnother,
                  onPressed: busy ? null : onRescan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LigneRow extends StatelessWidget {
  const _LigneRow({
    required this.ligne,
    required this.ligneLabel,
    required this.tarif,
    required this.onTap,
  });

  final Ligne ligne;
  final String ligneLabel;
  final String tarif;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LLRadius.md),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: LLSpace.s8),
        child: Row(
          children: [
            Radio<String>(value: ligne.id, enabled: onTap != null),
            const SizedBox(width: LLSpace.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ligneLabel, style: LLText.title3.copyWith(color: c.ink)),
                  Text(
                    l10n.louagesAhead(ligne.louagesEnFile),
                    style: LLText.bodyLg.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: LLSpace.s8),
            Text(
              tarif,
              textDirection: TextDirection.ltr,
              style: LLText.title3.copyWith(color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Manual fallback: type the code printed under the station QR.
class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isNotEmpty) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.enterCodeTitle),
      content: LLTextField(
        label: l10n.enterCode,
        hint: l10n.enterCodeHint,
        controller: _controller,
        ltr: true,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.validate)),
      ],
    );
  }
}

/// Round translucent icon button over the camera.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      fixedSize: const Size.square(LLSize.roundButton),
      backgroundColor: LLColors.cameraButton,
      foregroundColor: LLColors.onCamera,
      shape: const CircleBorder(),
    ),
  );
}

class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.camera});

  final MobileScannerController camera;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: camera,
      builder: (context, state, _) {
        if (state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }
        final on = state.torchState == TorchState.on;
        return _RoundButton(
          icon: on ? Icons.flash_off : Icons.flash_on,
          tooltip: on ? l10n.torchOff : l10n.torchOn,
          onPressed: camera.toggleTorch,
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: LLSpace.s24),
    child: Text(
      AppLocalizations.of(context).scannerHint,
      textAlign: TextAlign.center,
      style: LLText.bodyLg.copyWith(color: LLColors.onCamera),
    ),
  );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Material(
      color: LLColors.of(context).surface,
      child: CenteredMessage(
        icon: denied ? Icons.no_photography_outlined : Icons.error_outline,
        tone: StatusTone.error,
        text: denied ? l10n.cameraPermissionDenied : l10n.cameraUnavailable,
        action: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (denied) ...[
              LLButton(
                driver: true,
                icon: Icons.settings,
                label: l10n.openSettings,
                onPressed: () => AppSettings.openAppSettings(),
              ),
              const SizedBox(height: LLSpace.s8),
            ],
            LLButton(
              driver: true,
              variant: LLButtonVariant.outline,
              icon: Icons.refresh,
              label: l10n.retry,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
