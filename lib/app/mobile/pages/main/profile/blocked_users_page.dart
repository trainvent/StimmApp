import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    final moderationRepository = ModerationRepository.create();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.blockedUsers),
      ),
      body: StreamBuilder<List<BlockedUserProfile>>(
        stream: moderationRepository.watchBlockedUsers(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${context.l10n.blockedUsersLoadError}: ${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: TriangleLoadingIndicator());
          }

          final blockedUsers = snapshot.data!;
          if (blockedUsers.isEmpty) {
            return Center(
              child: Text(context.l10n.blockedUsersEmpty),
            );
          }

          return ListView.separated(
            itemCount: blockedUsers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final blockedUser = blockedUsers[index];
              final profile = blockedUser.profile;
              final title = profile?.displayName?.trim().isNotEmpty == true
                  ? profile!.displayName!
                  : context.l10n.unknownUser;
              final subtitle = profile?.email?.trim().isNotEmpty == true
                  ? profile!.email!
                  : blockedUser.userId;

              return ListTile(
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: TextButton(
                  key: Key('unblock_${blockedUser.userId}'),
                  onPressed: () async {
                    final successMessage =
                        context.l10n.unblockedUserSuccessfully;
                    await moderationRepository.unblockUser(
                      blockerId: userId,
                      blockedUserId: blockedUser.userId,
                    );
                    showSuccessSnackBar(successMessage);
                  },
                  child: Text(context.l10n.unblock),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
