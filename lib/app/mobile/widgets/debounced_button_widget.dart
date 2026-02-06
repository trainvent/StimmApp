import 'dart:async';
import 'package:flutter/material.dart';

/// A button wrapper that handles debouncing and loading states with a cool animation.
///
/// When tapped, it executes the [onPressed] callback. If [onPressed] returns a Future,
/// the button enters a loading state (grayed out/animated) until the Future completes.
/// It also supports a simple cooldown duration if no Future is returned.
class DebouncedButton extends StatefulWidget {
  const DebouncedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.cooldownDuration = const Duration(milliseconds: 500),
    this.style,
  });

  final Widget child;
  final FutureOr<void> Function()? onPressed;
  final Duration cooldownDuration;
  final ButtonStyle? style;

  @override
  State<DebouncedButton> createState() => _DebouncedButtonState();
}

class _DebouncedButtonState extends State<DebouncedButton> with SingleTickerProviderStateMixin {
  bool _isBusy = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isBusy || widget.onPressed == null) return;

    setState(() => _isBusy = true);
    await _controller.forward(); // Shrink

    try {
      final result = widget.onPressed!();
      if (result is Future) {
        await result;
      } else {
        // If not a future, just wait for the cooldown
        await Future.delayed(widget.cooldownDuration);
      }
    } finally {
      if (mounted) {
        await _controller.reverse(); // Grow back
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isBusy ? 0.6 : 1.0,
        child: ElevatedButton(
          onPressed: _isBusy ? null : _handleTap,
          style: widget.style,
          child: _isBusy
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : widget.child,
        ),
      ),
    );
  }
}
