import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

class MemberGroupsPage extends StatelessWidget {
  const MemberGroupsPage({super.key});

  String _accessModeTitle(PollGroupAccessMode mode) {
    switch (mode) {
      case PollGroupAccessMode.private:
        return 'Completely private';
      case PollGroupAccessMode.protected:
        return 'Protected';
      case PollGroupAccessMode.open:
        return 'Open';
    }
  }

  Future<void> _leaveGroup(BuildContext context, PollGroup group) async {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      showErrorSnackBar('Please sign in first.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave group'),
        content: Text('Do you want to leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await PollGroupRepository.create().leaveGroup(group: group, uid: uid);
      showSuccessSnackBar('You left the group.');
    } on StateError catch (error) {
      if (error.message == 'group_creator_cannot_leave') {
        showErrorSnackBar(
          'Group creators cannot leave their own group. Edit or delete it instead.',
        );
        return;
      }
      showErrorSnackBar(error.message);
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = authService.currentUser?.uid;
    final repository = PollGroupRepository.create();
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your groups.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My groups')),
      body: StreamBuilder<List<PollGroup>>(
        stream: repository.watchAccessibleGroupsForUser(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('MemberGroupsPage stream error: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Group debug error:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final groups = snapshot.data ?? const <PollGroup>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (groups.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'You are not a member of any groups yet.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _DebugMembershipPanel(uid: uid, repository: repository),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _DebugMembershipPanel(uid: uid, repository: repository),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isCreator = group.createdBy == uid;
                    final expiresAt = group.expiresAt;
                    final expiresLabel = expiresAt == null
                        ? 'No expiry'
                        : 'Expires ${DateFormat('yyyy-MM-dd').format(expiresAt)}';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.groups_2_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Chip(
                                  label: Text(isCreator ? 'Creator' : 'Member'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Access: ${_accessModeTitle(group.accessMode)}'
                              ' • Members: ${group.memberIds.length}'
                              ' • $expiresLabel',
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: isCreator
                                  ? const Text(
                                      'You created this group and cannot leave it here.',
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () => _leaveGroup(context, group),
                                      icon: const Icon(Icons.logout),
                                      label: const Text('Leave group'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DebugMembershipPanel extends StatelessWidget {
  const _DebugMembershipPanel({
    required this.uid,
    required this.repository,
  });

  final String uid;
  final PollGroupRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PollGroup>>(
      stream: repository.watchGroupsForUser(uid),
      builder: (context, groupSnapshot) {
        final memberGroups = groupSnapshot.data ?? const <PollGroup>[];
        return StreamBuilder<List<PollGroupAccessNotification>>(
          stream: repository.watchNotifications(uid),
          builder: (context, notificationSnapshot) {
            final notifications =
                notificationSnapshot.data ??
                const <PollGroupAccessNotification>[];
            final acceptedInviteGroupIds = notifications
                .where(
                  (item) =>
                      item.type == PollGroupAccessNotificationType.invite &&
                      item.status == PollGroupAccessNotificationStatus.accepted,
                )
                .map((item) => item.groupId)
                .toList();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Debug info'),
                    Text('uid: $uid'),
                    Text('memberGroups: ${memberGroups.length}'),
                    Text(
                      'memberGroupIds: ${memberGroups.map((group) => group.id).join(', ')}',
                    ),
                    Text('acceptedInvites: ${acceptedInviteGroupIds.length}'),
                    Text(
                      'acceptedInviteGroupIds: ${acceptedInviteGroupIds.join(', ')}',
                    ),
                    if (groupSnapshot.hasError)
                      Text('groupQueryError: ${groupSnapshot.error}'),
                    if (notificationSnapshot.hasError)
                      Text('notificationError: ${notificationSnapshot.error}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
