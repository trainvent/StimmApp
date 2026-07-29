import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    super.key,
    this.isFilled = false,
    required this.label,
    required this.callback,
  });
  final bool isFilled;
  final String label;
  final VoidCallback? callback;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.small),
    );
    Widget widget;
    if (isFilled) {
      widget = ElevatedButton(
        onPressed: callback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor:
              Colors.black, // Ensure text is black on filled buttons
          minimumSize: const Size(double.infinity, 50),
          shape: shape,
        ),
        child: Text(label),
      );
    } else {
      widget = OutlinedButton(
        onPressed: callback,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          minimumSize: const Size(double.infinity, 50),
          shape: shape,
        ),
        child: Text(label),
      );
    }

    return widget;
  }
}
