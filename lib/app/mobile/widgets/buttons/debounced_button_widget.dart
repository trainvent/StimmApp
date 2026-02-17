import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';

/// A button wrapper that handles debouncing and loading states with a cool animation.
///
/// When tapped, it executes the [onPressed] callback. If [onPressed] returns a Future,
/// the button enters a loading state (grayed out/animated) until the Future completes.
/// It also supports a simple cooldown duration if no Future is returned.
class DebouncedButton extends StatefulWidget {
  // We capture the key here but DO NOT pass it to super.key.
  // Instead, we pass it down to the inner ElevatedButton.
  // This allows tests to find the actual interactive button using the key provided
  // to this widget, while keeping the API clean.
  const DebouncedButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.cooldownDuration = const Duration(milliseconds: 500),
    this.style,
  }) : forwardedKey = key, super(key: null);

  final Key? forwardedKey;
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
          key: widget.forwardedKey, // Key is applied here
          onPressed: _isBusy ? null : _handleTap,
          style: widget.style,
          child: _isBusy
              ? TriangleLoadingIndicator(
                  size: 20,
                  showFill: false,
                  strokeColor: Theme.of(context).colorScheme.onPrimary,
                )
              : widget.child,
        ),
      ),
    );
  }
}
