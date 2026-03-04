import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/sign_action_button.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';

class PollDetailPage extends StatefulWidget {
  const PollDetailPage({super.key, required this.id});
  final String id;

  @override
  State<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends State<PollDetailPage> {
  String? _selectedOptionId;

  @override
  Widget build(BuildContext context) {
    final repo = PollRepository.create();
    return BaseDetailPage<Poll>(
      id: widget.id,
      appBarTitle: context.l10n.pollDetails,
      streamProvider: repo.watch,
      participantsStream: repo.watchParticipants(widget.id),
      sharePathSegment: 'poll',
      topRightActionBuilder: (context, poll) {
        final currentUid = authService.currentUser?.uid;
        if (currentUid == null) {
          return const SizedBox.shrink();
        }
        if (currentUid == poll.createdBy) {
          final canDelete = poll.totalVotes == 0;
          return PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                await _deletePoll(context, poll);
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
              await _showReportDialog(context, poll);
            } else if (value == 'block') {
              await _confirmBlockUser(context, poll);
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
      contentBuilder: (context, poll) {
        final total = poll.totalVotes;
        return RadioGroup<String>(
          groupValue: _selectedOptionId,
          onChanged: (v) => setState(() => _selectedOptionId = v),
          child: ListView(
            children: [
              ...poll.options.map((o) {
                final count = poll.votes[o.id] ?? 0;
                final pct = total == 0 ? 0 : (count / total * 100).round();
                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(o.label)),
                      Text('$count • $pct%'),
                    ],
                  ),
                  leading: Radio<String>(value: o.id),
                  onTap: () => setState(() => _selectedOptionId = o.id),
                );
              }),
            ],
          ),
        );
      },
      bottomAction: SignActionButton(
        label: context.l10n.vote,
        participantsStream: repo.watchParticipants(widget.id),
        onAction: ({String? reason}) async {
          final optionId = _selectedOptionId;
          if (optionId == null) return;
          final user = authService.currentUser!;
          await repo.vote(pollId: widget.id, optionId: optionId, uid: user.uid);
          if (context.mounted) Navigator.pop(context);
        },
        successMessage: context.l10n.voted,
      ),
    );
  }

  Future<void> _deletePoll(BuildContext context, Poll poll) async {
    if (poll.totalVotes != 0) {
      showErrorSnackBar(context.l10n.cannotDeletePollHasVotes);
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

    await PollRepository.create().delete(poll.id);
    QuotaUpdateNotifier.instance.notify();
    if (context.mounted) {
      showSuccessSnackBar(context.l10n.pollDeleted);
      Navigator.of(context).pop();
    }
  }

  Future<void> _showReportDialog(BuildContext context, Poll poll) async {
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
                      reportedUserId: poll.createdBy,
                      contentType: 'poll',
                      contentId: poll.id,
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

  Future<void> _confirmBlockUser(BuildContext context, Poll poll) async {
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
      blockedUserId: poll.createdBy,
      contentType: 'poll',
      contentId: poll.id,
      details: 'User blocked from poll detail page.',
    );
    if (context.mounted) {
      showSuccessSnackBar(context.l10n.userBlockedContentHidden);
      Navigator.of(context).pop();
    }
  }
}
