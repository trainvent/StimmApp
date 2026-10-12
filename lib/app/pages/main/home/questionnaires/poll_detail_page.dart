import 'package:stimmapp/core/providers/public_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/app/widgets/buttons/sign_action_button.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';

class PollDetailPage extends ConsumerStatefulWidget {
  const PollDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends ConsumerState<PollDetailPage> {
  String? _selectedOptionId;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUserProvider)?.uid;
    final repo = PollRepository.create();
    final participantIdsStream = repo.watchParticipantIds(
      widget.id,
      uid: currentUid,
    );
    return BaseDetailPage<Poll>(
      id: widget.id,
      appBarTitle: context.l10n.pollDetails,
      streamProvider: repo.watch,
      publicProfileRepository: ref.watch(publicProfileRepositoryProvider),
      participantsStream: repo.watchParticipants(widget.id),
      participantIdsStream: participantIdsStream,
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
              await BaseDetailPage.showReportDialog(
                context,
                item: poll,
                contentType: 'poll',
              );
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
      contentBuilder: (context, poll) => StreamBuilder<Set<String>>(
        stream: participantIdsStream,
        builder: (context, snapshot) {
          final hasSubmitted =
              currentUid != null &&
              !snapshot.hasError &&
              snapshot.connectionState != ConnectionState.waiting &&
              (snapshot.data?.contains(currentUid) ?? false);
          final total = poll.totalVotes;
          return RadioGroup<String>(
            groupValue: _selectedOptionId,
            onChanged: (v) => setState(() => _selectedOptionId = v),
            child: ListView(
              children: [
                if (poll.questionTitle.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      poll.questionTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ...poll.options.map((o) {
                  final count = poll.votes[o.id] ?? 0;
                  final pct = total == 0 ? 0 : (count / total * 100).round();
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(o.label)),
                        if (hasSubmitted) Text('$count • $pct%'),
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
      ),
      bottomAction: SignActionButton(
        submissionId: 'poll:${widget.id}',
        label: context.l10n.vote,
        participantIdsStream: participantIdsStream,
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
    if (_isDeleting) return;
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

    if (!context.mounted || _isDeleting) return;
    setState(() => _isDeleting = true);
    try {
      await PollRepository.create().delete(poll.id);
      QuotaUpdateNotifier.instance.notify();
      if (context.mounted) {
        showSuccessSnackBar(context.l10n.pollDeleted);
        Navigator.of(context).pop();
      }
    } on StateError catch (error) {
      if (context.mounted) {
        showErrorSnackBar(
          error.message == 'poll_has_votes'
              ? context.l10n.cannotDeletePollHasVotes
              : context.l10n.pollDeletionFailed,
        );
      }
    } catch (_) {
      if (context.mounted) showErrorSnackBar(context.l10n.pollDeletionFailed);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
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
