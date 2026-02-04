import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/mobile/widgets/button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/validate_password.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';

class SetNewPasswordPage extends StatefulWidget {
  const SetNewPasswordPage({super.key});

  @override
  State<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final TextEditingController controllerPw = TextEditingController();
  final TextEditingController controllerConfirmPw = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    controllerPw.dispose();
    controllerConfirmPw.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = authService.currentUser;
      if (user == null) {
        showErrorSnackBar(context.l10n.error);
        return;
      }

      await user.updatePassword(controllerPw.text);
      if (!mounted) return;

      showSuccessSnackBar(context.l10n.passwordChangedSuccessfully);

      // Sign out and go back to login/welcome
      await authService.signOut();
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar('${context.l10n.passwordChangeFailed}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = authService.currentUser?.displayName ?? '';

    return Form(
      key: _formKey,
      child: AppBottomBarButtons(
        appBar: AppBar(title: Text(context.l10n.resetPassword)),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60.0),
                  Text("${S.of(context).hello} $userName", style: AppTextStyles.xlBold),
                  const SizedBox(height: 20.0),
                  Text(
                    context.l10n.resetPassword,
                    style: AppTextStyles.xxlBold,
                  ),
                  const SizedBox(height: 20.0),
                  const Text('🔐', style: AppTextStyles.icons),
                  const SizedBox(height: 50),
                  TextFormField(
                    key: const Key('newPasswordTextField'),
                    controller: controllerPw,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.newPassword,
                    ),
                    validator: (value) => validatePassword(context, value),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('confirmPasswordTextField'),
                    controller: controllerConfirmPw,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.confirmPassword,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.l10n.enterSomething;
                      }
                      if (value != controllerPw.text) {
                        return context.l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        buttons: [
          ButtonWidget(
            key: const Key('confirmButton'),
            isFilled: true,
            label: context.l10n.confirm,
            callback: _updatePassword,
          ),
        ],
      ),
    );
  }
}
