import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A button that shows an inline [CircularProgressIndicator] while
/// an async action is running. Prevents double-taps automatically.
///
/// Works on both Material and Cupertino platforms.
class LoadingButton extends StatefulWidget {
  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.minimumSize,
    this.outlined = false,
    this.haptic = true,
  });

  /// The async callback. The button shows a spinner until it completes.
  final Future<void> Function() onPressed;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Size? minimumSize;
  final bool outlined;
  final bool haptic;

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    if (widget.haptic) HapticFeedback.mediumImpact();
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;
    final bg = widget.backgroundColor ?? AppColors.primary;
    final fg = widget.foregroundColor ?? AppColors.onPrimary;

    final spinner = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: fg,
      ),
    );

    if (isCupertino) {
      return CupertinoButton(
        onPressed: _isLoading ? null : _handlePress,
        color: widget.outlined ? null : bg,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              spinner
            else if (widget.icon != null)
              Icon(widget.icon, color: fg, size: 18),
            if (widget.icon != null || _isLoading) const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: widget.outlined ? bg : fg),
              ),
            ),
          ],
        ),
      );
    }

    final style = widget.outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: bg,
            side: BorderSide(color: bg),
            minimumSize: widget.minimumSize ?? const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        : FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            minimumSize: widget.minimumSize ?? const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLoading)
          spinner
        else if (widget.icon != null)
          Icon(widget.icon, size: 18),
        if (widget.icon != null || _isLoading) const SizedBox(width: 8),
        Flexible(child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );

    if (widget.outlined) {
      return OutlinedButton(
        onPressed: _isLoading ? null : _handlePress,
        style: style,
        child: child,
      );
    }

    return FilledButton(
      onPressed: _isLoading ? null : _handlePress,
      style: style,
      child: child,
    );
  }
}
