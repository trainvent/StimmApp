import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/button_widget.dart';
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
  bool _isLoading = false;

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

    setState(() => _isLoading = true);

    try {
      await authService.verifyCode(code);
      if (!mounted) return;
      showSuccessSnackBar(S.of(context).emailVerifiedSuccessfully);

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    try {
      await authService.sendVerificationCode();
      if (!mounted) return;
      showSuccessSnackBar(S.of(context).verificationCodeResent);
    } on AuthException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(e.message ?? S.of(context).failedToResendCode);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              'Enter Verification Code',
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
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ButtonWidget(
                    key: keys.emailConfirmationPage.verifyButton,
                    callback: _verifyCode,
                    label: S.of(context).verify,
                    isFilled: true,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    key: keys.emailConfirmationPage.resendCodeButton,
                    onPressed: _resendCode,
                    child: Text(context.l10n.resendEmail),
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
