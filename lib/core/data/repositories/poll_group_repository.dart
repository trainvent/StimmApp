import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

class PollGroupRepository {
  PollGroupRepository(this._fs);

  final DatabaseService _fs;

  static PollGroupRepository create() =>
      PollGroupRepository(locator.databaseService);

  CollectionReference<PollGroup> _groups() => _fs.colRef<PollGroup>(
    DatabaseCollections.pollGroups,
    fromFirestore: PollGroup.fromFirestore,
    toFirestore: PollGroup.toFirestore,
  );

  CollectionReference<PollGroupMember> _members(String groupId) =>
      _fs.colRef<PollGroupMember>(
        '${DatabaseCollections.pollGroups}/$groupId/members',
        fromFirestore: PollGroupMember.fromFirestore,
        toFirestore: PollGroupMember.toFirestore,
      );

  CollectionReference<PollGroupAllowedMember> _allowedMembers(String groupId) =>
      _fs.colRef<PollGroupAllowedMember>(
        '${DatabaseCollections.pollGroups}/$groupId/allowedMembers',
        fromFirestore: PollGroupAllowedMember.fromFirestore,
        toFirestore: PollGroupAllowedMember.toFirestore,
      );

  CollectionReference<PollGroupAllowedDomain> _allowedDomains(String groupId) =>
      _fs.colRef<PollGroupAllowedDomain>(
        '${DatabaseCollections.pollGroups}/$groupId/allowedDomains',
        fromFirestore: PollGroupAllowedDomain.fromFirestore,
        toFirestore: PollGroupAllowedDomain.toFirestore,
      );

  CollectionReference<PollGroupAccessNotification> _notifications(
    String uid,
  ) => _fs.colRef<PollGroupAccessNotification>(
    '${DatabaseCollections.users}/$uid/${DatabaseCollections.groupAccessNotifications}',
    fromFirestore: PollGroupAccessNotification.fromFirestore,
    toFirestore: PollGroupAccessNotification.toFirestore,
  );

  Stream<List<PollGroup>> watchGroupsForUser(String uid) {
    return _fs
        .watchCol(
          _groups().where('memberIds', arrayContains: uid),
        )
        .map((groups) {
          final sortedGroups = groups.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sortedGroups;
        });
  }

  Stream<List<PollGroup>> watchAccessibleGroupsForUser(String uid) {
    final controller = StreamController<List<PollGroup>>.broadcast();
    List<PollGroup> memberGroups = const [];
    List<PollGroupAccessNotification> notifications = const [];

    Future<void> emitGroups() async {
      final groupsById = <String, PollGroup>{
        for (final group in memberGroups) group.id: group,
      };
      final acceptedInviteGroupIds = notifications
          .where(
            (notification) =>
                notification.type == PollGroupAccessNotificationType.invite &&
                notification.status == PollGroupAccessNotificationStatus.accepted,
          )
          .map((notification) => notification.groupId)
          .where((groupId) => groupId.isNotEmpty)
          .toSet();

      for (final groupId in acceptedInviteGroupIds) {
        if (groupsById.containsKey(groupId)) {
          continue;
        }
        try {
          final group = await getGroup(groupId);
          if (group != null) {
            groupsById[group.id] = group;
          }
        } on DatabaseException catch (error) {
          // Accepted notifications can outlive readable access, for example
          // after membership changes or stale local state. Skip those groups
          // instead of breaking the entire stream.
          if (error.code != 'permission-denied') {
            rethrow;
          }
        }
      }

      final groups = groupsById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) {
        controller.add(groups);
      }
    }

    final groupsSub = watchGroupsForUser(uid).listen(
      (groups) async {
        memberGroups = groups;
        await emitGroups();
      },
      onError: controller.addError,
    );
    final notificationsSub = watchNotifications(uid).listen(
      (items) async {
        notifications = items;
        await emitGroups();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await groupsSub.cancel();
      await notificationsSub.cancel();
    };

    return controller.stream;
  }

  Future<List<PollGroup>> getAccessibleGroupsForUser(String uid) async {
    final memberGroups = await _fs
        .watchCol(
          _groups().where('memberIds', arrayContains: uid),
        )
        .first;
    final notifications = await watchNotifications(uid).first;

    final groupsById = <String, PollGroup>{
      for (final group in memberGroups) group.id: group,
    };
    final acceptedInviteGroupIds = notifications
        .where(
          (notification) =>
              notification.type == PollGroupAccessNotificationType.invite &&
              notification.status == PollGroupAccessNotificationStatus.accepted,
        )
        .map((notification) => notification.groupId)
        .where((groupId) => groupId.isNotEmpty)
        .toSet();

    for (final groupId in acceptedInviteGroupIds) {
      if (groupsById.containsKey(groupId)) {
        continue;
      }
      try {
        final group = await getGroup(groupId);
        if (group != null) {
          groupsById[group.id] = group;
        }
      } on DatabaseException catch (error) {
        if (error.code != 'permission-denied') {
          rethrow;
        }
      }
    }

    final groups = groupsById.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return groups;
  }

