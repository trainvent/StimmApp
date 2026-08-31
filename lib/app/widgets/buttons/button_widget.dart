import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';
import 'package:stimmapp/app/widgets/loading_info.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    super.key,
    this.isFilled = false,
    this.isLoading = false,
    required this.label,
    required this.callback,
  });
  final bool isFilled;
  final bool isLoading;
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
        onPressed: isLoading ? null : callback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor:
              Colors.black, // Ensure text is black on filled buttons
          minimumSize: const Size(double.infinity, 50),
          shape: shape,
        ),
        child: _buttonContent(context, Colors.black),
      );
    } else {
      widget = OutlinedButton(
        onPressed: isLoading ? null : callback,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          minimumSize: const Size(double.infinity, 50),
          shape: shape,
        ),
        child: _buttonContent(context, Theme.of(context).colorScheme.primary),
      );
    }

    return widget;
  }

  Widget _buttonContent(BuildContext context, Color strokeColor) {
    if (!isLoading) return Text(label);
    return LoadingInfo(text: label, indicatorColor: strokeColor);
  }
}
