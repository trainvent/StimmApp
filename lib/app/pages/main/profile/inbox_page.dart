import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/groups/group_entry_page.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/models/questionnaire_group.dart';
import 'package:stimmapp/core/data/repositories/questionnaire_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(context.l10n.pleaseSignInToViewGroupInvitations),
        ),
      );
    }

    final repo = QuestionnaireGroupRepository.create();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notificationsTitle), actions: []),
      body: StreamBuilder<List<QuestionnaireGroupAccessNotification>>(
        stream: repo.watchNotifications(uid),
        builder: (context, snapshot) {
          final notifications =
              snapshot.data ?? const <QuestionnaireGroupAccessNotification>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              notifications.isEmpty) {
            return const Center(
              child: TriangleLoadingIndicator(showFill: false),
            );
          }
          if (notifications.isEmpty) {
            return Center(child: Text(context.l10n.noGroupNotificationsYet));
          }
          final unreadRemovalIds = notifications
              .where(
                (item) =>
                    item.type ==
                        QuestionnaireGroupAccessNotificationType.removed &&
                    item.readAt == null,
              )
              .map((item) => item.id)
              .toList();
          if (unreadRemovalIds.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await repo.markNotificationsRead(uid, unreadRemovalIds);
            });
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = notifications[index];
              final statusLabel = switch (item.status) {
                QuestionnaireGroupAccessNotificationStatus.pending =>
                  context.l10n.notificationStatusPending,
                QuestionnaireGroupAccessNotificationStatus.accepted =>
                  context.l10n.notificationStatusAccepted,
                QuestionnaireGroupAccessNotificationStatus.denied =>
                  context.l10n.notificationStatusDenied,
              };
              final actionLabel = switch (item.type) {
                QuestionnaireGroupAccessNotificationType.invite =>
                  context.l10n.notificationActionInvitedYou,
                QuestionnaireGroupAccessNotificationType.request =>
                  context.l10n.notificationActionRequestedAccess,
                QuestionnaireGroupAccessNotificationType.removed =>
                  context.l10n.notificationActionRemovedYou,
              };
              final isRemoval =
                  item.type == QuestionnaireGroupAccessNotificationType.removed;
              return ListTile(
                leading: Icon(switch (item.type) {
                  QuestionnaireGroupAccessNotificationType.invite =>
                    Icons.group_add,
                  QuestionnaireGroupAccessNotificationType.request =>
                    Icons.mark_email_unread_outlined,
                  QuestionnaireGroupAccessNotificationType.removed =>
                    Icons.person_remove_outlined,
                }),
                title: Text(item.groupName),
                subtitle: Text(
                  isRemoval
                      ? '${item.actorDisplayName} $actionLabel'
                      : '${item.actorDisplayName} $actionLabel • $statusLabel',
                ),
                trailing:
                    !isRemoval &&
                        item.status ==
                            QuestionnaireGroupAccessNotificationStatus.pending
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: isRemoval
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GroupEntryPage(
                              groupId: item.groupId,
                              notificationId: item.id,
                              notificationOwnerUid: uid,
                            ),
                          ),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}
