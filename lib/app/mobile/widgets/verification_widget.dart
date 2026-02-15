import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/debounced_text_button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/verification_code_input.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';

class VerificationWidget extends StatefulWidget {
  const VerificationWidget({
    super.key,
    required this.codeController,
    required this.onVerify,
    required this.onResend,
  });

  final TextEditingController codeController;
  final Future<void> Function() onVerify;
  final Future<void> Function() onResend;

  @override
  State<VerificationWidget> createState() => _VerificationWidgetState();
}

class _VerificationWidgetState extends State<VerificationWidget> {
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.onVerify();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
          key: keys.verificationWidget.verificationCodeTextField,
          controller: widget.codeController,
          onCompleted: (_) => _handleVerify(),
        ),
        const SizedBox(height: 32),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          DebouncedTextButtonWidget(
            key: keys.verificationWidget.resendCodeButton,
            callback: widget.onResend,
            label: S.of(context).resendEmail,
            debounceDuration: const Duration(seconds: 30),
          ),
      ],
    );
  }
}
