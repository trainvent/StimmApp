import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/repositories/petition_comment_repository.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/core/providers/petition_comments_provider.dart';

class PetitionComments extends ConsumerWidget {
  const PetitionComments({super.key, required this.petitionId});
  final String petitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Divider(height: 32, color: Theme.of(context).colorScheme.outlineVariant),
      Text(
        context.l10n.petitionComments,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      ref
          .watch(petitionCommentsProvider(petitionId))
          .when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: TriangleLoadingIndicator(),
                ),
              ),
            ),
            error: (_, _) => TextButton(
              onPressed: () {
                ref.invalidate(commentBlockedUserIdsProvider);
                ref.invalidate(petitionCommentsProvider(petitionId));
              },
              child: Text(context.l10n.petitionCommentsError),
            ),
            data: (comments) => comments.isEmpty
                ? Text(context.l10n.petitionCommentsEmpty)
                : Column(
                    children: [
                      for (final comment in comments)
                        _CommentCard(
                          key: ValueKey(comment.signerId),
                          petitionId: petitionId,
                          comment: comment,
                        ),
                    ],
                  ),
          ),
    ],
  );
}

class _CommentCard extends ConsumerStatefulWidget {
  const _CommentCard({
    super.key,
    required this.petitionId,
    required this.comment,
  });
  final String petitionId;
  final PetitionComment comment;
  @override
  ConsumerState<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends ConsumerState<_CommentCard> {
  bool _saving = false;

  Future<void> _setLiked(String uid, bool liked) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(petitionCommentRepositoryProvider)
          .setLiked(widget.petitionId, widget.comment.signerId, uid, liked);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.commentLikeError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final uid = ref.watch(currentUserProvider)?.uid;
    final key = (petitionId: widget.petitionId, signerId: comment.signerId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.displayName?.trim().isNotEmpty == true
                  ? comment.displayName!
                  : context.l10n.unknownUser,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (comment.signedAt != null)
              Text(
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(comment.signedAt!.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Text(comment.text),
            ref
                .watch(petitionCommentLikesProvider(key))
                .when(
                  loading: () => const SizedBox(
                    height: 40,
                    width: 48,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: TriangleLoadingIndicator(),
                      ),
                    ),
                  ),
                  error: (_, _) => TextButton(
                    onPressed: () =>
                        ref.invalidate(petitionCommentLikesProvider(key)),
                    child: Text(context.l10n.commentLikesError),
                  ),
                  data: (likes) {
                    final liked = uid != null && likes.contains(uid);
                    final label = uid == null
                        ? context.l10n.signInToLikeComment
                        : liked
                        ? context.l10n.unlikeComment
                        : context.l10n.likeComment;
                    return Tooltip(
                      message: label,
                      child: Semantics(
                        label: label,
                        toggled: liked,
                        child: TextButton.icon(
                          onPressed: uid == null || _saving
                              ? null
                              : () => _setLiked(uid, !liked),
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: Center(
                                    child: TriangleLoadingIndicator(),
                                  ),
                                )
                              : Icon(
                                  liked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 20,
                                ),
                          label: Text('${likes.length}'),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
