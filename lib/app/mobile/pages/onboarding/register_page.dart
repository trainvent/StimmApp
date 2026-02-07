import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/email_confirmation_page.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/mobile/widgets/debounced_button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/validate_password.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:stimmapp/generated/l10n.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController controllerPw = TextEditingController();
  final TextEditingController controllerConfirmPw = TextEditingController();
  final TextEditingController controllerEm = TextEditingController();

  String errorMessage = 'Error message';

  @override
  void dispose() {
    controllerPw.dispose();
    controllerConfirmPw.dispose();
    controllerEm.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (controllerPw.text != controllerConfirmPw.text) {
      showErrorSnackBar(context.l10n.passwordsDoNotMatch);
      return;
    }

    try {
      await authService.createAccount(
        email: controllerEm.text.trim(),
        password: controllerPw.text,
      );
      if (!mounted) return;
      // Navigate to the new code-based confirmation page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const EmailConfirmationPage()),
      );
    } on AuthException catch (e) {
      setState(() {
        errorMessage = '${e.code}: ${e.message ?? 'Unknown error'}';
      });
      showErrorSnackBar(errorMessage);
    } on DatabaseException catch (e) {
      setState(() {
        errorMessage =
            'Database error (${e.code}): ${e.message ?? 'Unknown error'}';
      });
      debugPrintStack(
        label: 'register database error',
        stackTrace: StackTrace.current,
      );
      showErrorSnackBar(errorMessage);
    } catch (e, st) {
      // Fallback for any other exceptiFon
      setState(() {
        errorMessage = 'Unexpected error: $e';
      });
      debugPrintStack(label: 'register error', stackTrace: st);
      showErrorSnackBar(errorMessage);
    }
  }

  Future<void> registerWithEId() async {
    var result = "defaultUser";
    var randomName = "HANA";
    if (kIsWeb) {
      showSuccessSnackBar(context.l10n.pleaseUsePhoneToRegister);
    } else {
      // Dynamically construct the channel name based on the package name
      // This ensures it matches the Android side for both dev and prod flavors.
      final packageInfo = await PackageInfo.fromPlatform();
      final channelName = '${packageInfo.packageName}/eid';
      final platform = MethodChannel(channelName);

      try {
        final Map<dynamic, dynamic> callResult = await platform.invokeMethod(
          'passDataToNative',
          [
            {"text": "HANA"},
          ],
        );
        result = callResult['userName'] ?? "defaultUser";
        if (result == randomName) {
          showSuccessSnackBar(result);
        } else {
          showErrorSnackBar("expected: $randomName, got: $result");
        }
      } on PlatformException catch (e) {
        showErrorSnackBar("Native call failed: ${e.message}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Builder(
        builder: (context) {
          return AppBottomBarButtons(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: BackButton(color: Theme.of(context).colorScheme.primary),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: DConst.padBox),
                  Text(
                    context.l10n.registerHere,
                    style: AppTextStyles.xxlBold.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: DConst.padBox),
                  Text(
                    S.of(context).welcomePleaseEnterYourDetails,
                    style: AppTextStyles.m.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 30.0),
                  TextFormField(
                    key: keys.onboardingPage.emailTextField,
                    controller: controllerEm,
                    decoration: InputDecoration(
                      labelText: context.l10n.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return S.of(context).pleaseEnterYourEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: DConst.padBox),
                  TextFormField(
                    key: keys.onboardingPage.passwordTextField,
                    obscureText: true,
                    controller: controllerPw,
                    decoration: InputDecoration(
                      labelText: context.l10n.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => validatePassword(context, value),
                  ),
                  const SizedBox(height: DConst.padBox),
                  TextFormField(
                    key: const Key('repeatPasswordTextField'),
                    obscureText: true,
                    controller: controllerConfirmPw,
                    decoration: InputDecoration(
                      labelText: context.l10n.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.pleaseEnterYourPassword;
                      }
                      if (value != controllerPw.text) {
                        return context.l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) {
                      if (Form.of(context).validate()) {
                        register();
                      } else {
                        showErrorSnackBar(context.l10n.error);
                      }
                    },
                  ),
                  const SizedBox(height: DConst.padBox),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        "assets/images/form_guy_register.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: DConst.padBox),
                ],
              ),
            ),
            buttons: [
              DebouncedButton(
                key: keys.onboardingPage.registerButton,
                onPressed: () async {
                  if (Form.of(context).validate()) {
                    await register();
                  } else {
                    showErrorSnackBar(errorMessage);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(context.l10n.register),
              ),
            ],
          );
        },
      ),
    );
  }
}