  Future<String> createGroup({
    required String creatorUid,
    required String name,
    required String joinCode,
    required PollGroupNicknameMode nicknameMode,
    required bool managersCanInvite,
    required PollGroupAccessMode accessMode,
    required bool inviteLinkEnabled,
    DateTime? expiresAt,
    List<PollGroupAllowedMember> allowedMembers = const [],
    List<PollGroupAllowedDomain> allowedDomains = const [],
  }) async {
    final normalizedMembers = normalizeAllowedMembers(allowedMembers);
    final normalizedDomains = normalizeAllowedDomains(allowedDomains);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createPollGroup',
      );
      final result = await callable.call(<String, Object?>{
        'name': name,
        'joinCode': joinCode,
        'nicknameMode': pollGroupNicknameModeToFirestore(nicknameMode),
        'managersCanInvite': managersCanInvite,
        'accessMode': pollGroupAccessModeToFirestore(accessMode),
        'inviteLinkEnabled': inviteLinkEnabled,
        'expiresAtMillis': expiresAt?.millisecondsSinceEpoch,
        'allowedMembers': normalizedMembers
            .map(
              (member) => <String, Object?>{
                'email': member.email,
                'nickname': member.nickname,
                'role': pollGroupRoleToFirestore(member.role),
              },
            )
            .toList(),
        'allowedDomains': normalizedDomains
            .map(
              (domain) => <String, Object?>{
                'domain': domain.domain,
                'role': pollGroupRoleToFirestore(domain.role),
              },
            )
            .toList(),
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final groupId = data['groupId'] as String?;
      if (groupId == null || groupId.isEmpty) {
        throw StateError('Group creation returned no id.');
      }
      return groupId;
    } on FirebaseFunctionsException catch (e) {
      if (e.message == 'group_limit_requires_pro') {
        throw StateError('group_limit_requires_pro');
      }
      throw StateError(e.message ?? e.code);
    }
  }

  Future<int> countGroupsCreatedByUser(String uid) async {
    final groups = await watchGroupsForUser(uid).first;
    return groups.where((group) => group.createdBy == uid).take(2).length;
  }

