import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/password_textfield.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/verification_widget.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _newEmail => _emailController.text.trim().toLowerCase();

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _sendCode() async {
    final formState = _formKey.currentState;
    if (formState != null && !formState.validate()) {
      return;
    }
    if (_newEmail.isEmpty ||
        !_looksLikeEmail(_newEmail) ||
        _passwordController.text.isEmpty) {
      showErrorSnackBar(context.l10n.enterSomething);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await authService.sendEmailChangeCode(
        newEmail: _newEmail,
        currentPassword: _passwordController.text,
      );
      if (!mounted) return;
      showSuccessSnackBar(context.l10n.changeEmailCodeSent);
      setState(() {
        _codeSent = true;
        _codeController.clear();
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(e.message ?? context.l10n.changeEmailFailed);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar('${context.l10n.changeEmailFailed}: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    setState(() => _isSubmitting = true);
    try {
      await authService.verifyEmailChangeCode(
        newEmail: _newEmail,
        code: _codeController.text.trim(),
        currentPassword: _passwordController.text,
      );
      if (!mounted) return;
      showSuccessSnackBar(context.l10n.emailChangedSuccessfully);
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(e.message ?? context.l10n.changeEmailFailed);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar('${context.l10n.changeEmailFailed}: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomBarButtons(
      appBar: AppBar(title: Text(context.l10n.changeEmail)),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 60.0),
                Text(context.l10n.changeEmail, style: AppTextStyles.xxlBold),
                const SizedBox(height: 20.0),
                const Icon(Icons.alternate_email, size: 56),
                const SizedBox(height: 28),
                if (!_codeSent) ...[
                  Text(
                    context.l10n.changeEmailInstructions,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.descriptionText,
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: context.l10n.newEmail,
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final email = value?.trim().toLowerCase() ?? '';
                              if (email.isEmpty) {
                                return context.l10n.enterSomething;
                              }
                              if (!_looksLikeEmail(email)) {
                                return context.l10n.invalidEmailEntered;
                              }
                              if (email ==
                                  authService.currentUser?.email
                                      ?.trim()
                                      .toLowerCase()) {
                                return context.l10n.enterSomething;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          PasswordTextField(
                            controller: _passwordController,
                            labelText: context.l10n.currentPassword,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.l10n.enterSomething;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else
                  VerificationWidget(
                    codeController: _codeController,
                    onVerify: _verifyCode,
                    onResend: _sendCode,
                  ),
              ],
            ),
          ),
        ),
      ),
      buttons: [
        if (!_codeSent)
          ButtonWidget(
            isFilled: true,
            label: context.l10n.continueText,
            callback: _isSubmitting ? null : _sendCode,
          )
        else
          ButtonWidget(
            isFilled: true,
            label: context.l10n.verify,
            callback: _isSubmitting ? null : _verifyCode,
          ),
      ],
    );
  }
}
