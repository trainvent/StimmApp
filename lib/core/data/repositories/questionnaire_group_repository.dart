import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/questionnaire_group.dart';
import 'package:stimmapp/core/data/models/questionnaire_group_activity.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

enum QuestionnaireGroupLeaveResult { left, groupDeleted }

class QuestionnaireGroupRepository {
  QuestionnaireGroupRepository(this._fs);

  final DatabaseService _fs;

  static QuestionnaireGroupRepository create() =>
      QuestionnaireGroupRepository(locator.databaseService);

  CollectionReference<QuestionnaireGroup> _groups() =>
      _fs.colRef<QuestionnaireGroup>(
        DatabaseCollections.questionnaireGroups,
        fromFirestore: QuestionnaireGroup.fromFirestore,
        toFirestore: QuestionnaireGroup.toFirestore,
      );

  CollectionReference<QuestionnaireGroupMember> _members(String groupId) =>
      _fs.colRef<QuestionnaireGroupMember>(
        '${DatabaseCollections.questionnaireGroups}/$groupId/members',
        fromFirestore: QuestionnaireGroupMember.fromFirestore,
        toFirestore: QuestionnaireGroupMember.toFirestore,
      );

  CollectionReference<QuestionnaireGroupAllowedMember> _allowedMembers(
    String groupId,
  ) => _fs.colRef<QuestionnaireGroupAllowedMember>(
    '${DatabaseCollections.questionnaireGroups}/$groupId/allowedMembers',
    fromFirestore: QuestionnaireGroupAllowedMember.fromFirestore,
    toFirestore: QuestionnaireGroupAllowedMember.toFirestore,
  );

  CollectionReference<QuestionnaireGroupInvitation> _invitations(
    String groupId,
  ) => _fs.colRef<QuestionnaireGroupInvitation>(
    '${DatabaseCollections.questionnaireGroups}/$groupId/invitations',
    fromFirestore: QuestionnaireGroupInvitation.fromFirestore,
    toFirestore: QuestionnaireGroupInvitation.toFirestore,
  );

  CollectionReference<QuestionnaireGroupAdminElection> _adminElections(
    String groupId,
  ) => _fs.colRef<QuestionnaireGroupAdminElection>(
    '${DatabaseCollections.questionnaireGroups}/$groupId/adminElections',
    fromFirestore: QuestionnaireGroupAdminElection.fromFirestore,
    toFirestore: QuestionnaireGroupAdminElection.toFirestore,
  );

  CollectionReference<QuestionnaireGroupAdminElectionVote> _adminElectionVotes(
    String groupId,
  ) => _fs.colRef<QuestionnaireGroupAdminElectionVote>(
    '${DatabaseCollections.questionnaireGroups}/$groupId/adminElections/current/votes',
    fromFirestore: QuestionnaireGroupAdminElectionVote.fromFirestore,
    toFirestore: QuestionnaireGroupAdminElectionVote.toFirestore,
  );

  CollectionReference<QuestionnaireGroupAllowedDomain> _allowedDomains(
    String groupId,
  ) => _fs.colRef<QuestionnaireGroupAllowedDomain>(
    '${DatabaseCollections.questionnaireGroups}/$groupId/allowedDomains',
    fromFirestore: QuestionnaireGroupAllowedDomain.fromFirestore,
    toFirestore: QuestionnaireGroupAllowedDomain.toFirestore,
  );

  CollectionReference<QuestionnaireGroupActivity> _activities(
    String groupId,
  ) => _fs.colRef<QuestionnaireGroupActivity>(
    '${DatabaseCollections.questionnaireGroups}/$groupId/${DatabaseCollections.groupActivities}',
    fromFirestore: QuestionnaireGroupActivity.fromFirestore,
    toFirestore: QuestionnaireGroupActivity.toFirestore,
  );

  CollectionReference<QuestionnaireGroupAccessNotification> _notifications(
    String uid,
  ) => _fs.colRef<QuestionnaireGroupAccessNotification>(
    '${DatabaseCollections.users}/$uid/${DatabaseCollections.groupAccessNotifications}',
    fromFirestore: QuestionnaireGroupAccessNotification.fromFirestore,
    toFirestore: QuestionnaireGroupAccessNotification.toFirestore,
  );

  Stream<List<QuestionnaireGroup>> watchGroupsForUser(String uid) {
    return _fs.watchCol(_groups().where('memberIds', arrayContains: uid)).map((
      groups,
    ) {
      final sortedGroups = groups.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sortedGroups;
    });
  }

