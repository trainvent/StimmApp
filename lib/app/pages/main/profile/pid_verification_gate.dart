import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/profile/pid_verification_page.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

enum PidVerificationGateAction { publishPetition, signPetition }

/// Checks the current server-backed profile before a PID-gated action.
///
/// Firestore rules remain authoritative; this gate exists to give the user an
/// actionable route to verification instead of exposing a permission error.
Future<bool> ensureCurrentPidVerification(
  BuildContext context, {
  required PidVerificationGateAction action,
}) async {
  final user = authService.currentUser;
  if (user == null) return false;

  final profile = await UserRepository.create().watchById(user.uid).first;
  if (profile?.hasValidIdentityVerification == true) return true;
  if (!context.mounted) return false;

  final explanation = switch (action) {
    PidVerificationGateAction.publishPetition =>
      context.l10n.pidVerificationRequiredToPublishPetition,
    PidVerificationGateAction.signPetition =>
      context.l10n.pidVerificationRequiredToSignPetition,
  };

  final openVerification = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.pidVerificationRequired),
      content: Text(explanation),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(context.l10n.verify),
        ),
      ],
    ),
  );

  if (openVerification == true && context.mounted) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PidVerificationPage(
          reverify: profile?.hasIdentityVerificationHistory == true,
        ),
      ),
    );
  }

  // Require an explicit retry after returning so publication/signing cannot
  // happen accidentally as a side effect of completing verification.
  return false;
}
