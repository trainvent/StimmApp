import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
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
    final creatorSnap = await firestore.collection('users').doc(creatorUid).get();
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
    await groupRef.collection('members').doc(creatorUid).set(
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
      final allowedMember = normalizedMembers.where((member) => member.email == email);
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

    test('respondToNotification accepts invite and adds membership', () async {
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
      expect(notification?.status, PollGroupAccessNotificationStatus.accepted);
    });
  });
}
