import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/login_page.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/welcome_page.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class SignActionButton extends StatelessWidget {
  const SignActionButton({
    super.key,
    required this.label,
    required this.participantsStream,
    required this.onAction,
    required this.successMessage,
  });

  final String label;
  final Stream<List<UserProfile>> participantsStream;
  final Future<void> Function() onAction;
  final String successMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: participantsStream,
      builder: (context, snap) {
        final uid = authService.currentUser?.uid;
        final participants = snap.data ?? const [];
        final alreadySigned =
            uid != null && participants.any((p) => p.uid == uid);
        final loading = snap.connectionState == ConnectionState.waiting;
        final disabled = alreadySigned || loading;

        return ElevatedButton(
          key: keys.petitionDetailPage.signButton,
          onPressed: disabled
              ? null
              : () async {
                  final user = authService.currentUser;
                  if (user == null) {
                    if (!context.mounted) return;
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const _LoginBottomSheet(),
                    );
                    // After bottom sheet closes, check if user is logged in
                    if (authService.currentUser != null) {
                      try {
                        await onAction();
                        if (!context.mounted) return;
                        showSuccessSnackBar(successMessage);
                      } catch (e) {
                        if (!context.mounted) return;
                        showErrorSnackBar(e.toString());
                      }
                    }
                    return;
                  }
                  try {
                    await onAction();
                    if (!context.mounted) return;
                    showSuccessSnackBar(successMessage);
                  } catch (e) {
                    if (!context.mounted) return;
                    showErrorSnackBar(e.toString());
                  }
                },
          child: Text(alreadySigned ? '⛔ $label ⛔' : label),
        );
      },
    );
  }
}

class _LoginBottomSheet extends StatelessWidget {
  const _LoginBottomSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: const _LoginContent(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(child: LoginPage(isEmbedded: true)),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Column(
              children: [
                Text(context.l10n.notSignedUpYet),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    // Close the bottom sheet and navigate to WelcomePage
                    // We need to find the navigator of the main app, not the nested one
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const WelcomePage(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(context.l10n.goToWelcome),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
