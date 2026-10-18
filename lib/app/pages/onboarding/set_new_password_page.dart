import 'package:stimmapp/app/widgets/lemm_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stimmapp/app/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/widgets/password_textfield.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/validate_password.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:trainvent_general/trainvent_general.dart';

class SetNewPasswordPage extends StatefulWidget {
  const SetNewPasswordPage({super.key});

  @override
  State<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final TextEditingController controllerPw = TextEditingController();
  final TextEditingController controllerConfirmPw = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;

  @override
  void dispose() {
    controllerPw.dispose();
    controllerConfirmPw.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_isUpdating || !_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);

    try {
      final user = authService.currentUser;
      if (user == null) {
        showUserMistakeSnackBar(context.l10n.passwordResetSessionExpired);
        return;
      }

      await user.updatePassword(controllerPw.text);
      if (!mounted) return;

      final successMessage = context.l10n.passwordChangedSuccessfully;
      final route = ModalRoute.of(context);
      FocusManager.instance.primaryFocus?.unfocus();

      // Sign out and go back to login/welcome
      await authService.signOut();
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
      // Let the outgoing scaffold and its buttons leave before positioning
      // the snackbar on the destination scaffold.
      if (route != null && !route.isCurrent) await route.completed;
      await WidgetsBinding.instance.endOfFrame;
      showSuccessSnackBar(successMessage);
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      final message = switch (e) {
        FirebaseAuthException(
          code: 'requires-recent-login' ||
              'user-token-expired' ||
              'invalid-user-token',
        ) =>
          l10n.passwordResetSessionExpired,
        FirebaseAuthException(code: 'network-request-failed') =>
          l10n.passwordResetConnectionFailed,
        FirebaseAuthException(code: 'too-many-requests') =>
          l10n.passwordResetTryLater,
        FirebaseAuthException(code: 'weak-password') =>
          l10n.passwordResetChooseStronger,
        _ => l10n.passwordResetFailed,
      };
      showUserMistakeSnackBar(message);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = authService.currentUser?.displayName ?? '';
    final passwordIllustration = LemmImage(
      assetPath: 'assets/images/Lemm_pen_password.png',
      height: 180,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );

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
                  Text(
                    "${S.of(context).hello} $userName",
                    style: AppTextStyles.xlBold,
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    context.l10n.pleaseEnterNewPassword,
                    style: AppTextStyles.l,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  passwordIllustration,
                  const SizedBox(height: 24),
                  AutofillGroup(
                    child: Column(
                      children: [
                        PasswordTextField(
                          key: const Key('newPasswordTextField'),
                          controller: controllerPw,
                          labelText: context.l10n.newPassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (value) =>
                              validatePassword(context, value),
                        ),
                        const SizedBox(height: 10),
                        PasswordTextField(
                          key: const Key('confirmPasswordTextField'),
                          controller: controllerConfirmPw,
                          labelText: context.l10n.confirmPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
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
                ],
              ),
            ),
          ),
        ),
        buttons: [
          ElevatedButton(
            key: const Key('confirmButton'),
            onPressed: _isUpdating ? null : _updatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isUpdating
                ? const SizedBox.square(
                    dimension: 24,
                    child: Center(
                      child: TriangleLoadingIndicator(
                        size: 20,
                        showFill: false,
                        strokeColor: Colors.black,
                      ),
                    ),
                  )
                : Text(context.l10n.confirm),
          ),
        ],
      ),
    );
  }
}
