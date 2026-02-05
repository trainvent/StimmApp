import 'dart:async';
import 'package:flutter/material.dart';

/// A button that has a debounce and cooldown effect to prevent spamming.
///
/// When tapped, it becomes disabled for the given [debounceDuration]
/// and displays a countdown.
class DebouncedButtonWidget extends StatefulWidget {
  const DebouncedButtonWidget({
    super.key,
    this.isFilled = false,
    required this.label,
    required this.callback,
    this.debounceDuration = const Duration(seconds: 10),
  });

  final bool isFilled;
  final String label;
  final VoidCallback callback;
  final Duration debounceDuration;

  @override
  State<DebouncedButtonWidget> createState() => _DebouncedButtonWidgetState();
}

class _DebouncedButtonWidgetState extends State<DebouncedButtonWidget> {
  bool _isOnCooldown = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _countdown = widget.debounceDuration.inSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (_isOnCooldown) return;

    widget.callback();

    setState(() {
      _isOnCooldown = true;
      _countdown = widget.debounceDuration.inSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isOnCooldown = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.isFilled;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final disabledColor = Colors.grey;

    // Define styles for filled and outlined buttons
    final filledStyle = ElevatedButton.styleFrom(
      backgroundColor: _isOnCooldown ? disabledColor.withValues(alpha: 0.5) : primaryColor,
      foregroundColor: Colors.black,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Tapped effect color
      splashFactory: InkRipple.splashFactory,
    );

    final outlinedStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: _isOnCooldown ? disabledColor : primaryColor,
      side: BorderSide(color: _isOnCooldown ? disabledColor : primaryColor),
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // No splash for outlined to make it cleaner
      splashFactory: NoSplash.splashFactory,
    );

    return ElevatedButton(
      onPressed: _isOnCooldown ? null : _handleTap,
      style: isFilled ? filledStyle : outlinedStyle,
      child: Text(
        _isOnCooldown ? 'Bitte warten (${_countdown}s)' : widget.label,
      ),
    );
  }
}
