import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

class PollGroupRepository {
  PollGroupRepository(this._fs);

  final DatabaseService _fs;

  static PollGroupRepository create() => PollGroupRepository(locator.databaseService);

  CollectionReference<PollGroup> _groups() => _fs.colRef<PollGroup>(
    DatabaseCollections.pollGroups,
    fromFirestore: PollGroup.fromFirestore,
    toFirestore: PollGroup.toFirestore,
  );

  CollectionReference<PollGroupMember> _members(String groupId) => _fs.colRef<PollGroupMember>(
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

  Stream<List<PollGroup>> watchGroupsForUser(String uid) {
    return _fs.watchCol(
      _groups()
          .where('memberIds', arrayContains: uid)
          .orderBy('createdAt', descending: true),
    );
  }

  Future<String> createGroup({
    required String creatorUid,
    required String name,
    required String joinCode,
    required PollGroupNicknameMode nicknameMode,
    required bool managersCanInvite,
    DateTime? expiresAt,
    List<PollGroupAllowedMember> allowedMembers = const [],
  }) async {
    final now = DateTime.now();
    final groupRef = _groups().doc();
    final group = PollGroup(
      id: groupRef.id,
      name: name,
      createdBy: creatorUid,
      createdAt: now,
      expiresAt: expiresAt,
      joinCode: joinCode,
      nicknameMode: nicknameMode,
      managersCanInvite: managersCanInvite,
      memberIds: [creatorUid],
      importedMemberCount: allowedMembers.length,
    );

    final batch = _fs.instance.batch();
    batch.set(groupRef, group);
    batch.set(
      _members(groupRef.id).doc(creatorUid),
      PollGroupMember(
        uid: creatorUid,
        role: PollGroupRole.admin,
        joinedAt: now,
        joinedBy: creatorUid,
      ),
    );

    for (final member in allowedMembers) {
      batch.set(_allowedMembers(groupRef.id).doc(member.email.toLowerCase()), member);
    }

    await batch.commit();
    return groupRef.id;
  }

  Future<List<PollGroupAllowedMember>> getAllowedMembers(String groupId) async {
    final snap = await _allowedMembers(groupId).get();
    return snap.docs.map((doc) => doc.data()).toList();
  }
}
