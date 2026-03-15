import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/group_editor_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/group_access_qr_scanner_page.dart';
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

  Future<void> _openEditor(BuildContext context, PollGroup group) async {
    await Navigator.of(context).push<PollGroup>(
      MaterialPageRoute(
        builder: (context) => GroupEditorPage(initialGroup: group),
      ),
    );
  }

  Future<void> _deleteGroup(BuildContext context, PollGroup group) async {
    final controller = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type "${group.name}" to confirm deletion. This cannot be undone.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(controller.text.trim() == group.name.trim());
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        showErrorSnackBar('Group name did not match.');
        return;
      }

      await PollGroupRepository.create().deleteGroup(group.id);
      showSuccessSnackBar('Group deleted.');
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      controller.dispose();
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
      appBar: AppBar(
        title: const Text('My groups'),
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
      body: StreamBuilder<List<PollGroup>>(
        stream: repository.watchAccessibleGroupsForUser(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load your groups.\n${snapshot.error}',
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
                ],
              ),
            );
          }

          return ListView.separated(
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

              return StreamBuilder<PollGroupMember?>(
                stream: repository.watchMember(group.id, uid),
                builder: (context, memberSnapshot) {
                  final member = memberSnapshot.data;
                  final isAdmin = member?.role == PollGroupRole.admin;
                  final canManage = isCreator || isAdmin;
                  final roleLabel = isCreator
                      ? 'Creator'
                      : (isAdmin ? 'Admin' : 'Member');

                  return Slidable(
                    key: ValueKey('member_group_${group.id}'),
                    endActionPane: ActionPane(
                      motion: const StretchMotion(),
                      children: canManage
                          ? [
                              SlidableAction(
                                onPressed: (_) => _deleteGroup(context, group),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                icon: Icons.delete_outline,
                                label: 'Delete',
                              ),
                            ]
                          : [
                              SlidableAction(
                                onPressed: (_) => _leaveGroup(context, group),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                                icon: Icons.logout,
                                label: 'Leave',
                              ),
                            ],
                    ),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: canManage
                            ? () => _openEditor(context, group)
                            : null,
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  Chip(label: Text(roleLabel)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Access: ${_accessModeTitle(group.accessMode)}'
                                ' • Members: ${group.memberIds.length}'
                                ' • $expiresLabel',
                              ),
                              const SizedBox(height: 10),
                              Text(
                                canManage
                                    ? 'Swipe for delete.'
                                    : 'Swipe to leave the group.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
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
