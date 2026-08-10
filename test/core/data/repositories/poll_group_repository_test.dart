import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/poll_group_activity.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

class _TestPollGroupRepository extends PollGroupRepository {
  _TestPollGroupRepository(this.firestore) : super(DatabaseService(firestore));

  final FakeFirebaseFirestore firestore;

  @override
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
    final normalizedMembers = PollGroupRepository.normalizeAllowedMembers(
      allowedMembers,
    );
    final normalizedDomains = PollGroupRepository.normalizeAllowedDomains(
      allowedDomains,
    );
    final now = DateTime(2024, 1, 1);
    final groupRef = firestore.collection('pollGroups').doc();
    final creatorSnap = await firestore
        .collection('users')
        .doc(creatorUid)
        .get();
    final creatorData = creatorSnap.data() ?? const <String, dynamic>{};
    final actorDisplayName =
        (creatorData['displayName'] as String?)?.trim().isNotEmpty == true
        ? (creatorData['displayName'] as String).trim()
        : ((creatorData['email'] as String?)?.trim().isNotEmpty == true
              ? (creatorData['email'] as String).trim()
              : 'Group admin');

    await groupRef.set(
      PollGroup.toFirestore(
        PollGroup(
          id: groupRef.id,
          name: name,
          createdBy: creatorUid,
          createdAt: now,
          expiresAt: expiresAt,
          joinCode: joinCode,
          nicknameMode: nicknameMode,
          managersCanInvite: managersCanInvite,
          memberIds: [creatorUid],
          importedMemberCount: normalizedMembers.length,
          isActive: true,
          accessMode: accessMode,
          inviteLinkEnabled: inviteLinkEnabled,
        ),
        null,
      ),
    );
    await groupRef
        .collection('members')
        .doc(creatorUid)
        .set(
          PollGroupMember.toFirestore(
            PollGroupMember(
              uid: creatorUid,
              role: PollGroupRole.admin,
              joinedAt: now,
              joinedBy: creatorUid,
            ),
            null,
          ),
        );

    for (final member in normalizedMembers) {
      await groupRef
          .collection('allowedMembers')
          .doc(member.email.toLowerCase())
          .set(PollGroupAllowedMember.toFirestore(member, null));
    }
    for (final domain in normalizedDomains) {
      await groupRef
          .collection('allowedDomains')
          .doc(domain.domain)
          .set(PollGroupAllowedDomain.toFirestore(domain, null));
    }

    final users = await firestore.collection('users').get();
    for (final userDoc in users.docs) {
      final email = (userDoc.data()['email'] as String?)?.trim().toLowerCase();
      final allowedMember = normalizedMembers.where(
        (member) => member.email == email,
      );
      if (email == null || allowedMember.isEmpty) {
        continue;
      }
      final notificationRef = firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('groupAccessNotifications')
          .doc();
      await notificationRef.set(
        PollGroupAccessNotification.toFirestore(
          PollGroupAccessNotification(
            id: notificationRef.id,
            groupId: groupRef.id,
            groupName: name,
            actorUid: creatorUid,
            actorDisplayName: actorDisplayName,
            recipientUid: userDoc.id,
            role: allowedMember.first.role,
            accessMode: accessMode,
            type: PollGroupAccessNotificationType.invite,
            status: PollGroupAccessNotificationStatus.pending,
            createdAt: now,
          ),
          null,
        ),
      );
      await groupRef
          .collection('invitations')
          .doc(userDoc.id)
          .set(
            PollGroupInvitation.toFirestore(
              PollGroupInvitation(
                recipientUid: userDoc.id,
                email: email,
                displayName: userDoc.data()['displayName'] as String?,
                role: allowedMember.first.role,
                status: PollGroupInvitationStatus.pending,
                invitedAt: now,
                invitedBy: creatorUid,
              ),
              null,
            ),
          );
    }

