import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/verification_widget.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/generated/l10n.dart';

class EmailConfirmationPage extends StatefulWidget {
  const EmailConfirmationPage({
    super.key,
    this.sendCodeOnLoad = false,
  });

  final bool sendCodeOnLoad;

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.sendCodeOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resendCode(showSuccessFeedback: false);
      });
    }
  }

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
      _codeController.clear();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(S.of(context).anUnexpectedErrorOccurred);
      _codeController.clear();
    }
  }

  Future<void> _resendCode({bool showSuccessFeedback = true}) async {
    try {
      await authService.sendVerificationCode();
      if (!mounted) return;
      if (showSuccessFeedback) {
        showSuccessSnackBar(S.of(context).verificationCodeResent);
      }
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
        child: VerificationWidget(
          codeController: _codeController,
          onVerify: _verifyCode,
          onResend: _resendCode,
        ),
      ),
    );
  }
}
