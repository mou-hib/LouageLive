import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// App bar on [LLColors.surface] with ink text. [board] adds the 6px
/// brandRed stripe used under live (departure board) screens.
///
/// The automatic back arrow (Icons.arrow_back) mirrors in RTL.
class LLAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LLAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.board = false,
    this.trailing = const [],
  });

  final String title;
  final String? subtitle;
  final bool board;
  final List<Widget> trailing;

  @override
  Size get preferredSize =>
      Size.fromHeight(LLSize.appBarH + (board ? LLSize.stripe : 0));

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    return AppBar(
      backgroundColor: c.surface,
      foregroundColor: c.ink,
      toolbarHeight: LLSize.appBarH,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LLText.title3.copyWith(color: c.ink),
          ),
          if (subtitle case final subtitle?)
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LLText.caption.copyWith(color: c.inkMuted),
            ),
        ],
      ),
      actions: trailing,
      bottom: board
          ? PreferredSize(
              preferredSize: const Size.fromHeight(LLSize.stripe),
              child: Container(
                key: const ValueKey('ll-app-bar-stripe'),
                height: LLSize.stripe,
                color: c.brandRed,
              ),
            )
          : null,
    );
  }
}
