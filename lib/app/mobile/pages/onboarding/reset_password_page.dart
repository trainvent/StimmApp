import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/set_new_password_page.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
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

  void sendLoginCode() async {
    try {
      await authService.sendLoginCode(controllerEmail.text);
      if (!mounted) return;
      showSuccessSnackBar(context.l10n.loginCodeSent);
      if (!mounted) return;
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
    // State variable to track loading inside the dialog
    final ValueNotifier<bool> isLoading = ValueNotifier(false);
    // State variable to show error message inside the dialog
    final ValueNotifier<String?> dialogError = ValueNotifier(null);

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (dialogContext) {
        return ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (context, loading, child) {
            return AlertDialog(
              title: Text(context.l10n.enterCode),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('verificationCodeTextField'),
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    enabled: !loading,
                    decoration: const InputDecoration(
                      hintText: '000000',
                      counterText: '',
                    ),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: dialogError,
                    builder: (context, error, _) {
                      if (error == null) return const SizedBox.shrink();
                      return Padding(
                        key: const Key('error'),
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  if (loading)
                    const Padding(
                      key: Key('loading'),
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  key: const Key('cancelButton'),
                  onPressed: loading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  key: const Key('confirmButton'),
                  onPressed: loading
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.length != 6) return;

                          isLoading.value = true;
                          dialogError.value = null;

                          // Capture the parent context before the async gap
                          final parentContext = context;

                          try {
                            await authService.signInWithCode(
                              controllerEmail.text,
                              code,
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext); // Close dialog

                            if (!mounted) return;
                            Navigator.of(parentContext).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SetNewPasswordPage(),
                              ),
                            );
                          } on AuthException catch (e) {
                            isLoading.value = false;
                            // Show error in the dialog UI instead of just a snackbar
                            dialogError.value = e.message ?? 'Error';

                            // Clear the code field on error
                            codeController.clear();

                            // Also show snackbar for accessibility/consistency if needed,
                            // but the text in dialog is better for tests waiting for text.
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(e.message ?? 'Error')),
                              );
                            }
                          }
                        },
                  child: Text(context.l10n.confirm),
                ),
              ],
            );
          },
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
                          key: const Key('emailTestField'),
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
                  const SizedBox(height: 10),
                  TextButton(
                    key: const Key('sendLoginCodeButton'),
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
