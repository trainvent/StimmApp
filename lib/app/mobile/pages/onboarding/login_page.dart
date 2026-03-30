import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/password_textfield.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';

import 'reset_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.isEmbedded = false});
  final bool isEmbedded;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController controllerEm = TextEditingController(text: '');
  TextEditingController controllerPw = TextEditingController(text: '');
  String errorMessage = '';

  @override
  void dispose() {
    controllerPw.dispose();
    controllerEm.dispose();
    super.dispose();
  }

  void signIn() async {
    // Capture localized messages before the async gap.

    try {
      await authService.signIn(
        email: controllerEm.text,
        password: controllerPw.text,
      );
      if (mounted) popPage();
    } on AuthException catch (e) {
      errorMessage = e.toString();
      if (!mounted) return;
      showErrorSnackBar(errorMessage);
      // Clear password field on error, but keep email
      controllerPw.clear();
    }
  }

  void popPage() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Builder(
        builder: (context) {
          return AppBottomBarButtons(
            appBar: widget.isEmbedded
                ? null
                : AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: BackButton(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      context.l10n.signIn,
                      style: AppTextStyles.xxlBold.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isEmbedded) ...[
                    const SizedBox(height: DConst.padBox),
                    Text(
                      context.l10n.signIn,
                      style: AppTextStyles.xxlBold.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: DConst.padBox),
                  Text(
                    S.of(context).pleaseEnterYourCredentials,
                    style: AppTextStyles.m.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: DConst.padBox),
                  TextFormField(
                    key: keys.loginPage.emailTextField,
                    controller: controllerEm,
                    decoration: InputDecoration(
                      labelText: context.l10n.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
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
                  const SizedBox(height: DConst.padBox),
                  PasswordTextField(
                    key: keys.loginPage.passwordTextField,
                    controller: controllerPw,
                    labelText: context.l10n.password,
                    isDense: true,
                    validator: (String? value) {
                      if (value == null) {
                        return context.l10n.enterSomething;
                      }
                      if (value.trim().isEmpty) {
                        return context.l10n.enterSomething;
                      }
                      return null;
                    },
                    style: AppTextStyles.m,
                    onFieldSubmitted: (value) {
                      if (Form.of(context).validate()) {
                        signIn();
                      } else {
                        showErrorSnackBar(errorMessage);
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: keys.loginPage.forgotPasswordButton,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ResetPasswordPage(
                                email: controllerEm.text,
                              );
                            },
                          ),
                        );
                      },
                      child: Text(
                        context.l10n.resetPassword,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DConst.padBox),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        "assets/images/Lemm_login.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: DConst.padBox),
                ],
              ),
            ),
            buttons: [
              ButtonWidget(
                key: keys.loginPage.signInButton,
                isFilled: true,
                label: context.l10n.signIn,
                callback: () {
                  if (Form.of(context).validate()) {
                    signIn();
                  } else {
                    showErrorSnackBar(errorMessage);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
