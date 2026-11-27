import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Loading placeholder with a soft opacity pulse (static when animations
/// are disabled).
class LLSkeleton extends StatefulWidget {
  const LLSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = LLRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<LLSkeleton> createState() => _LLSkeletonState();
}

class _LLSkeletonState extends State<LLSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LLMotion.reduced(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: LLMotion.standard),
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: c.neutralTint,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
