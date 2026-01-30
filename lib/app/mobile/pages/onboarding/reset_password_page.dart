import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/mobile/widgets/button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  TextEditingController controllerEmail = TextEditingController();
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    controllerEmail.text = widget.email;
  }

  @override
  void dispose() {
    controllerEmail.dispose();
    super.dispose();
  }

  void resetPassword() async {
    try {
      await authService.resetPassword(email: controllerEmail.text);
      if (!mounted) return;
      showSuccessSnackBar(context.l10n.resetPasswordLinkSent);
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.message ?? context.l10n.error;
        showErrorSnackBar(errorMessage);
      });
    }
  }

  void sendLoginCode() async {
    try {
      await authService.sendLoginCode(controllerEmail.text);
      if (!mounted) return;
      showSuccessSnackBar(context.l10n.loginLinkSent);
      _showEnterCodeDialog();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.message ?? context.l10n.error;
        showErrorSnackBar(errorMessage);
      });
    }
  }

  void _showEnterCodeDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.enterCode),
          content: TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.length != 6) return;

                try {
                  await authService.signInWithCode(controllerEmail.text, code);
                  if (!mounted) return;
                  // Close dialog
                  Navigator.pop(context);
                  // Close ResetPasswordPage and go back to root (which will show home)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } on AuthException catch (e) {
                  if (!mounted) return;
                  showErrorSnackBar(e.message ?? context.l10n.error);
                }
              },
              child: Text(context.l10n.confirm),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: AppBottomBarButtons(
        appBar: AppBar(title: Text(context.l10n.resetPassword)),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60.0),
                  Text(
                    context.l10n.resetPassword,
                    style: AppTextStyles.xxlBold,
                  ),
                  const SizedBox(height: 20.0),
                  const Text('🔐', style: AppTextStyles.icons),
                  const SizedBox(height: 50),
                  Center(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: controllerEmail,
                          decoration: InputDecoration(
                            labelText: context.l10n.email,
                          ),
                          validator: (String? value) {
                            if (value == null) {
                              return context.l10n.enterSomething;
                            }
                            if (value.trim().isEmpty) {
                              return context.l10n.enterSomething;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          errorMessage,
                          style: AppTextStyles.m.copyWith(
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        buttons: [
          Builder(
            builder: (context) {
              return Column(
                children: [
                  ButtonWidget(
                    isFilled: true,
                    label: context.l10n.resetPassword,
                    callback: () async {
                      if (Form.of(context).validate()) {
                        resetPassword();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      if (Form.of(context).validate()) {
                        sendLoginCode();
                      }
                    },
                    child: Text(context.l10n.sendLoginLink),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