    return groupRef.id;
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late PollGroupRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = _TestPollGroupRepository(firestore);
  });

  Future<void> addMember({
    required String groupId,
    required String uid,
    required PollGroupRole role,
    required DateTime joinedAt,
  }) async {
    await firestore
        .collection('pollGroups')
        .doc(groupId)
        .collection('members')
        .doc(uid)
        .set(
          PollGroupMember.toFirestore(
            PollGroupMember(
              uid: uid,
              role: role,
              joinedAt: joinedAt,
              joinedBy: 'owner',
            ),
            null,
          ),
        );
    await firestore.collection('pollGroups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([uid]),
    });
  }

  group('PollGroupRepository', () {
    test(
      'createGroup persists invite, privacy, members, and domains',
      () async {
        await firestore
            .collection('users')
            .doc('owner')
            .set(
              const UserProfile(
                uid: 'owner',
                displayName: 'Owner',
                email: 'owner@example.com',
              ).toJson(),
            );
        await firestore
            .collection('users')
            .doc('invitee')
            .set(
              const UserProfile(
                uid: 'invitee',
                displayName: 'Invitee',
                email: 'anna@example.com',
              ).toJson(),
            );

        final groupId = await repository.createGroup(
          creatorUid: 'owner',
          name: 'Operations',
          joinCode: 'GRP-ABC123',
          nicknameMode: PollGroupNicknameMode.adminAssigned,
          managersCanInvite: true,
          accessMode: PollGroupAccessMode.protected,
          inviteLinkEnabled: true,
          allowedMembers: [
            PollGroupAllowedMember(
              email: 'Anna@Example.com',
              nickname: 'Anna',
              role: PollGroupRole.user,
              createdAt: DateTime(2024, 1, 1),
              createdBy: 'owner',
            ),
          ],
          allowedDomains: [
            PollGroupAllowedDomain(
              domain: '@Example.com',
              role: PollGroupRole.manager,
              createdAt: DateTime(2024, 1, 1),
              createdBy: 'owner',
            ),
          ],
        );

        final groupSnap = await firestore
            .collection('pollGroups')
            .doc(groupId)
            .get();
        final allowedMembers = await firestore
            .collection('pollGroups')
            .doc(groupId)
            .collection('allowedMembers')
            .get();
        final allowedDomains = await firestore
            .collection('pollGroups')
            .doc(groupId)
            .collection('allowedDomains')
            .get();
        final notifications = await firestore
            .collection('users')
            .doc('invitee')
            .collection('groupAccessNotifications')
            .get();

        expect(groupSnap.data()?['accessMode'], 'protected');
        expect(groupSnap.data()?['inviteLinkEnabled'], isTrue);
        expect(groupSnap.data()?['importedMemberCount'], 1);
        expect(allowedMembers.docs.single.id, 'anna@example.com');
        expect(allowedDomains.docs.single.id, 'example.com');
        expect(notifications.docs, hasLength(1));
        expect(notifications.docs.single.data()['type'], 'invite');
      },
    );

    test('normalizes and deduplicates allowed members and domains', () {
      final members = PollGroupRepository.normalizeAllowedMembers([
        PollGroupAllowedMember(
          email: ' DUP@example.com ',
          nickname: 'First',
          role: PollGroupRole.user,
          createdAt: DateTime(2024, 1, 1),
          createdBy: 'owner',
        ),
        PollGroupAllowedMember(
          email: 'dup@example.com',
          nickname: 'Latest',
          role: PollGroupRole.manager,
          createdAt: DateTime(2024, 1, 1),
          createdBy: 'owner',
        ),
      ]);
      final domains = PollGroupRepository.normalizeAllowedDomains([
        PollGroupAllowedDomain(
          domain: '@Example.com',
          role: PollGroupRole.user,
          createdAt: DateTime(2024, 1, 1),
          createdBy: 'owner',
        ),
        PollGroupAllowedDomain(
          domain: 'example.com',
          role: PollGroupRole.admin,
          createdAt: DateTime(2024, 1, 1),
          createdBy: 'owner',
        ),
      ]);

      expect(members, hasLength(1));
      expect(members.single.email, 'dup@example.com');
      expect(members.single.nickname, 'Latest');
      expect(members.single.role, PollGroupRole.manager);

      expect(domains, hasLength(1));
      expect(domains.single.domain, 'example.com');
      expect(domains.single.role, PollGroupRole.admin);
    });

    test('watchGroupsForUser returns created groups', () async {
      await repository.createGroup(
        creatorUid: 'owner',
        name: 'Operations',
        joinCode: 'GRP-ABC123',
        nicknameMode: PollGroupNicknameMode.selfNamed,
        managersCanInvite: true,
        accessMode: PollGroupAccessMode.private,
        inviteLinkEnabled: false,
      );

      final groups = await repository.watchGroupsForUser('owner').first;

      expect(groups, hasLength(1));
      expect(groups.single.name, 'Operations');
    });

    test('sole member leaving deletes the group', () async {
      final groupId = await repository.createGroup(
        creatorUid: 'owner',
        name: 'Solo',
        joinCode: 'GRP-SOLO',
        nicknameMode: PollGroupNicknameMode.selfNamed,
        managersCanInvite: true,
        accessMode: PollGroupAccessMode.private,
        inviteLinkEnabled: false,
      );
      final group = (await repository.getGroup(groupId))!;

      final result = await repository.leaveGroup(group: group, uid: 'owner');

      expect(result, PollGroupLeaveResult.groupDeleted);
      expect(await repository.getGroup(groupId), isNull);
      expect(
        (await firestore
                .collection('pollGroups')
                .doc(groupId)
                .collection('members')
                .get())
            .docs,
        isEmpty,
      );
    });

    test(
      'creator leaving transfers ownership to longest-serving admin',
      () async {
        final groupId = await repository.createGroup(
          creatorUid: 'owner',
          name: 'Team',
          joinCode: 'GRP-TEAM',
          nicknameMode: PollGroupNicknameMode.selfNamed,
          managersCanInvite: true,
          accessMode: PollGroupAccessMode.private,
          inviteLinkEnabled: false,
        );
        await addMember(
          groupId: groupId,
          uid: 'newer-admin',
          role: PollGroupRole.admin,
          joinedAt: DateTime(2024, 3),
        );
        await addMember(
          groupId: groupId,
          uid: 'older-admin',
          role: PollGroupRole.admin,
          joinedAt: DateTime(2024, 2),
        );
        final group = (await repository.getGroup(groupId))!;

        final result = await repository.leaveGroup(group: group, uid: 'owner');
        final updatedGroup = (await repository.getGroup(groupId))!;
        final formerOwner = await firestore
            .collection('pollGroups')
            .doc(groupId)
            .collection('members')
            .doc('owner')
            .get();

        expect(result, PollGroupLeaveResult.left);
        expect(updatedGroup.createdBy, 'older-admin');
        expect(updatedGroup.memberIds, isNot(contains('owner')));
        expect(formerOwner.exists, isFalse);
        expect(
          (await repository.watchActivities(groupId).first).single.type,
          PollGroupActivityType.ownershipTransferred,
        );
      },
    );

    test(
      'creator leaving members without an admin starts an election',
      () async {
        final groupId = await repository.createGroup(
          creatorUid: 'owner',
          name: 'Team',
          joinCode: 'GRP-TEAM',
          nicknameMode: PollGroupNicknameMode.selfNamed,
          managersCanInvite: true,
          accessMode: PollGroupAccessMode.private,
          inviteLinkEnabled: false,
        );
        await addMember(
          groupId: groupId,
          uid: 'member',
          role: PollGroupRole.user,
          joinedAt: DateTime(2024, 2),
        );
        final group = (await repository.getGroup(groupId))!;

        final before = DateTime.now();
        final result = await repository.leaveGroup(group: group, uid: 'owner');
        final updatedGroup = (await repository.getGroup(groupId))!;
        final election = await repository.watchAdminElection(groupId).first;

        expect(result, PollGroupLeaveResult.left);
        expect(updatedGroup.createdBy, 'owner');
        expect(updatedGroup.memberIds, isNot(contains('owner')));
        expect(updatedGroup.adminElectionOpen, isTrue);
        expect(updatedGroup.adminElectionEndsAt, isNotNull);
        expect(
          updatedGroup.adminElectionEndsAt!.difference(before).inHours,
          inInclusiveRange(71, 72),
        );
        expect(election?.candidateUids, ['member']);
        expect(election?.isOpen, isTrue);
        expect(
          (await repository.watchActivities(groupId).first).single.type,
          PollGroupActivityType.adminElectionStarted,
        );
      },
    );

    test(
      'accepted member can be removed with prepared access revoked',
      () async {
        await firestore
            .collection('users')
            .doc('owner')
            .set(
              const UserProfile(
                uid: 'owner',
                displayName: 'Owner',
                email: 'owner@example.com',
              ).toJson(),
            );
        await firestore
            .collection('users')
            .doc('invitee')
            .set(
              const UserProfile(
                uid: 'invitee',
                displayName: 'Invitee',
                email: 'anna@example.com',
              ).toJson(),
            );

        final groupId = await repository.createGroup(
          creatorUid: 'owner',
          name: 'Operations',
          joinCode: 'GRP-ABC123',
          nicknameMode: PollGroupNicknameMode.selfNamed,
          managersCanInvite: true,
          accessMode: PollGroupAccessMode.private,
          inviteLinkEnabled: false,
          allowedMembers: [
            PollGroupAllowedMember(
              email: 'anna@example.com',
              nickname: 'Anna',
              role: PollGroupRole.manager,
              createdAt: DateTime(2024, 1, 1),
              createdBy: 'owner',
            ),
          ],
        );

        final notifications = await firestore
            .collection('users')
            .doc('invitee')
            .collection('groupAccessNotifications')
            .get();
        final notificationId = notifications.docs.single.id;

        await repository.respondToNotification(
          currentUid: 'invitee',
          notificationId: notificationId,
          accept: true,
        );

        final group = await repository.getGroup(groupId);
        final memberSnap = await firestore
            .collection('pollGroups')
            .doc(groupId)
            .collection('members')
            .doc('invitee')
            .get();
        final notification = await repository.getNotification(
          'invitee',
          notificationId,
        );

        expect(group?.memberIds, contains('invitee'));
        expect(memberSnap.exists, isTrue);
        expect(
          notification?.status,
          PollGroupAccessNotificationStatus.accepted,
        );
        expect(
          (await repository.watchInvitations(groupId).first).single.status,
          PollGroupInvitationStatus.accepted,
        );

        await repository.removeMember(
          group: group!,
          uid: 'invitee',
          actorUid: 'owner',
          actorDisplayName: 'Owner',
          role: PollGroupRole.manager,
          email: 'anna@example.com',
        );

        final updatedGroup = await repository.getGroup(groupId);
        final removedMember = await firestore
            .collection('pollGroups')
            .doc(groupId)
            .collection('members')
            .doc('invitee')
            .get();
        final removedPreparedAccess = await firestore
            .collection('pollGroups')
            .doc(groupId)
            .collection('allowedMembers')
            .doc('anna@example.com')
            .get();
        final updatedNotifications = await firestore
            .collection('users')
            .doc('invitee')
            .collection('groupAccessNotifications')
            .orderBy('createdAt')
            .get();
        final accessibleGroups = await repository.getAccessibleGroupsForUser(
          'invitee',
        );
        final invitation =
            (await repository.watchInvitations(groupId).first).single;

        expect(updatedGroup?.memberIds, isNot(contains('invitee')));
        expect(invitation.status, PollGroupInvitationStatus.removed);
        expect(updatedGroup?.importedMemberCount, 0);
        expect(removedMember.exists, isFalse);
        expect(removedPreparedAccess.exists, isFalse);
        expect(accessibleGroups, isEmpty);
        expect(updatedNotifications.docs, hasLength(2));
        expect(updatedNotifications.docs.last.data()['type'], 'removed');
        expect(updatedNotifications.docs.last.data()['readAt'], isNull);
        expect(
          updatedNotifications.docs.last.data()['actorDisplayName'],
          'Owner',
        );
        final removalNotificationId = updatedNotifications.docs.last.id;
        final unreadRemoval = await repository.getNotification(
          'invitee',
          removalNotificationId,
        );
        expect(unreadRemoval?.countsAsUnread, isTrue);

        await repository.markNotificationsRead('invitee', [
          removalNotificationId,
        ]);
        final readRemoval = await repository.getNotification(
          'invitee',
          removalNotificationId,
        );
        expect(readRemoval?.readAt, isNotNull);
        expect(readRemoval?.countsAsUnread, isFalse);
        final activities = await repository.watchActivities(groupId).first;
        expect(
          activities.map((activity) => activity.type),
          containsAll([
            PollGroupActivityType.memberJoined,
            PollGroupActivityType.memberRemoved,
          ]),
        );
      },
    );

    test('records group publication activity', () async {
      final groupId = await repository.createGroup(
        creatorUid: 'owner',
        name: 'Operations',
        joinCode: 'GRP-ABC123',
        nicknameMode: PollGroupNicknameMode.selfNamed,
        managersCanInvite: true,
        accessMode: PollGroupAccessMode.private,
        inviteLinkEnabled: false,
      );

      await repository.recordPublicationPublished(
        groupId: groupId,
        actorUid: 'owner',
        actorDisplayName: 'Owner',
        title: 'Quarterly priorities',
      );

      final activity = (await repository.watchActivities(groupId).first).single;
      expect(activity.type, PollGroupActivityType.publicationPublished);
      expect(activity.actorDisplayName, 'Owner');
      expect(activity.targetTitle, 'Quarterly priorities');
    });
  });
}
