import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/repositories/petition_comment_repository.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';

final petitionCommentRepositoryProvider = Provider(
  (ref) => PetitionCommentRepository(locator.databaseService),
);
final commentBlockedUserIdsProvider = StreamProvider.autoDispose<Set<String>>((
  ref,
) {
  final uid = ref.watch(currentUserProvider)?.uid;
  return uid == null
      ? Stream.value(<String>{})
      : ModerationRepository.create().watchBlockedUserIds(uid);
});
final petitionCommentsProvider = StreamProvider.autoDispose
    .family<List<PetitionComment>, String>((ref, id) {
      final repository = ref.watch(petitionCommentRepositoryProvider);
      return ref
          .watch(commentBlockedUserIdsProvider)
          .when(
            loading: () => const Stream<List<PetitionComment>>.empty(),
            error: (error, stack) =>
                Stream<List<PetitionComment>>.error(error, stack),
            data: (blocked) => repository
                .watchComments(id)
                .map(
                  (comments) => comments
                      .where((comment) => !blocked.contains(comment.signerId))
                      .toList(),
                ),
          );
    });
final petitionCommentLikesProvider = StreamProvider.autoDispose
    .family<Set<String>, ({String petitionId, String signerId})>(
      (ref, key) => ref
          .watch(petitionCommentRepositoryProvider)
          .watchLikes(key.petitionId, key.signerId),
    );