  Future<List<PollGroupAllowedMember>> getAllowedMembers(String groupId) async {
    final snap = await _allowedMembers(groupId).get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  Future<List<PollGroupAllowedDomain>> getAllowedDomains(String groupId) async {
    final snap = await _allowedDomains(groupId).get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateGroup({
    required PollGroup group,
    List<PollGroupAllowedMember> allowedMembers = const [],
    List<PollGroupAllowedDomain> allowedDomains = const [],
  }) async {
    final normalizedMembers = normalizeAllowedMembers(allowedMembers);
    final normalizedDomains = normalizeAllowedDomains(allowedDomains);
    final existingMemberDocs = await _allowedMembers(group.id).get();
    final existingDomainDocs = await _allowedDomains(group.id).get();
    final batch = _fs.instance.batch();

    batch.set(_groups().doc(group.id), group, SetOptions(merge: true));

    final nextMemberIds = normalizedMembers.map((member) => member.email).toSet();
    for (final doc in existingMemberDocs.docs) {
      if (!nextMemberIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }
    for (final member in normalizedMembers) {
      batch.set(
        _allowedMembers(group.id).doc(member.email.toLowerCase()),
        member,
      );
    }

    final nextDomainIds = normalizedDomains.map((domain) => domain.domain).toSet();
    for (final doc in existingDomainDocs.docs) {
      if (!nextDomainIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }
    for (final domain in normalizedDomains) {
      batch.set(_allowedDomains(group.id).doc(domain.domain), domain);
    }

    await batch.commit();
  }

  Stream<List<PollGroupAccessNotification>> watchNotifications(String uid) {
    return _fs.watchCol(
      _notifications(uid).orderBy('createdAt', descending: true),
    );
  }

  Future<PollGroup?> getGroup(String groupId) async {
    return _fs.getDoc(_groups().doc(groupId));
  }

  Stream<PollGroupMember?> watchMember(String groupId, String uid) {
    return _fs.watchDoc(_members(groupId).doc(uid));
  }

  Future<void> deleteGroup(String groupId) async {
    final membersSnap = await _members(groupId).get();
    final allowedMembersSnap = await _allowedMembers(groupId).get();
    final allowedDomainsSnap = await _allowedDomains(groupId).get();
    final batch = _fs.instance.batch();

    for (final doc in membersSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in allowedMembersSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in allowedDomainsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_groups().doc(groupId));
    await batch.commit();
  }

  Future<PollGroupAccessNotification?> getNotification(
    String uid,
    String notificationId,
  ) async {
    return _fs.getDoc(_notifications(uid).doc(notificationId));
  }

  Future<void> respondToNotification({
    required String currentUid,
    required String notificationId,
    required bool accept,
  }) async {
    final notificationRef = _notifications(currentUid).doc(notificationId);
    final notification = await _fs.getDoc(notificationRef);
    if (notification == null) {
      throw StateError('Notification not found.');
    }
    if (notification.status != PollGroupAccessNotificationStatus.pending) {
      return;
    }

    final groupRef = _groups().doc(notification.groupId);
    final joiningUid =
        notification.type == PollGroupAccessNotificationType.invite
        ? currentUid
        : notification.actorUid;
    final now = DateTime.now();
    final batch = _fs.instance.batch();

    if (accept) {
      batch.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([joiningUid]),
      });
      batch.set(
        _members(notification.groupId).doc(joiningUid),
        PollGroupMember(
          uid: joiningUid,
          role: notification.role,
          joinedAt: now,
          joinedBy: currentUid,
        ),
      );
    }

    batch.set(
      notificationRef,
      notification.copyWith(
        status: accept
            ? PollGroupAccessNotificationStatus.accepted
            : PollGroupAccessNotificationStatus.denied,
        resolvedAt: now,
      ),
    );

    await batch.commit();
  }

  Future<void> requestAccess({
    required String requesterUid,
    required String requesterDisplayName,
    required PollGroup group,
    required PollGroupRole requestedRole,
  }) async {
    final now = DateTime.now();
    final notificationRef = _notifications(group.createdBy).doc();
    await notificationRef.set(
      PollGroupAccessNotification(
        id: notificationRef.id,
        groupId: group.id,
        groupName: group.name,
        actorUid: requesterUid,
        actorDisplayName: requesterDisplayName,
        recipientUid: group.createdBy,
        role: requestedRole,
        accessMode: group.accessMode,
        type: PollGroupAccessNotificationType.request,
        status: PollGroupAccessNotificationStatus.pending,
        createdAt: now,
      ),
    );
  }

  Future<void> joinOpenGroup({
    required PollGroup group,
    required String uid,
    required String joinedBy,
  }) async {
    final batch = _fs.instance.batch();
    batch.update(_groups().doc(group.id), {
      'memberIds': FieldValue.arrayUnion([uid]),
    });
    batch.set(
      _members(group.id).doc(uid),
      PollGroupMember(
        uid: uid,
        role: PollGroupRole.user,
        joinedAt: DateTime.now(),
        joinedBy: joinedBy,
      ),
    );
    await batch.commit();
  }

  Future<void> leaveGroup({
    required PollGroup group,
    required String uid,
  }) async {
    if (!group.memberIds.contains(uid)) {
      return;
    }
    if (group.createdBy == uid) {
      throw StateError('group_creator_cannot_leave');
    }

    final batch = _fs.instance.batch();
    batch.update(_groups().doc(group.id), {
      'memberIds': FieldValue.arrayRemove([uid]),
    });
    batch.delete(_members(group.id).doc(uid));
    await batch.commit();
  }

  static List<PollGroupAllowedMember> normalizeAllowedMembers(
    List<PollGroupAllowedMember> members,
  ) {
    final deduped = <String, PollGroupAllowedMember>{};
    for (final member in members) {
      final email = member.email.trim().toLowerCase();
      if (email.isEmpty) {
        continue;
      }
      deduped[email] = PollGroupAllowedMember(
        email: email,
        nickname: member.nickname?.trim().isEmpty == true
            ? null
            : member.nickname?.trim(),
        role: member.role,
        createdAt: member.createdAt,
        createdBy: member.createdBy,
      );
    }
    return deduped.values.toList();
  }

  static List<PollGroupAllowedDomain> normalizeAllowedDomains(
    List<PollGroupAllowedDomain> domains,
  ) {
    final deduped = <String, PollGroupAllowedDomain>{};
    for (final domain in domains) {
      final normalizedDomain = normalizeDomain(domain.domain);
      if (normalizedDomain == null) {
        continue;
      }
      deduped[normalizedDomain] = PollGroupAllowedDomain(
        domain: normalizedDomain,
        role: domain.role,
        createdAt: domain.createdAt,
        createdBy: domain.createdBy,
      );
    }
    return deduped.values.toList();
  }

  static String? normalizeDomain(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }
    final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    if (withoutAt.isEmpty ||
        withoutAt.startsWith('.') ||
        withoutAt.endsWith('.') ||
        withoutAt.contains('@') ||
        !withoutAt.contains('.')) {
      return null;
    }
    return withoutAt;
  }
}
