import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/debounced_button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/debounced_text_button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';

class EmailConfirmationPage extends StatefulWidget {
  const EmailConfirmationPage({super.key});

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      showErrorSnackBar(S.of(context).pleaseEnterAValid6digitCode);
      return;
    }


    try {
      await authService.verifyCode(code);
      if (!mounted) return;
      // If this page was pushed onto the stack (e.g. from OnboardingPage),
      // popping it might reveal the AuthLayout underneath which has now updated.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(e.message ?? S.of(context).verificationFailed);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(S.of(context).anUnexpectedErrorOccurred);
    } finally {
    }
  }

  Future<void> _resendCode() async {
    try {
      await authService.sendVerificationCode();
      if (!mounted) return;
      showSuccessSnackBar(S.of(context).verificationCodeResent);
    } on AuthException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(e.message ?? S.of(context).failedToResendCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.emailVerification)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
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
            TextField(
              key: keys.emailConfirmationPage.verificationCodeTextField,
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            Column(
                children: [
                  DebouncedButton(
                    key: keys.emailConfirmationPage.verifyButton,
                    onPressed: _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(S.of(context).verify),
                  ),
                  const SizedBox(height: 16),
                  DebouncedTextButtonWidget(
                    key: keys.emailConfirmationPage.resendCodeButton,
                    callback: _resendCode,
                    label: context.l10n.resendEmail,
                    debounceDuration: const Duration(seconds: 30),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: keys.emailConfirmationPage.backButton,
                    onPressed: () {
                      authService.signOut();
                    },
                    child: Text(context.l10n.backToLogin),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
