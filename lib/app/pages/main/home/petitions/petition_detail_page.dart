import 'package:stimmapp/core/providers/public_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/home/petitions/petition_comments.dart';
import 'package:stimmapp/app/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/widgets/buttons/sign_action_button.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';

class PetitionDetailPage extends ConsumerStatefulWidget {
  const PetitionDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<PetitionDetailPage> createState() => _PetitionDetailPageState();
}

class _PetitionDetailPageState extends ConsumerState<PetitionDetailPage> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final repo = PetitionRepository.create();
    final participantIdsStream = repo.watchParticipantIds(
      widget.id,
      uid: ref.watch(currentUserProvider)?.uid,
    );
    return BaseDetailPage<Petition>(
      id: widget.id,
      appBarTitle: context.l10n.petitionDetails,
      streamProvider: repo.watch,
      publicProfileRepository: ref.watch(publicProfileRepositoryProvider),
      participantsStream: repo.watchParticipants(widget.id),
      participantIdsStream: participantIdsStream,
      signaturesStream: repo.watchSignatures(widget.id),
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
              await BaseDetailPage.showReportDialog(
                context,
                item: petition,
                contentType: 'petition',
              );
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
      allowExpiredContentInteraction: true,
      contentBuilder: (context, p) => ListView(
        children: [
          if (p.imageUrl != null) Image.network(p.imageUrl!),
          PetitionComments(petitionId: widget.id),
        ],
      ),
      bottomAction: SignActionButton(
        submissionId: 'petition:${widget.id}',
        label: context.l10n.sign,
        participantIdsStream: participantIdsStream,
        askForReason: true,
        onAction: ({String? reason}) async {
          final user = authService.currentUser!;
          await repo.sign(widget.id, user.uid, reason: reason);
          if (context.mounted) Navigator.pop(context);
        },
        successMessage: context.l10n.signed,
      ),
    );
  }

  Future<void> _deletePetition(BuildContext context, Petition petition) async {
    if (_isDeleting) return;
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

    if (!context.mounted || _isDeleting) return;
    setState(() => _isDeleting = true);
    try {
      await PetitionRepository.create().delete(petition.id);
      QuotaUpdateNotifier.instance.notify();
      if (context.mounted) {
        showSuccessSnackBar(context.l10n.petitionDeleted);
        Navigator.of(context).pop();
      }
    } on StateError catch (error) {
      if (context.mounted) {
        showErrorSnackBar(
          error.message == 'petition_has_signatures'
              ? context.l10n.cannotDeletePetitionHasSignatures
              : context.l10n.petitionDeletionFailed,
        );
      }
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context.l10n.petitionDeletionFailed);
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
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
