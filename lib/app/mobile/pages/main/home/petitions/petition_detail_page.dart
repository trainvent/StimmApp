import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/sign_action_button.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';

class PetitionDetailPage extends StatelessWidget {
  const PetitionDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = PetitionRepository.create();
    return BaseDetailPage<Petition>(
      id: id,
      appBarTitle: context.l10n.petitionDetails,
      streamProvider: repo.watch,
      participantsStream: repo.watchParticipants(id),
      signaturesStream: repo.watchSignatures(id),
      sharePathSegment: 'petition',
      topRightActionBuilder: (context, petition) {
        final currentUid = authService.currentUser?.uid;
        if (currentUid == null) {
          return const SizedBox.shrink();
        }
        if (currentUid == petition.createdBy) {
          final canDelete = petition.signatureCount == 0;
          return PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                await _deletePetition(context, petition);
              }
            },
            itemBuilder: (context) => canDelete
                ? [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(context.l10n.deleteForm),
                    ),
                  ]
                : [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(context.l10n.noFittingOptions),
                    ),
                  ],
          );
        }
        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'report') {
              await _showReportDialog(context, petition);
            } else if (value == 'block') {
              await _confirmBlockUser(context, petition);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'report',
              child: Text(context.l10n.reportContent),
            ),
            PopupMenuItem<String>(
              value: 'block',
              child: Text(context.l10n.blockUser),
            ),
          ],
        );
      },
      contentBuilder: (context, p) {
        if (p.imageUrl != null) {
          return Image.network(p.imageUrl!);
        }
        return const SizedBox.shrink();
      },
      bottomAction: SignActionButton(
        label: context.l10n.sign,
        participantsStream: repo.watchParticipants(id),
        askForReason: true,
        onAction: ({String? reason}) async {
          final user = authService.currentUser!;
          await repo.sign(id, user.uid, reason: reason);
          if (context.mounted) Navigator.pop(context);
        },
        successMessage: context.l10n.signed,
      ),
    );
  }

  Future<void> _deletePetition(
    BuildContext context,
    Petition petition,
  ) async {
    if (petition.signatureCount != 0) {
      showErrorSnackBar(context.l10n.cannotDeletePetitionHasSignatures);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteForm),
        content: Text(context.l10n.areYouSureYouWantToDeleteThisForm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    await PetitionRepository.create().delete(petition.id);
    QuotaUpdateNotifier.instance.notify();
    if (context.mounted) {
      showSuccessSnackBar(context.l10n.petitionDeleted);
      Navigator.of(context).pop();
    }
  }

  Future<void> _showReportDialog(
    BuildContext context,
    Petition petition,
  ) async {
    final detailsController = TextEditingController();
    String selectedReason = 'harassment';
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final reportContent = context.l10n.reportContent;
            final additionalDetailsOptional =
                context.l10n.additionalDetailsOptional;
            final cancel = context.l10n.cancel;
            final submit = context.l10n.submit;
            final harassmentOrBullying = context.l10n.harassmentOrBullying;
            final hateSpeech = context.l10n.hateSpeech;
            final sexualOrExplicitContent =
                context.l10n.sexualOrExplicitContent;
            final violenceOrThreats = context.l10n.violenceOrThreats;
            final misinformationOrFraud = context.l10n.misinformationOrFraud;
            final reportSubmittedReview24Hours =
                context.l10n.reportSubmittedReview24Hours;
            return AlertDialog(
              title: Text(reportContent),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    items: [
                      DropdownMenuItem(
                        value: 'harassment',
                        child: Text(harassmentOrBullying),
                      ),
                      DropdownMenuItem(
                        value: 'hate_speech',
                        child: Text(hateSpeech),
                      ),
                      DropdownMenuItem(
                        value: 'sexual_content',
                        child: Text(sexualOrExplicitContent),
                      ),
                      DropdownMenuItem(
                        value: 'violence',
                        child: Text(violenceOrThreats),
                      ),
                      DropdownMenuItem(
                        value: 'misinformation',
                        child: Text(misinformationOrFraud),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedReason = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: additionalDetailsOptional,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final reporterId = authService.currentUser?.uid;
                    if (reporterId == null) {
                      return;
                    }
                    await ModerationRepository.create().submitReport(
                      reporterId: reporterId,
                      reportedUserId: petition.createdBy,
                      contentType: 'petition',
                      contentId: petition.id,
                      reason: selectedReason,
                      details: detailsController.text,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      showSuccessSnackBar(reportSubmittedReview24Hours);
                    }
                  },
                  child: Text(submit),
                ),
              ],
            );
          },
        );
      },
    );
    detailsController.dispose();
  }

  Future<void> _confirmBlockUser(
    BuildContext context,
    Petition petition,
  ) async {
    final shouldBlock = await showDialog<bool>(
      context: context,
      builder: (context) {
        final blockUser = context.l10n.blockUser;
        final blockUserDescription = context.l10n.blockUserDescription;
        final cancel = context.l10n.cancel;
        return AlertDialog(
          title: Text(blockUser),
          content: Text(blockUserDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(blockUser),
            ),
          ],
        );
      },
    );

    if (shouldBlock != true) {
      return;
    }

    final blockerId = authService.currentUser?.uid;
    if (blockerId == null) {
      return;
    }
    await ModerationRepository.create().blockUser(
      blockerId: blockerId,
      blockedUserId: petition.createdBy,
      contentType: 'petition',
      contentId: petition.id,
      details: 'User blocked from petition detail page.',
    );
    if (context.mounted) {
      showSuccessSnackBar(context.l10n.userBlockedContentHidden);
      Navigator.of(context).pop();
    }
  }
}
