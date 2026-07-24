import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    super.key,
    this.isFilled = false,
    required this.label,
    required this.callback,
  });
  final bool isFilled;
  final String label;
  final Function()? callback;

  @override
  Widget build(BuildContext context) {
    Widget widget;
    if (isFilled) {
      widget = ElevatedButton(
        onPressed: callback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.black, // Ensure text is black on filled buttons
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(label),
      );
    } else {
      widget = OutlinedButton( // Changed to OutlinedButton for non-filled state
        onPressed: callback,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(label),
      );
    }

    return widget;
  }
}
