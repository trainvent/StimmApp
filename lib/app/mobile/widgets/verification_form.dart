import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/debounced_button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/debounced_text_button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/verification_code_input.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';

class VerificationForm extends StatelessWidget {
  const VerificationForm({
    super.key,
    required this.codeController,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
    required this.backLabel,
  });

  final TextEditingController codeController;
  final VoidCallback onVerify;
  final Future<void> Function() onResend;
  final VoidCallback onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          S.of(context).enterVerificationCode,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          S.of(context).weHaveSentA6digitCodeToYourEmailPlease,
          textAlign: TextAlign.center,
          style: AppTextStyles.descriptionText,
        ),
        const SizedBox(height: 32),
        VerificationCodeInput(
          controller: codeController,
          onCompleted: (_) => onVerify(),
        ),
        const SizedBox(height: 32),
        DebouncedButton(
          onPressed: () async => onVerify(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(S.of(context).verify),
        ),
        const SizedBox(height: 16),
        DebouncedTextButtonWidget(
          callback: onResend,
          label: S.of(context).resendEmail,
          debounceDuration: const Duration(seconds: 30),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onBack,
          child: Text(backLabel),
        ),
      ],
    );
  }
}
