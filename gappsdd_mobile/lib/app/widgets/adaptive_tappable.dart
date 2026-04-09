import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A tappable wrapper that provides platform-appropriate press feedback:
/// - **Android/Material**: standard [InkWell] ripple
/// - **iOS/Cupertino**: opacity + subtle scale-down animation
///
/// Also triggers optional haptic feedback on tap.
class AdaptiveTappable extends StatefulWidget {
  const AdaptiveTappable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.haptic = HapticStyle.none,
    this.scaleOnPress = 0.97,
    this.opacityOnPress = 0.7,
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final HapticStyle haptic;

  /// Scale factor when pressed (iOS only). 1.0 = no scale.
  final double scaleOnPress;

  /// Opacity when pressed (iOS only). 1.0 = no opacity change.
  final double opacityOnPress;

  /// Optional background color for the InkWell (Android).
  final Color? backgroundColor;

  @override
  State<AdaptiveTappable> createState() => _AdaptiveTappableState();
}

class _AdaptiveTappableState extends State<AdaptiveTappable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  void _onTap() {
    widget.haptic.trigger();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

    if (!isCupertino) {
      return Material(
        color: widget.backgroundColor ?? Colors.transparent,
        borderRadius: widget.borderRadius,
        child: InkWell(
          onTap: widget.onTap != null ? _onTap : null,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      );
    }

    final scale = Tween<double>(begin: 1.0, end: widget.scaleOnPress);
    final opacity = Tween<double>(begin: 1.0, end: widget.opacityOnPress);

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap != null ? _onTap : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = CurvedAnimation(parent: _controller, curve: Curves.easeInOut).value;
          return Opacity(
            opacity: opacity.transform(t),
            child: Transform.scale(
              scale: scale.transform(t),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Haptic feedback intensity levels.
enum HapticStyle {
  none,
  light,
  medium,
  heavy;

  void trigger() {
    switch (this) {
      case HapticStyle.none:
        break;
      case HapticStyle.light:
        HapticFeedback.lightImpact();
      case HapticStyle.medium:
        HapticFeedback.mediumImpact();
      case HapticStyle.heavy:
        HapticFeedback.heavyImpact();
    }
  }
}
