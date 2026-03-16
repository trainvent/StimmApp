import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/group_editor_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/group_access_qr_scanner_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class MemberGroupsPage extends StatelessWidget {
  const MemberGroupsPage({super.key});

  String _accessModeTitle(BuildContext context, PollGroupAccessMode mode) {
    switch (mode) {
      case PollGroupAccessMode.private:
        return context.l10n.completelyPrivateAccessMode;
      case PollGroupAccessMode.protected:
        return context.l10n.protectedAccessMode;
      case PollGroupAccessMode.open:
        return context.l10n.openAccessMode;
    }
  }

  Future<void> _leaveGroup(BuildContext context, PollGroup group) async {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }

    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.leaveGroup),
          content: Text(context.l10n.doYouWantToLeaveGroup(group.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.leaveGroup),
            ),
          ],
        ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await PollGroupRepository.create().leaveGroup(group: group, uid: uid);
      if (!context.mounted) {
        return;
      }
      showSuccessSnackBar(context.l10n.youLeftTheGroup);
    } on StateError catch (error) {
      if (!context.mounted) {
        return;
      }
      if (error.message == 'group_creator_cannot_leave') {
        showErrorSnackBar(context.l10n.groupCreatorsCannotLeaveOwnGroup);
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
          title: Text(context.l10n.deleteGroup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.typeGroupNameToConfirmDeletion(group.name)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: context.l10n.groupNameLabel,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(controller.text.trim() == group.name.trim());
              },
              child: Text(context.l10n.deleteGroup),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        if (!context.mounted) {
          return;
        }
        showErrorSnackBar(context.l10n.groupNameDidNotMatch);
        return;
      }

      await PollGroupRepository.create().deleteGroup(group.id);
      if (!context.mounted) {
        return;
      }
      showSuccessSnackBar(context.l10n.groupDeleted);
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
      return Scaffold(
        body: Center(child: Text(context.l10n.pleaseSignInToViewYourGroups)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myGroups),
        actions: [
          IconButton(
            tooltip: context.l10n.scanQrCode,
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
                  '${context.l10n.failedToLoadYourGroups}\n${snapshot.error}',
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
                  Text(
                    context.l10n.youAreNotMemberOfAnyGroupsYet,
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
                  ? context.l10n.noExpiry
                  : context.l10n.expiresOnDate(
                      DateFormat('yyyy-MM-dd').format(expiresAt),
                    );

              return StreamBuilder<PollGroupMember?>(
                stream: repository.watchMember(group.id, uid),
                builder: (context, memberSnapshot) {
                  final member = memberSnapshot.data;
                  final isAdmin = member?.role == PollGroupRole.admin;
                  final canManage = isCreator || isAdmin;
                  final roleLabel = isCreator
                      ? context.l10n.creatorRoleLabel
                      : (isAdmin
                            ? context.l10n.adminRoleLabel
                            : context.l10n.memberRoleLabel);

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
                                label: context.l10n.deleteGroup,
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
                                label: context.l10n.leaveGroup,
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
                                context.l10n.groupAccessSummary(
                                  _accessModeTitle(context, group.accessMode),
                                  group.memberIds.length,
                                  expiresLabel,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                canManage
                                    ? context.l10n.swipeForDelete
                                    : context.l10n.swipeToLeaveGroup,
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
