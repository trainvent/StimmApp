import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/layout/init_app_layout.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_ui.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/pages/onboarding/login_page.dart';
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
    this.notificationId,
    this.notificationOwnerUid,
  });

  final String groupId;
  final String? notificationId;
  final String? notificationOwnerUid;

  @override
  State<GroupEntryPage> createState() => _GroupEntryPageState();
}

class _GroupEntryPageState extends State<GroupEntryPage> {
  final _repo = PollGroupRepository.create();
  bool _isSaving = false;
  String? _autoJoinAttemptedForUid;

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
    final fallbackDisplayName = context.l10n.aUser;
    setState(() => _isSaving = true);
    try {
      final profile = await UserRepository.create().getById(uid);
      await _repo.requestAccess(
        requesterUid: uid,
        requesterDisplayName:
            profile?.displayName ?? profile?.email ?? fallbackDisplayName,
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

  Future<void> _openLogin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _openAppHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const InitAppLayout()),
      (_) => false,
    );
  }

  void _maybeAutoJoinOpenGroup(PollGroup? group, UserProfile? currentProfile) {
    final currentUid = currentProfile?.uid;
    if (group == null ||
        currentUid == null ||
        group.accessMode != PollGroupAccessMode.open ||
        group.memberIds.contains(currentUid) ||
        _isSaving ||
        _autoJoinAttemptedForUid == currentUid) {
      return;
    }

    _autoJoinAttemptedForUid = currentUid;
    Future.microtask(() => _joinOpenGroup(group));
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
      return currentUid == null
          ? FilledButton(
              onPressed: _isSaving ? null : _openLogin,
              child: Text(context.l10n.signIn),
            )
          : Text(context.l10n.privateGroupWaitForInvite);
    }
    if (currentUid != null && group.memberIds.contains(currentUid)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.alreadyMemberOfGroup),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _openAppHome,
            child: Text(context.l10n.openApp),
          ),
        ],
      );
    }
    if (currentUid == null) {
      final label = group.accessMode == PollGroupAccessMode.open
          ? context.l10n.signInToJoinGroup
          : context.l10n.signInToRequestGroupAccess;
      return FilledButton(
        onPressed: _isSaving ? null : _openLogin,
        child: Text(label),
      );
    }
    if (group.accessMode == PollGroupAccessMode.private) {
      return Text(context.l10n.privateGroupWaitForInvite);
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
    return StreamBuilder<Object?>(
      stream: authService.firebaseAuth.authStateChanges(),
      builder: (context, _) {
        final currentUid = authService.currentUser?.uid;
        return FutureBuilder<(PollGroup?, PollGroupAccessNotification?, UserProfile?)>(
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

            _maybeAutoJoinOpenGroup(group, currentProfile);

            final isAnonymousPrivateView =
                group == null && notification == null && currentUid == null;
            final title = isAnonymousPrivateView
                ? context.l10n.groupAccessTitle
                : (group?.name ??
                      notification?.groupName ??
                      context.l10n.groupAccessTitle);

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
                      context.l10n.accessModeLabel(
                        group.accessMode.localizedTitle(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (group.accessMode == PollGroupAccessMode.protected)
                      Text(group.accessMode.localizedDescription(context)),
                    if (group.accessMode == PollGroupAccessMode.open)
                      Text(
                        currentUid == null
                            ? context.l10n.signInToJoinGroupAutomatically
                            : context.l10n.openGroupsCanBeJoinedImmediately,
                      ),
                  ] else if (notification != null) ...[
                    const SizedBox(height: 8),
                    Text(context.l10n.groupDetailsTemporarilyUnavailableRespond),
                  ] else if (currentUid == null) ...[
                    const SizedBox(height: 8),
                    Text(context.l10n.privateGroupOrSignInRequired),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(context.l10n.privateGroupWaitForInvite),
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
      },
    );
  }
}
