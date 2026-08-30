import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/pages/onboarding/login_page.dart';
import 'package:stimmapp/app/pages/onboarding/welcome_page.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/providers/app_preferences_provider.dart';
import 'package:stimmapp/core/providers/deferred_submission_provider.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:trainvent_general/trainvent_general.dart';

class SignActionButton extends ConsumerWidget {
  const SignActionButton({
    super.key,
    required this.submissionId,
    required this.label,
    required this.participantIdsStream,
    required this.onAction,
    required this.successMessage,
    this.preflight,
    this.askForReason = false,
  });

  final String submissionId;
  final String label;
  final Stream<Set<String>> participantIdsStream;
  final Future<void> Function({String? reason}) onAction;
  final Future<bool> Function()? preflight;
  final String successMessage;
  final bool askForReason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showPetitionReason = ref.watch(showPetitionReasonProvider);
    final submissionPhase = ref.watch(
      deferredSubmissionProvider.select((state) => state[submissionId]),
    );
    final isPending = submissionPhase == DeferredSubmissionPhase.pending;
    final isCommitting = submissionPhase == DeferredSubmissionPhase.committing;

    return StreamBuilder<Set<String>>(
      stream: participantIdsStream,
      builder: (context, snap) {
        final uid = authService.currentUser?.uid;
        final participantIds = snap.data ?? const <String>{};
        final alreadySigned = uid != null && participantIds.contains(uid);
        final loading = snap.connectionState == ConnectionState.waiting;
        final disabled = alreadySigned || loading || isCommitting;

        return ElevatedButton(
          key: keys.petitionDetailPage.signButton,
          onPressed: isPending
              ? () => ref
                    .read(deferredSubmissionProvider.notifier)
                    .cancel(submissionId)
              : disabled
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
                      if (!context.mounted) return;
                      await _queueSubmission(context, ref, showPetitionReason);
                    }
                    return;
                  }
                  await _queueSubmission(context, ref, showPetitionReason);
                },
          child: isPending || isCommitting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TriangleLoadingIndicator(
                      size: 20,
                      showFill: false,
                      strokeColor: Theme.of(context).colorScheme.onPrimary,
                      iterationDuration:
                          DeferredSubmissionController.undoDuration,
                      iterations: 1,
                    ),
                    const SizedBox(width: 10),
                    Text(isPending ? context.l10n.undo : label),
                  ],
                )
              : Text(alreadySigned ? '⛔ $label ⛔' : label),
        );
      },
    );
  }

  Future<void> _queueSubmission(
    BuildContext context,
    WidgetRef ref,
    bool showPetitionReason,
  ) async {
    if (preflight != null && !await preflight!()) return;
    if (!context.mounted) return;

    String? reason;
    if (askForReason && showPetitionReason) {
      reason = await showDialog<String>(
        context: context,
        builder: (context) {
          String tempReason = '';
          return AlertDialog(
            title: Text(S.of(context).whyAreYouSigning),
            content: TextField(
              onChanged: (value) => tempReason = value,
              decoration: InputDecoration(
                hintText: S.of(context).enterYourReasonHere,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('Skip'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, tempReason),
                child: Text('Submit'),
              ),
            ],
          );
        },
      );
    }

    if (!context.mounted) return;
    ref
        .read(deferredSubmissionProvider.notifier)
        .queue(
          id: submissionId,
          action: () => onAction(reason: reason),
          onSuccess: () => showSuccessSnackBar(successMessage),
          onError: (error) {
            if (error is StateError) {
              showErrorSnackBar(error.message);
            } else {
              showErrorSnackBar(error.toString());
            }
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
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushAndRemoveUntil(
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
