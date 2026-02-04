import 'dart:async';
import 'package:flutter/material.dart';

/// A TextButton that has a debounce and cooldown effect to prevent spamming.
///
/// When tapped, it becomes disabled for the given [debounceDuration]
/// and displays a countdown.
class DebouncedTextButtonWidget extends StatefulWidget {
  const DebouncedTextButtonWidget({
    super.key,
    required this.label,
    required this.callback,
    this.debounceDuration = const Duration(seconds: 30),
  });

  final String label;
  final VoidCallback callback;
  final Duration debounceDuration;

  @override
  State<DebouncedTextButtonWidget> createState() =>
      _DebouncedTextButtonWidgetState();
}

class _DebouncedTextButtonWidgetState extends State<DebouncedTextButtonWidget> {
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
    final isDisabled = _isOnCooldown;
    return TextButton(
      onPressed: isDisabled ? null : _handleTap,
      child: Text(
        _isOnCooldown ? '${widget.label} (${_countdown}s)' : widget.label,
        style: TextStyle(
          color: isDisabled
              ? Theme.of(context).disabledColor
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
