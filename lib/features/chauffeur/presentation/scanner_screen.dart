import 'package:app_settings/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/file_error.dart';
import '../data/station.dart';
import '../logic/chauffeur_providers.dart';
import 'file_error_message.dart';
import '../../../core/widgets/status_view.dart';
import 'widgets/centered_message.dart';

enum _Etape { scan, chargement, lignes, erreur }

/// C2 — scan the station QR code, pick a line, join its queue.
/// Pops `true` once the louage has joined a queue.
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

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_etape != _Etape.scan) return;
    final code = capture.barcodes
        .map((b) => b.rawValue?.trim() ?? '')
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;
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
    });
    await _camera.start();
  }

  /// Unknown QR code → scan again; anything else (network...) → reload the
  /// same station.
  Future<void> _retry() =>
      _error == FileError.qrStationInvalide ? _rescan() : _loadLignes();

  Future<void> _join(Station station, Ligne ligne) async {
    if (_joiningLigneId != null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.joinQueueConfirm(station.nom, ligne.villeArrivee)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.joinQueue),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _joiningLigneId != null) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanStationQr),
        actions: [if (_etape == _Etape.scan) _TorchButton(camera: _camera)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Kept mounted: the camera is stopped/started, not rebuilt.
          LayoutBuilder(
            builder: (context, constraints) {
              final window = Rect.fromCenter(
                center: constraints.biggest.center(Offset.zero),
                width: constraints.biggest.shortestSide * 0.7,
                height: constraints.biggest.shortestSide * 0.7,
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
                    borderColor: scheme.primary,
                    color: scheme.scrim.withValues(alpha: 0.5),
                  ),
                  const _Hint(),
                ],
              );
            },
          ),
          if (_etape != _Etape.scan)
            Material(
              color: scheme.surface,
              child: SafeArea(child: _buildEtape(context, l10n)),
            ),
        ],
      ),
    );
  }

  Widget _buildEtape(BuildContext context, AppLocalizations l10n) {
    final station = _station;
    return switch (_etape) {
      _Etape.scan ||
      _Etape.chargement => const Center(child: CircularProgressIndicator()),
      _Etape.erreur => CenteredMessage(
        icon: Icons.error_outline,
        tone: StatusTone.error,
        text: fileErrorMessage(l10n, _error ?? FileError.inconnue),
        action: FilledButton.icon(
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
          onPressed: _retry,
        ),
      ),
      _Etape.lignes when station != null => _Lignes(
        station: station,
        error: _error,
        joiningLigneId: _joiningLigneId,
        onSelect: (ligne) => _join(station, ligne),
        onRescan: _rescan,
      ),
      _Etape.lignes => const SizedBox.shrink(),
    };
  }
}

class _Lignes extends StatelessWidget {
  const _Lignes({
    required this.station,
    required this.error,
    required this.joiningLigneId,
    required this.onSelect,
    required this.onRescan,
  });

  final Station station;
  final FileError? error;
  final String? joiningLigneId;
  final ValueChanged<Ligne> onSelect;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tarif = NumberFormat('#,##0.000', l10n.localeName);
    final busy = joiningLigneId != null;

    if (station.lignes.isEmpty) {
      return CenteredMessage(
        icon: Icons.info_outline,
        text: l10n.noActiveLine,
        action: FilledButton.icon(
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(l10n.retry),
          onPressed: onRescan,
        ),
      );
    }
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(station.nom, style: theme.textTheme.headlineSmall),
        Text(station.ville, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.chooseLine, style: theme.textTheme.titleMedium),
        if (error case final error?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            fileErrorMessage(l10n, error),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        for (final ligne in station.lignes)
          Card(
            child: ListTile(
              enabled: !busy,
              title: Text(
                ligne.villeArrivee,
                style: theme.textTheme.titleLarge,
              ),
              subtitle: Text(l10n.tarifDt(tarif.format(ligne.tarif))),
              trailing: joiningLigneId == ligne.id
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.chevron_right),
              onTap: () => onSelect(ligne),
            ),
          ),
      ],
    );
  }
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
        return IconButton(
          icon: Icon(on ? Icons.flash_off : Icons.flash_on),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Material(
            color: theme.colorScheme.inverseSurface,
            shape: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                AppLocalizations.of(context).scannerHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
      color: Theme.of(context).colorScheme.surface,
      child: CenteredMessage(
        icon: denied ? Icons.no_photography_outlined : Icons.error_outline,
        tone: StatusTone.error,
        text: denied ? l10n.cameraPermissionDenied : l10n.cameraUnavailable,
        action: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (denied) ...[
              FilledButton.icon(
                icon: const Icon(Icons.settings),
                label: Text(l10n.openSettings),
                onPressed: () => AppSettings.openAppSettings(),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
