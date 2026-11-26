import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';

/// Centered icon + text (+ optional action), scrollable on small screens.
class CenteredMessage extends StatelessWidget {
  const CenteredMessage({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (action case final action?) ...[
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
