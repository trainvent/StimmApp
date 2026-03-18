import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/group_access_qr_scanner_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/group_entry_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.pleaseSignInToViewGroupInvitations)),
      );
    }

    final repo = PollGroupRepository.create();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.scanQrCodeTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const GroupAccessQrScannerPage(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: StreamBuilder<List<PollGroupAccessNotification>>(
        stream: repo.watchNotifications(uid),
        builder: (context, snapshot) {
          final notifications =
              snapshot.data ?? const <PollGroupAccessNotification>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notifications.isEmpty) {
            return Center(child: Text(context.l10n.noGroupNotificationsYet));
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = notifications[index];
              final statusLabel = switch (item.status) {
                PollGroupAccessNotificationStatus.pending => context.l10n.notificationStatusPending,
                PollGroupAccessNotificationStatus.accepted => context.l10n.notificationStatusAccepted,
                PollGroupAccessNotificationStatus.denied => context.l10n.notificationStatusDenied,
              };
              final actionLabel = switch (item.type) {
                PollGroupAccessNotificationType.invite => context.l10n.notificationActionInvitedYou,
                PollGroupAccessNotificationType.request => context.l10n.notificationActionRequestedAccess,
              };
              return ListTile(
                leading: Icon(
                  item.type == PollGroupAccessNotificationType.invite
                      ? Icons.group_add
                      : Icons.mark_email_unread_outlined,
                ),
                title: Text(item.groupName),
                subtitle: Text(
                  '${item.actorDisplayName} $actionLabel • $statusLabel',
                ),
                trailing:
                    item.status == PollGroupAccessNotificationStatus.pending
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: () {
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
