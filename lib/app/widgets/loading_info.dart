import 'package:flutter/material.dart';
import 'package:trainvent_general/trainvent_general.dart';

/// A compact loading indicator and label for use inside buttons and actions.
class LoadingInfo extends StatelessWidget {
  const LoadingInfo({
    super.key,
    required this.text,
    this.indicatorColor,
    this.size = 20,
    this.iterationDuration,
    this.iterations,
  });

  final String text;
  final Color? indicatorColor;
  final double size;
  final Duration? iterationDuration;
  final int? iterations;

  @override
  Widget build(BuildContext context) {
    final color = indicatorColor ?? Theme.of(context).colorScheme.onPrimary;

    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: size,
              child: Center(child: _indicator(color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicator(Color color) {
    if (iterationDuration == null) {
      return TriangleLoadingIndicator(
        size: size,
        showFill: false,
        strokeColor: color,
      );
    }

    return TriangleLoadingIndicator(
      size: size,
      showFill: false,
      strokeColor: color,
      iterationDuration: iterationDuration!,
      iterations: iterations,
    );
  }
}
