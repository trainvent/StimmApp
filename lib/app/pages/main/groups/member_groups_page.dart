import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/pages/main/groups/group_access_qr_scanner_page.dart';
import 'package:stimmapp/app/pages/main/groups/group_dashboard_page.dart';
import 'package:stimmapp/app/pages/main/groups/group_editor_page.dart';
import 'package:stimmapp/app/pages/main/groups/group_ui.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/widgets/slidable_widget.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/core/providers/subscription_provider.dart';
import 'package:stimmapp/core/services/purchases_service.dart';

bool groupCreationRequiresPro({
  required int createdCount,
  required UserProfile? profile,
  required String? authenticatedEmail,
}) {
  final hasProAccess =
      profile?.isPro == true ||
      UserProfile.shouldForcePro(profile?.email) ||
      UserProfile.shouldForcePro(authenticatedEmail);
  return createdCount >= 1 && !hasProAccess;
}

class MemberGroupsPage extends StatelessWidget {
  const MemberGroupsPage({super.key});

  Future<void> _showAdditionalGroupsProDialog(BuildContext context) async {
    final openPaywall = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.paywallTitle),
        content: Text(context.l10n.additionalGroupsRequirePro),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.signUpForPro),
          ),
        ],
      ),
    );
    if (openPaywall != true || !context.mounted) {
      return;
    }

    final opened = await PurchasesService.instance.presentPaywall(
      context: context,
      source: 'member_groups_pro_dialog',
    );
    if (!opened && context.mounted) {
      showErrorSnackBar(context.l10n.couldNotOpenPaywall);
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
      final result = await PollGroupRepository.create().leaveGroup(
        group: group,
        uid: uid,
      );
      if (!context.mounted) {
        return;
      }
      showSuccessSnackBar(
        result == PollGroupLeaveResult.groupDeleted
            ? context.l10n.groupDeleted
            : context.l10n.youLeftTheGroup,
      );
    } on StateError catch (error) {
      if (!context.mounted) {
        return;
      }
      showErrorSnackBar(error.message);
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    }
  }

  Future<void> _openDashboard(BuildContext context, PollGroup group) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => GroupDashboardPage(group: group)),
    );
  }

  Future<void> _openCreateGroup(BuildContext context) async {
    final authenticatedUser = authService.currentUser;
    if (authenticatedUser == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }
    final uid = authenticatedUser.uid;

    await PurchasesService.instance.refreshCustomerInfo();
    await syncSubscriptionStatus(
      uid,
      PurchasesService.instance.currentStatus,
      authenticatedEmail: authenticatedUser.email,
    );

    final user = await UserRepository.create().getById(uid);
    final createdCount = await PollGroupRepository.create()
        .countGroupsCreatedByUser(uid);
    final requiresPro = groupCreationRequiresPro(
      createdCount: createdCount,
      profile: user,
      authenticatedEmail: authenticatedUser.email,
    );
    if (kDebugMode) {
      debugPrint(
        'MemberGroupsPage._openCreateGroup: uid=$uid '
        'createdCount=$createdCount profileIsPro=${user?.isPro} '
        'profileForcedPro=${UserProfile.shouldForcePro(user?.email)} '
        'authForcedPro=${UserProfile.shouldForcePro(authenticatedUser.email)} '
        'requiresPro=$requiresPro',
      );
    }
    if (!context.mounted) {
      return;
    }
    if (requiresPro) {
      if (kDebugMode) {
        debugPrint(
          'MemberGroupsPage._openCreateGroup: showing Pro explanation',
        );
      }
      await _showAdditionalGroupsProDialog(context);
      return;
    }

    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push<PollGroup>(
      MaterialPageRoute(builder: (context) => const GroupEditorPage()),
    );
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
          _GroupCreateAction(
            onCreate: () => _openCreateGroup(context),
            onLocked: () => _showAdditionalGroupsProDialog(context),
          ),
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
            return const Center(
              child: TriangleLoadingIndicator(showFill: false),
            );
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

              return StreamBuilder<PollGroupMember?>(
                stream: repository.watchMember(group.id, uid),
                builder: (context, memberSnapshot) {
                  final member = memberSnapshot.data;
                  final isAdmin = member?.role == PollGroupRole.admin;
                  final inviteLink = buildPollGroupInviteLink(group);
                  final roleLabel = isCreator
                      ? context.l10n.creatorRoleLabel
                      : (isAdmin
                            ? context.l10n.adminRoleLabel
                            : context.l10n.memberRoleLabel);
                  final expiresAt = group.expiresAt;
                  final expiresLabel = expiresAt == null
                      ? context.l10n.noExpiry
                      : context.l10n.expiresOnDate(
                          formatPollGroupDate(expiresAt),
                        );

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: AppSlidable(
                      key: ValueKey('member_group_${group.id}'),
                      startAction: AppSlidableAction(
                        icon: Icons.dashboard_outlined,
                        label: context.l10n.openGroupDashboard,
                      ),
                      onStartSwipe: () => _openDashboard(context, group),
                      endAction: AppSlidableAction(
                        icon: Icons.logout,
                        label: context.l10n.leaveGroup,
                        style: AppSlidableActionStyle.secondary,
                      ),
                      onEndSwipe: () => _leaveGroup(context, group),
                      child: PollGroupSummaryCard(
                        group: group,
                        embedded: true,
                        onTap: () => showPollGroupInviteQrCode(context, group),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(label: Text(roleLabel)),
                            if (inviteLink != null) ...[
                              IconButton(
                                tooltip: context.l10n.copyInviteLinkTooltip,
                                onPressed: () =>
                                    copyPollGroupInviteLink(context, group),
                                icon: const Icon(Icons.copy_outlined),
                              ),
                              IconButton(
                                tooltip: context.l10n.displayQrCode,
                                onPressed: () =>
                                    showPollGroupInviteQrCode(context, group),
                                icon: const Icon(Icons.qr_code_2),
                              ),
                            ],
                          ],
                        ),
                        summary: context.l10n.groupAccessSummary(
                          group.accessMode.localizedTitle(context),
                          group.memberIds.length,
                          expiresLabel,
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

class _GroupCreateAction extends ConsumerWidget {
  const _GroupCreateAction({required this.onCreate, required this.onLocked});

  final VoidCallback onCreate;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileState = ref.watch(userProfileProvider);
    if (user == null) {
      return IconButton(
        key: const Key('group_create_action'),
        tooltip: context.l10n.createGroupTooltip,
        onPressed: null,
        icon: const Icon(Icons.add),
      );
    }

    return StreamBuilder<List<PollGroup>>(
      stream: PollGroupRepository.create().watchGroupsForUser(user.uid),
      builder: (context, snapshot) {
        if (!profileState.hasValue || !snapshot.hasData) {
          return const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: TriangleLoadingIndicator(
                  size: 18,
                  strokeWidth: 2,
                  showFill: false,
                ),
              ),
            ),
          );
        }

        final createdCount = snapshot.data!
            .where((group) => group.createdBy == user.uid)
            .length;
        final requiresPro = groupCreationRequiresPro(
          createdCount: createdCount,
          profile: profileState.value,
          authenticatedEmail: user.email,
        );
        return IconButton(
          key: const Key('group_create_action'),
          tooltip: requiresPro
              ? context.l10n.additionalGroupsRequirePro
              : context.l10n.createGroupTooltip,
          onPressed: requiresPro ? onLocked : onCreate,
          icon: ImageFiltered(
            key: requiresPro ? const Key('group_create_action_blurred') : null,
            imageFilter: ImageFilter.blur(
              sigmaX: requiresPro ? 1.4 : 0,
              sigmaY: requiresPro ? 1.4 : 0,
            ),
            child: Icon(
              Icons.add,
              color: requiresPro
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
        );
      },
    );
  }
}
