import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/widgets/buttons/login_provider_button_widget.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/analytics_service.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';

import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isGoogleSigningIn = false;

  bool get _showsAppleSignIn =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Widget _buildAppleSignInButton(BuildContext context) {
    // Authentication will be connected after the Apple Developer and Firebase
    // provider configuration is in place.
    return LoginProviderButtonWidget(
      key: keys.welcomePage.appleSignInButton,
      provider: LoginProvider.apple,
      label: 'Apple',
      semanticLabel: context.l10n.continueWithApple,
      onPressed: null,
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context) {
    return LoginProviderButtonWidget(
      key: keys.welcomePage.googleSignInButton,
      provider: LoginProvider.google,
      label: 'Google',
      semanticLabel: context.l10n.continueWithGoogle,
      onPressed: _isGoogleSigningIn ? null : _continueWithGoogle,
      isLoading: _isGoogleSigningIn,
    );
  }

  Widget _buildProviderSignInButtons(BuildContext context) {
    final googleButton = _buildGoogleSignInButton(context);
    if (!_showsAppleSignIn) return googleButton;

    return Row(
      children: [
        Expanded(child: googleButton),
        const SizedBox(width: 10),
        Expanded(child: _buildAppleSignInButton(context)),
      ],
    );
  }

  Future<void> _continueWithGoogle() async {
    if (_isGoogleSigningIn) return;

    setState(() => _isGoogleSigningIn = true);
    try {
      await authService.signInWithGoogle();
      unawaited(
        AnalyticsService.instance.logAuthResult(
          action: 'google_sign_in',
          success: true,
        ),
      );
    } on AuthException catch (e) {
      debugPrint(
        'Google sign-in Firebase failure '
        '(code: ${e.code}, message: ${e.message})',
      );
      unawaited(
        AnalyticsService.instance.logAuthResult(
          action: 'google_sign_in',
          success: false,
          errorCode: e.code,
        ),
      );
      if (!mounted || e.code == 'google-sign-in-cancelled') return;
      showErrorSnackBar(e.message ?? context.l10n.googleSignInFailed);
    } catch (e, st) {
      debugPrint('Google sign-in failed: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context.l10n.googleSignInFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomBarButtons(
      body: Center(
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Image.asset('assets/images/Lemm_waving.png'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: context.l10n.welcomeTo,
                            style: AppTextStyles.xxlRed,
                          ),
                          TextSpan(
                            text: context.localizedAppName,
                            style: AppTextStyles.xxlRed,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.theWelcomePhrase,
                    style: AppTextStyles.m.copyWith(color: Colors.teal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      buttons: [
        ButtonWidget(
          key: const Key('register_button'),
          label: context.l10n.register,
          isFilled: true,
          callback: () {
            AnalyticsService.instance.logAuthFlowOpened('register');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return const RegisterPage();
                },
              ),
            );
          },
        ),
        const SizedBox(height: 10.0),
        ButtonWidget(
          key: const Key('login_button'),
          label: context.l10n.login,
          callback: () {
            AnalyticsService.instance.logAuthFlowOpened('login');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return const LoginPage();
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.l10n.orSeparator,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider(thickness: 1)),
          ],
        ),
        const SizedBox(height: 16),
        _buildProviderSignInButtons(context),
      ],
    );
  }
}
