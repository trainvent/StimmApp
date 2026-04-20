import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bottom_bar_buttons.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/button_widget.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/analytics_service.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';

import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
      ],
    );
  }
}
