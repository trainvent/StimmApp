import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/group_access_qr_scanner_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/group_entry_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view group invitations.')),
      );
    }

    final repo = PollGroupRepository.create();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Scan QR code',
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
            return const Center(child: Text('No group notifications yet.'));
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = notifications[index];
              final statusLabel = switch (item.status) {
                PollGroupAccessNotificationStatus.pending => 'Pending',
                PollGroupAccessNotificationStatus.accepted => 'Accepted',
                PollGroupAccessNotificationStatus.denied => 'Denied',
              };
              final actionLabel = switch (item.type) {
                PollGroupAccessNotificationType.invite => 'invited you',
                PollGroupAccessNotificationType.request => 'requested access',
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
