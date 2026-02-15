import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/set_new_password_page.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/debounced_button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/verification_widget.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  TextEditingController controllerEmail = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String errorMessage = '';
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    controllerEmail.text = widget.email;
  }

  @override
  void dispose() {
    controllerEmail.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendLoginCode() async {
    if (controllerEmail.text.trim().isEmpty) {
      setState(() {
        errorMessage = context.l10n.enterSomething;
      });
      return;
    }

    try {
      await authService.sendLoginCode(controllerEmail.text);
      if (!mounted) return;
      showSuccessSnackBar(context.l10n.loginCodeSent);
      setState(() {
        _codeSent = true;
        errorMessage = '';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.message ?? context.l10n.error;
        showErrorSnackBar(errorMessage);
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      showErrorSnackBar(S.of(context).pleaseEnterAValid6digitCode);
      return;
    }

    try {
      await authService.signInWithCode(
        controllerEmail.text,
        code,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SetNewPasswordPage(),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(e.message ?? S.of(context).verificationFailed);
      _codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.resetPassword)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.l10n.resetPassword,
                  style: AppTextStyles.xxlBold,
                ),
                const SizedBox(height: 20.0),
                const Text('🔐', style: AppTextStyles.icons),
                const SizedBox(height: 30),
                if (!_codeSent) ...[
                  TextFormField(
                    key: const Key('emailTestField'),
                    controller: controllerEmail,
                    decoration: InputDecoration(
                      labelText: context.l10n.email,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: AppTextStyles.m.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                  const SizedBox(height: 20),
                  DebouncedButton(
                    key: const Key('sendLoginCodeButton'),
                    onPressed: _sendLoginCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(S.of(context).requestLoginCode),
                  ),
                ] else ...[
                  VerificationWidget(
                    codeController: _codeController,
                    onVerify: _verifyCode,
                    onResend: _sendLoginCode,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
