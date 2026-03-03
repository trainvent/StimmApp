import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/sign_action_button.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

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
        if (currentUid == null || currentUid == poll.createdBy) {
          return const SizedBox.shrink();
        }
        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'report') {
              await _showReportDialog(context, poll);
            } else if (value == 'block') {
              await _confirmBlockUser(context, poll);
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

  Future<void> _showReportDialog(BuildContext context, Poll poll) async {
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
                      reportedUserId: poll.createdBy,
                      contentType: 'poll',
                      contentId: poll.id,
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

  Future<void> _confirmBlockUser(BuildContext context, Poll poll) async {
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
      blockedUserId: poll.createdBy,
      contentType: 'poll',
      contentId: poll.id,
      details: 'User blocked from poll detail page.',
    );
    if (context.mounted) {
      showSuccessSnackBar('User blocked. Their content is now hidden.');
      Navigator.of(context).pop();
    }
  }
}
