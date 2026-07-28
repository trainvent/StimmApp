import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_assets.dart';
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

  Widget _buildGoogleSignInButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final asset = switch ((isIos, isDark)) {
      (true, true) => AppAssets.googleSignInIosDark,
      (true, false) => AppAssets.googleSignInIosLight,
      (false, true) => AppAssets.googleSignInAndroidWebDark,
      (false, false) => AppAssets.googleSignInAndroidWebLight,
    };
    final buttonSize = isIos ? const Size(214, 50) : const Size(225, 50);
    if (Localizations.localeOf(context).languageCode == 'de') {
      return SizedBox.fromSize(
        size: buttonSize,
        child: OutlinedButton(
          key: keys.welcomePage.googleSignInButton,
          onPressed: _isGoogleSigningIn ? null : _continueWithGoogle,
          style: OutlinedButton.styleFrom(
            backgroundColor: isDark
                ? const Color(0xFF131314)
                : const Color(0xFFFFFFFF),
            foregroundColor: isDark
                ? const Color(0xFFE3E3E3)
                : const Color(0xFF1F1F1F),
            disabledBackgroundColor: isDark
                ? const Color(0xFF131314)
                : const Color(0xFFFFFFFF),
            disabledForegroundColor: isDark
                ? const Color(0xFFE3E3E3)
                : const Color(0xFF1F1F1F),
            side: BorderSide(
              color: isDark ? const Color(0xFF8E918F) : const Color(0xFF747775),
            ),
            padding: EdgeInsets.symmetric(horizontal: isIos ? 16 : 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _isGoogleSigningIn
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.asset(AppAssets.googleLogo, width: 20, height: 20),
              ),
              Text(context.l10n.continueWithGoogle),
            ],
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: !_isGoogleSigningIn,
      label: context.l10n.continueWithGoogle,
      child: GestureDetector(
        key: keys.welcomePage.googleSignInButton,
        onTap: _isGoogleSigningIn ? null : _continueWithGoogle,
        child: SizedBox.fromSize(
          size: buttonSize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: _isGoogleSigningIn ? 0.55 : 1,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
              if (_isGoogleSigningIn)
                const Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
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
        _buildGoogleSignInButton(context),
      ],
    );
  }
}
