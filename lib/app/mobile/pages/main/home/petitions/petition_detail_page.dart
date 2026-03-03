import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/sign_action_button.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

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
        if (currentUid == null || currentUid == petition.createdBy) {
          return const SizedBox.shrink();
        }
        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'report') {
              await _showReportDialog(context, petition);
            } else if (value == 'block') {
              await _confirmBlockUser(context, petition);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'report',
              child: Text('Report content'),
            ),
            PopupMenuItem<String>(value: 'block', child: Text('Block user')),
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
            return AlertDialog(
              title: const Text('Report content'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    items: const [
                      DropdownMenuItem(
                        value: 'harassment',
                        child: Text('Harassment or bullying'),
                      ),
                      DropdownMenuItem(
                        value: 'hate_speech',
                        child: Text('Hate speech'),
                      ),
                      DropdownMenuItem(
                        value: 'sexual_content',
                        child: Text('Sexual or explicit content'),
                      ),
                      DropdownMenuItem(
                        value: 'violence',
                        child: Text('Violence or threats'),
                      ),
                      DropdownMenuItem(
                        value: 'misinformation',
                        child: Text('Misinformation or fraud'),
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
                    decoration: const InputDecoration(
                      labelText: 'Additional details (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
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
                      showSuccessSnackBar(
                        'Report submitted. We review reports within 24 hours.',
                      );
                    }
                  },
                  child: const Text('Submit'),
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
        return AlertDialog(
          title: const Text('Block user'),
          content: const Text(
            'This will hide this user\'s content from your feed immediately and notify the StimmApp team for review.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Block user'),
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
      showSuccessSnackBar('User blocked. Their content is now hidden.');
      Navigator.of(context).pop();
    }
  }
}
