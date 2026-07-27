import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

class VerificationCodeInput extends StatelessWidget {
  static const _codeLength = 6;
  static const _separatorWidth = 8.0;

  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;

  const VerificationCodeInput({
    super.key,
    required this.controller,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 328.0;
        final pinWidth =
            ((availableWidth - (_separatorWidth * (_codeLength - 1))) /
                    _codeLength)
                .clamp(32.0, 48.0);
        final defaultPinTheme = PinTheme(
          width: pinWidth,
          height: 56,
          textStyle: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline),
          ),
        );

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            key: key,
            length: _codeLength,
            controller: controller,
            defaultPinTheme: defaultPinTheme,
            separatorBuilder: (_) => const SizedBox(width: _separatorWidth),
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration?.copyWith(
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
            ),
            submittedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration?.copyWith(
                border: Border.all(color: colorScheme.primary),
              ),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            onCompleted: onCompleted,
          ),
        );
      },
    );
  }
}
