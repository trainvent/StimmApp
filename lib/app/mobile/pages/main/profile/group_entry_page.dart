import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GroupEntryPage extends StatefulWidget {
  const GroupEntryPage({
    super.key,
    required this.groupId,
    this.inviteToken,
    this.notificationId,
    this.notificationOwnerUid,
  });

  final String groupId;
  final String? inviteToken;
  final String? notificationId;
  final String? notificationOwnerUid;

  @override
  State<GroupEntryPage> createState() => _GroupEntryPageState();
}

class _GroupEntryPageState extends State<GroupEntryPage> {
  final _repo = PollGroupRepository.create();
  bool _isSaving = false;

  Future<PollGroup?> _loadGroup() async {
    try {
      return await _repo.getGroup(widget.groupId);
    } catch (error, stackTrace) {
      debugPrint(
        'GroupEntryPage: failed to load group ${widget.groupId}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<PollGroupAccessNotification?> _loadNotification() async {
    final ownerUid = widget.notificationOwnerUid;
    final notificationId = widget.notificationId;
    if (ownerUid == null || notificationId == null) {
      return null;
    }
    try {
      return await _repo.getNotification(ownerUid, notificationId);
    } catch (error, stackTrace) {
      debugPrint(
        'GroupEntryPage: failed to load notification $notificationId for $ownerUid: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> _respondToNotification(bool accept) async {
    final uid = authService.currentUser?.uid;
    final notificationOwnerUid = widget.notificationOwnerUid;
    final notificationId = widget.notificationId;
    if (uid == null || notificationOwnerUid != uid || notificationId == null) {
      showErrorSnackBar(context.l10n.actionNoLongerAvailable);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _repo.respondToNotification(
        currentUid: uid,
        notificationId: notificationId,
        accept: accept,
      );
      if (!mounted) {
        return;
      }
      showSuccessSnackBar(
        accept ? context.l10n.groupAccessAccepted : context.l10n.inviteDenied,
      );
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _requestAccess(PollGroup group) async {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final profile = await UserRepository.create().getById(uid);
      await _repo.requestAccess(
        requesterUid: uid,
        requesterDisplayName:
            profile?.displayName ?? profile?.email ?? context.l10n.aUser,
        group: group,
        requestedRole: PollGroupRole.user,
      );
      if (!mounted) {
        return;
      }
      showSuccessSnackBar(context.l10n.accessRequestSent);
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _joinOpenGroup(PollGroup group) async {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _repo.joinOpenGroup(group: group, uid: uid, joinedBy: uid);
      if (!mounted) {
        return;
      }
      showSuccessSnackBar(context.l10n.youJoinedTheGroup);
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _hasValidProtectedToken(PollGroup group) {
    if (group.accessMode != PollGroupAccessMode.protected) {
      return true;
    }
    return widget.inviteToken != null &&
        widget.inviteToken == group.inviteLinkToken;
  }

  Widget _buildPrimaryActions({
    required PollGroup? group,
    required PollGroupAccessNotification? notification,
    required UserProfile? currentProfile,
  }) {
    final currentUid = currentProfile?.uid;

    if (notification != null &&
        notification.status == PollGroupAccessNotificationStatus.pending &&
        currentUid == notification.recipientUid) {
      final acceptLabel =
          notification.type == PollGroupAccessNotificationType.request
          ? context.l10n.approveRequest
          : context.l10n.acceptInvite;
      final denyLabel =
          notification.type == PollGroupAccessNotificationType.request
          ? context.l10n.denyRequest
          : context.l10n.denyInvite;
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => _respondToNotification(false),
              child: Text(denyLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isSaving ? null : () => _respondToNotification(true),
              child: Text(acceptLabel),
            ),
          ),
        ],
      );
    }

    if (group == null) {
      return const SizedBox.shrink();
    }
    if (currentUid != null && group.memberIds.contains(currentUid)) {
      return Text(context.l10n.alreadyMemberOfGroup);
    }
    if (group.accessMode == PollGroupAccessMode.private) {
      return Text(context.l10n.privateGroupWaitForInvite);
    }
    if (group.accessMode == PollGroupAccessMode.protected &&
        !_hasValidProtectedToken(group)) {
      return Text(context.l10n.invalidProtectedInviteLink);
    }
    if (group.accessMode == PollGroupAccessMode.protected) {
      return FilledButton(
        onPressed: _isSaving ? null : () => _requestAccess(group),
        child: Text(context.l10n.requestAccess),
      );
    }
    return FilledButton(
      onPressed: _isSaving ? null : () => _joinOpenGroup(group),
      child: Text(context.l10n.joinGroup),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = authService.currentUser?.uid;
    return FutureBuilder<
      (PollGroup?, PollGroupAccessNotification?, UserProfile?)
    >(
      future: () async {
        final group = await _loadGroup();
        final notification = await _loadNotification();
        final profile = currentUid == null
            ? null
            : await UserRepository.create().getById(currentUid);
        return (group, notification, profile);
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final group = snapshot.data!.$1;
        final notification = snapshot.data!.$2;
        final currentProfile = snapshot.data!.$3;
        final title =
            group?.name ?? notification?.groupName ?? context.l10n.groupAccessTitle;

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              if (notification != null)
                Text(
                  notification.type == PollGroupAccessNotificationType.invite
                      ? context.l10n.invitedYouToThisGroup(
                          notification.actorDisplayName,
                        )
                      : context.l10n.requestedAccessToThisGroup(
                          notification.actorDisplayName,
                        ),
                ),
              if (group != null) ...[
                if (notification != null) const SizedBox(height: 12),
                Text(
                  context.l10n.accessModeLabel(switch (group.accessMode) {
                    PollGroupAccessMode.private =>
                      context.l10n.completelyPrivateAccessMode,
                    PollGroupAccessMode.protected =>
                      context.l10n.protectedAccessMode,
                    PollGroupAccessMode.open => context.l10n.openAccessMode,
                  }),
                ),
                const SizedBox(height: 8),
                if (group.accessMode == PollGroupAccessMode.protected)
                  Text(context.l10n.protectedGroupsRequireInviteLink),
                if (group.accessMode == PollGroupAccessMode.open)
                  Text(context.l10n.openGroupsCanBeJoinedImmediately),
              ] else if (notification != null) ...[
                const SizedBox(height: 8),
                Text(context.l10n.groupDetailsTemporarilyUnavailableRespond),
              ] else ...[
                const SizedBox(height: 8),
                Text(context.l10n.groupDetailsTemporarilyUnavailable),
              ],
              const SizedBox(height: 24),
              _buildPrimaryActions(
                group: group,
                notification: notification,
                currentProfile: currentProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
