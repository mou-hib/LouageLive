import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ll_logo.dart';
import '../../../l10n/app_localizations.dart';

/// A1 — shown while the session and the role are being resolved.
///
/// Full brandRed, logo on red, name and tagline in white, a thin white
/// progress bar near the bottom (static when animations are disabled).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _staticProgress = 0.4;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final l10n = AppLocalizations.of(context);
    const onRed = LLColors.onBrandRed;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.brandRed,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.all(LLSpace.s24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LLLogo(
                          size: LLSize.logoSplash,
                          variant: LLLogoVariant.onRed,
                        ),
                        const SizedBox(height: LLSpace.s24),
                        Text(
                          l10n.appTitle,
                          textAlign: TextAlign.center,
                          style: LLText.boardLg.copyWith(color: onRed),
                        ),
                        const SizedBox(height: LLSpace.s8),
                        Text(
                          l10n.splashTagline,
                          textAlign: TextAlign.center,
                          style: LLText.bodyLg.copyWith(
                            color: onRed.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: LLSpace.s48),
                child: SizedBox(
                  width: LLSize.progressThinW,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(LLRadius.full),
                    child: LinearProgressIndicator(
                      // Static bar when the system asks for no animations.
                      value: LLMotion.reduced(context) ? _staticProgress : null,
                      minHeight: LLSize.progressThin,
                      color: onRed,
                      backgroundColor: onRed.withValues(alpha: 0.3),
                      semanticsLabel: l10n.loading,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