  Stream<List<QuestionnaireGroup>> watchAccessibleGroupsForUser(String uid) {
    return watchGroupsForUser(uid);
  }

  Future<List<QuestionnaireGroup>> getAccessibleGroupsForUser(
    String uid,
  ) async {
    return watchGroupsForUser(uid).first;
  }

  Future<String> createGroup({
    required String creatorUid,
    required String name,
    required String joinCode,
    required QuestionnaireGroupNicknameMode nicknameMode,
    required bool managersCanInvite,
    required QuestionnaireGroupAccessMode accessMode,
    required bool inviteLinkEnabled,
    DateTime? expiresAt,
    List<QuestionnaireGroupAllowedMember> allowedMembers = const [],
    List<QuestionnaireGroupAllowedDomain> allowedDomains = const [],
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty ||
        normalizedName.length > AppLimits.maxGroupNameLength) {
      throw StateError('invalid_group_name');
    }
    final normalizedMembers = normalizeAllowedMembers(allowedMembers);
    final normalizedDomains = normalizeAllowedDomains(allowedDomains);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createPollGroup',
      );
      final result = await callable.call(<String, Object?>{
        'name': normalizedName,
        'joinCode': joinCode,
        'nicknameMode': questionnaireGroupNicknameModeToFirestore(nicknameMode),
        'managersCanInvite': managersCanInvite,
        'accessMode': questionnaireGroupAccessModeToFirestore(accessMode),
        'inviteLinkEnabled': inviteLinkEnabled,
        'expiresAtMillis': expiresAt?.millisecondsSinceEpoch,
        'allowedMembers': normalizedMembers
            .map(
              (member) => <String, Object?>{
                'email': member.email,
                'nickname': member.nickname,
                'role': questionnaireGroupRoleToFirestore(member.role),
              },
            )
            .toList(),
        'allowedDomains': normalizedDomains
            .map(
              (domain) => <String, Object?>{
                'domain': domain.domain,
                'role': questionnaireGroupRoleToFirestore(domain.role),
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

  Future<void> setProfilePicture(String groupId, String? url) async {
    await _groups().doc(groupId).update({'profilePictureUrl': url});
  }

  Future<int> countGroupsCreatedByUser(String uid) async {
    final groups = await watchGroupsForUser(uid).first;
    return groups.where((group) => group.createdBy == uid).take(2).length;
  }

  Future<List<QuestionnaireGroupAllowedMember>> getAllowedMembers(
    String groupId,
  ) async {
    final snap = await _allowedMembers(groupId).get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  Future<List<QuestionnaireGroupAllowedDomain>> getAllowedDomains(
    String groupId,
  ) async {
    final snap = await _allowedDomains(groupId).get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  Future<int> updateGroup({
    required QuestionnaireGroup group,
    List<QuestionnaireGroupAllowedMember> allowedMembers = const [],
    List<QuestionnaireGroupAllowedDomain> allowedDomains = const [],
    List<String> inviteEmails = const [],
  }) async {
    final normalizedName = group.name.trim();
    if (normalizedName.isEmpty ||
        normalizedName.length > AppLimits.maxGroupNameLength) {
      throw StateError('invalid_group_name');
    }
    final normalizedMembers = normalizeAllowedMembers(allowedMembers);
    final normalizedDomains = normalizeAllowedDomains(allowedDomains);
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('updatePollGroup')
          .call({
            'groupId': group.id,
            'name': normalizedName,
            'nicknameMode': questionnaireGroupNicknameModeToFirestore(
              group.nicknameMode,
            ),
            'managersCanInvite': group.managersCanInvite,
            'accessMode': questionnaireGroupAccessModeToFirestore(
              group.accessMode,
            ),
            'inviteLinkEnabled': group.inviteLinkEnabled,
            'expiresAtMillis': group.expiresAt?.millisecondsSinceEpoch,
            'allowedMembers': normalizedMembers
                .map(
                  (member) => <String, Object?>{
                    'email': member.email,
                    'nickname': member.nickname,
                    'role': questionnaireGroupRoleToFirestore(member.role),
                  },
                )
                .toList(),
            'allowedDomains': normalizedDomains
                .map(
                  (domain) => <String, Object?>{
                    'domain': domain.domain,
                    'role': questionnaireGroupRoleToFirestore(domain.role),
                  },
                )
                .toList(),
            'inviteEmails': inviteEmails,
          });
      final data = Map<String, dynamic>.from(result.data as Map);
      return data['invitationCount'] as int? ?? 0;
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? e.code);
    }
  }

  Stream<List<QuestionnaireGroupAccessNotification>> watchNotifications(
    String uid,
  ) {
    return _fs.watchCol(
      _notifications(uid).orderBy('createdAt', descending: true),
    );
  }

  Future<void> markNotificationsRead(String uid, Iterable<String> ids) async {
    final uniqueIds = ids.where((id) => id.isNotEmpty).toSet();
    if (uniqueIds.isEmpty) return;
    final batch = _fs.instance.batch();
    for (final id in uniqueIds) {
      batch.update(_notifications(uid).doc(id), {
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<QuestionnaireGroup?> getGroup(String groupId) async {
    return _fs.getDoc(_groups().doc(groupId));
  }

  Stream<QuestionnaireGroup?> watchGroup(String groupId) {
    return _fs.watchDoc(_groups().doc(groupId));
  }

  Stream<QuestionnaireGroupMember?> watchMember(String groupId, String uid) {
    return _fs.watchDoc(_members(groupId).doc(uid));
  }

  Stream<List<QuestionnaireGroupMember>> watchMembers(String groupId) {
    return _fs.watchCol(_members(groupId).orderBy('joinedAt'));
  }

  Stream<List<QuestionnaireGroupInvitation>> watchInvitations(String groupId) {
    return _fs.watchCol(
      _invitations(groupId).orderBy('invitedAt', descending: true),
    );
  }

  Stream<List<QuestionnaireGroupActivity>> watchActivities(String groupId) {
    return _fs.watchCol(
      _activities(groupId).orderBy('createdAt', descending: true),
    );
  }

  void _addActivityToBatch(
    WriteBatch batch, {
    required String groupId,
    required QuestionnaireGroupActivityType type,
    required String actorUid,
    String? actorDisplayName,
    String? subjectUid,
    String? subjectDisplayName,
    String? targetTitle,
    int? count,
    DateTime? createdAt,
  }) {
    final ref = _activities(groupId).doc();
    batch.set(
      ref,
      QuestionnaireGroupActivity(
        id: ref.id,
        type: type,
        actorUid: actorUid,
        actorDisplayName: actorDisplayName,
        subjectUid: subjectUid,
        subjectDisplayName: subjectDisplayName,
        targetTitle: targetTitle,
        count: count,
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
  }

  Future<String?> _userDisplayName(String uid) async {
    final snapshot = await _fs.instance
        .collection(DatabaseCollections.users)
        .doc(uid)
        .get();
    final data = snapshot.data();
    final displayName = data?['displayName'] as String?;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final email = data?['email'] as String?;
    return email == null || email.trim().isEmpty ? null : email.trim();
  }

  Future<void> recordPublicationPublished({
    required String groupId,
    required String actorUid,
    required String title,
    String? actorDisplayName,
  }) async {
    final ref = _activities(groupId).doc();
    await ref.set(
      QuestionnaireGroupActivity(
        id: ref.id,
        type: QuestionnaireGroupActivityType.publicationPublished,
        actorUid: actorUid,
        actorDisplayName: actorDisplayName,
        targetTitle: title,
        createdAt: DateTime.now(),
      ),
    );
  }

  Stream<QuestionnaireGroupAdminElection?> watchAdminElection(String groupId) {
    return _fs.watchDoc(_adminElections(groupId).doc('current'));
  }

  Stream<QuestionnaireGroupAdminElectionVote?> watchAdminElectionVote(
    String groupId,
    String uid,
  ) {
    return _fs.watchDoc(_adminElectionVotes(groupId).doc(uid));
  }

  Future<void> castAdminElectionVote({
    required String groupId,
    required String candidateUid,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('castPollGroupAdminVote')
          .call({'groupId': groupId, 'candidateUid': candidateUid});
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? e.code);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    final membersSnap = await _members(groupId).get();
    final allowedMembersSnap = await _allowedMembers(groupId).get();
    final allowedDomainsSnap = await _allowedDomains(groupId).get();
    final invitationsSnap = await _invitations(groupId).get();
    final activitiesSnap = await _activities(groupId).get();
    final electionSnap = await _adminElections(groupId).get();
    final electionVotes = electionSnap.docs.isEmpty
        ? const <QueryDocumentSnapshot<QuestionnaireGroupAdminElectionVote>>[]
        : (await _adminElectionVotes(groupId).get()).docs;
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
    for (final doc in invitationsSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in activitiesSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in electionVotes) {
      batch.delete(doc.reference);
    }
    for (final doc in electionSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_groups().doc(groupId));
    await batch.commit();
  }

  Future<QuestionnaireGroupAccessNotification?> getNotification(
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
    if (notification.status !=
        QuestionnaireGroupAccessNotificationStatus.pending) {
      return;
    }

    final groupRef = _groups().doc(notification.groupId);
    final joiningUid =
        notification.type == QuestionnaireGroupAccessNotificationType.invite
        ? currentUid
        : notification.actorUid;
    final now = DateTime.now();
    final invitationRef = _invitations(notification.groupId).doc(joiningUid);
    final invitation =
        notification.type == QuestionnaireGroupAccessNotificationType.invite
        ? await _fs.getDoc(invitationRef)
        : null;
    final joiningDisplayName = accept
        ? await _userDisplayName(joiningUid)
        : null;
    final batch = _fs.instance.batch();

    if (accept) {
      batch.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([joiningUid]),
      });
      batch.set(
        _members(notification.groupId).doc(joiningUid),
        QuestionnaireGroupMember(
          uid: joiningUid,
          role: notification.role,
          joinedAt: now,
          joinedBy: currentUid,
        ),
      );
      _addActivityToBatch(
        batch,
        groupId: notification.groupId,
        type: QuestionnaireGroupActivityType.memberJoined,
        actorUid: joiningUid,
        actorDisplayName: joiningDisplayName,
        createdAt: now,
      );
    }

    batch.set(
      notificationRef,
      notification.copyWith(
        status: accept
            ? QuestionnaireGroupAccessNotificationStatus.accepted
            : QuestionnaireGroupAccessNotificationStatus.denied,
        resolvedAt: now,
      ),
    );
    if (invitation != null) {
      batch.set(
        invitationRef,
        invitation.copyWith(
          status: accept
              ? QuestionnaireGroupInvitationStatus.accepted
              : QuestionnaireGroupInvitationStatus.declined,
          resolvedAt: now,
        ),
      );
    }

    await batch.commit();
  }

  Future<void> requestAccess({
    required String requesterUid,
    required String requesterDisplayName,
    required QuestionnaireGroup group,
    required QuestionnaireGroupRole requestedRole,
  }) async {
    final now = DateTime.now();
    final notificationRef = _notifications(group.createdBy).doc();
    await notificationRef.set(
      QuestionnaireGroupAccessNotification(
        id: notificationRef.id,
        groupId: group.id,
        groupName: group.name,
        actorUid: requesterUid,
        actorDisplayName: requesterDisplayName,
        recipientUid: group.createdBy,
        role: requestedRole,
        accessMode: group.accessMode,
        type: QuestionnaireGroupAccessNotificationType.request,
        status: QuestionnaireGroupAccessNotificationStatus.pending,
        createdAt: now,
      ),
    );
  }

  Future<void> joinOpenGroup({
    required QuestionnaireGroup group,
    required String uid,
    required String joinedBy,
    String? actorDisplayName,
  }) async {
    final batch = _fs.instance.batch();
    batch.update(_groups().doc(group.id), {
      'memberIds': FieldValue.arrayUnion([uid]),
    });
    batch.set(
      _members(group.id).doc(uid),
      QuestionnaireGroupMember(
        uid: uid,
        role: QuestionnaireGroupRole.user,
        joinedAt: DateTime.now(),
        joinedBy: joinedBy,
      ),
    );
    _addActivityToBatch(
      batch,
      groupId: group.id,
      type: QuestionnaireGroupActivityType.memberJoined,
      actorUid: uid,
      actorDisplayName: actorDisplayName,
    );
    await batch.commit();
  }

  Future<QuestionnaireGroupLeaveResult> leaveGroup({
    required QuestionnaireGroup group,
    required String uid,
  }) async {
    final currentGroup = await getGroup(group.id);
    if (currentGroup == null || !currentGroup.memberIds.contains(uid)) {
      return QuestionnaireGroupLeaveResult.left;
    }

    if (currentGroup.memberIds.length == 1) {
      if (currentGroup.createdBy != uid) {
        try {
          final result = await FirebaseFunctions.instance
              .httpsCallable('leavePollGroup')
              .call({'groupId': currentGroup.id});
          final data = Map<String, dynamic>.from(result.data as Map);
          return data['result'] == 'groupDeleted'
              ? QuestionnaireGroupLeaveResult.groupDeleted
              : QuestionnaireGroupLeaveResult.left;
        } on FirebaseFunctionsException catch (e) {
          throw StateError(e.message ?? e.code);
        }
      }
      await deleteGroup(currentGroup.id);
      return QuestionnaireGroupLeaveResult.groupDeleted;
    }

    String? successorUid;
    if (currentGroup.createdBy == uid) {
      final members = await _members(currentGroup.id).get();
      final adminCandidates =
          members.docs
              .map((doc) => doc.data())
              .where(
                (member) =>
                    member.uid != uid &&
                    member.role == QuestionnaireGroupRole.admin &&
                    currentGroup.memberIds.contains(member.uid),
              )
              .toList()
            ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
      if (adminCandidates.isEmpty) {
        final now = DateTime.now();
        final endsAt = now.add(const Duration(days: 3));
        final candidateUids = currentGroup.memberIds
            .where((memberUid) => memberUid != uid)
            .toList();
        final previousVotes = await _adminElectionVotes(currentGroup.id).get();
        final batch = _fs.instance.batch();
        for (final vote in previousVotes.docs) {
          batch.delete(vote.reference);
        }
        batch.update(_groups().doc(currentGroup.id), {
          'memberIds': FieldValue.arrayRemove([uid]),
          'adminElectionStatus': 'open',
          'adminElectionEndsAt': Timestamp.fromDate(endsAt),
        });
        batch.delete(_members(currentGroup.id).doc(uid));
        batch.set(
          _adminElections(currentGroup.id).doc('current'),
          QuestionnaireGroupAdminElection(
            id: 'current',
            status: 'open',
            startedAt: now,
            endsAt: endsAt,
            initiatedBy: uid,
            candidateUids: candidateUids,
          ),
        );
        _addActivityToBatch(
          batch,
          groupId: currentGroup.id,
          type: QuestionnaireGroupActivityType.adminElectionStarted,
          actorUid: uid,
          actorDisplayName: await _userDisplayName(uid),
          createdAt: now,
        );
        await batch.commit();
        return QuestionnaireGroupLeaveResult.left;
      }
      successorUid = adminCandidates.first.uid;
    }

    final batch = _fs.instance.batch();
    final actorDisplayName = await _userDisplayName(uid);
    batch.update(_groups().doc(currentGroup.id), {
      'memberIds': FieldValue.arrayRemove([uid]),
      'createdBy': ?successorUid,
      if (successorUid != null) 'adminElectionStatus': null,
      if (successorUid != null) 'adminElectionEndsAt': null,
    });
    batch.delete(_members(currentGroup.id).doc(uid));
    _addActivityToBatch(
      batch,
      groupId: currentGroup.id,
      type: successorUid == null
          ? QuestionnaireGroupActivityType.memberLeft
          : QuestionnaireGroupActivityType.ownershipTransferred,
      actorUid: uid,
      actorDisplayName: actorDisplayName,
      subjectUid: successorUid,
      subjectDisplayName: successorUid == null
          ? null
          : await _userDisplayName(successorUid),
    );
    await batch.commit();
    return QuestionnaireGroupLeaveResult.left;
  }

  Future<void> removeMember({
    required QuestionnaireGroup group,
    required String uid,
    required String actorUid,
    required String actorDisplayName,
    required QuestionnaireGroupRole role,
    String? email,
    String? memberDisplayName,
  }) async {
    if (uid == group.createdBy) {
      throw StateError('group_creator_cannot_be_removed');
    }
    if (!group.memberIds.contains(uid)) {
      return;
    }

    final normalizedEmail = email?.trim().toLowerCase();
    final allowedMemberRef = normalizedEmail == null || normalizedEmail.isEmpty
        ? null
        : _allowedMembers(group.id).doc(normalizedEmail);
    final allowedMemberExists = allowedMemberRef == null
        ? false
        : (await allowedMemberRef.get()).exists;
    final invitationRef = _invitations(group.id).doc(uid);
    final invitation = await _fs.getDoc(invitationRef);
    final now = DateTime.now();
    final notificationRef = _notifications(uid).doc();
    final batch = _fs.instance.batch();
    batch.update(_groups().doc(group.id), {
      'memberIds': FieldValue.arrayRemove([uid]),
      if (allowedMemberExists) 'importedMemberCount': FieldValue.increment(-1),
    });
    batch.delete(_members(group.id).doc(uid));
    if (allowedMemberExists) {
      batch.delete(allowedMemberRef);
    }
    if (invitation != null) {
      batch.set(
        invitationRef,
        invitation.copyWith(
          status: QuestionnaireGroupInvitationStatus.removed,
          resolvedAt: now,
        ),
      );
    }
    batch.set(
      notificationRef,
      QuestionnaireGroupAccessNotification(
        id: notificationRef.id,
        groupId: group.id,
        groupName: group.name,
        actorUid: actorUid,
        actorDisplayName: actorDisplayName,
        recipientUid: uid,
        role: role,
        accessMode: group.accessMode,
        type: QuestionnaireGroupAccessNotificationType.removed,
        status: QuestionnaireGroupAccessNotificationStatus.accepted,
        createdAt: now,
        resolvedAt: now,
      ),
    );
    _addActivityToBatch(
      batch,
      groupId: group.id,
      type: QuestionnaireGroupActivityType.memberRemoved,
      actorUid: actorUid,
      actorDisplayName: actorDisplayName,
      subjectUid: uid,
      subjectDisplayName: memberDisplayName ?? email,
      createdAt: now,
    );
    await batch.commit();
  }

  Future<void> updateMember({
    required QuestionnaireGroup group,
    required QuestionnaireGroupMember member,
    required QuestionnaireGroupRole role,
    String? nickname,
    String? email,
  }) async {
    if (!group.memberIds.contains(member.uid)) {
      throw StateError('group_member_not_found');
    }
    if (member.uid == group.createdBy && role != QuestionnaireGroupRole.admin) {
      throw StateError('group_creator_must_remain_admin');
    }

    final trimmedNickname = nickname?.trim();
    final normalizedNickname =
        trimmedNickname == null || trimmedNickname.isEmpty
        ? null
        : trimmedNickname;
    if (normalizedNickname != null &&
        normalizedNickname.length > AppLimits.maxGroupNicknameLength) {
      throw StateError('invalid_group_nickname');
    }

    final batch = _fs.instance.batch();
    batch.update(_members(group.id).doc(member.uid), {
      'nickname': normalizedNickname,
      'role': questionnaireGroupRoleToFirestore(role),
    });

    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      final allowedMemberRef = _allowedMembers(group.id).doc(normalizedEmail);
      if ((await allowedMemberRef.get()).exists) {
        batch.update(allowedMemberRef, {
          'nickname': normalizedNickname,
          'role': questionnaireGroupRoleToFirestore(role),
        });
      }
    }

    await batch.commit();
  }

  static List<QuestionnaireGroupAllowedMember> normalizeAllowedMembers(
    List<QuestionnaireGroupAllowedMember> members,
  ) {
    final deduped = <String, QuestionnaireGroupAllowedMember>{};
    for (final member in members) {
      final email = member.email.trim().toLowerCase();
      if (email.isEmpty) {
        continue;
      }
      final trimmedNickname = member.nickname?.trim();
      final normalizedNickname =
          trimmedNickname == null || trimmedNickname.isEmpty
          ? null
          : (trimmedNickname.length > AppLimits.maxGroupNicknameLength
                ? trimmedNickname.substring(0, AppLimits.maxGroupNicknameLength)
                : trimmedNickname);
      deduped[email] = QuestionnaireGroupAllowedMember(
        email: email,
        nickname: normalizedNickname,
        role: member.role,
        createdAt: member.createdAt,
        createdBy: member.createdBy,
      );
    }
    return deduped.values.toList();
  }

  static List<QuestionnaireGroupAllowedDomain> normalizeAllowedDomains(
    List<QuestionnaireGroupAllowedDomain> domains,
  ) {
    final deduped = <String, QuestionnaireGroupAllowedDomain>{};
    for (final domain in domains) {
      final normalizedDomain = normalizeDomain(domain.domain);
      if (normalizedDomain == null) {
        continue;
      }
      deduped[normalizedDomain] = QuestionnaireGroupAllowedDomain(
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
        withoutAt.length > AppLimits.maxDomainLength ||
        withoutAt.startsWith('.') ||
        withoutAt.endsWith('.') ||
        withoutAt.contains('@') ||
        !withoutAt.contains('.')) {
      return null;
    }
    return withoutAt;
  }
}
