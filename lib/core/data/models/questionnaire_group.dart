import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionnaireGroupRole { admin, manager, user }

enum QuestionnaireGroupNicknameMode { selfNamed, adminAssigned }

enum QuestionnaireGroupAccessMode { private, protected, open }

enum QuestionnaireGroupAccessNotificationType { invite, request, removed }

enum QuestionnaireGroupAccessNotificationStatus { pending, accepted, denied }

enum QuestionnaireGroupInvitationStatus { pending, accepted, declined, removed }

String questionnaireGroupRoleToFirestore(QuestionnaireGroupRole role) {
  switch (role) {
    case QuestionnaireGroupRole.admin:
      return 'admin';
    case QuestionnaireGroupRole.manager:
      return 'manager';
    case QuestionnaireGroupRole.user:
      return 'user';
  }
}

QuestionnaireGroupRole parseQuestionnaireGroupRole(String? value) {
  switch (value) {
    case 'admin':
      return QuestionnaireGroupRole.admin;
    case 'manager':
      return QuestionnaireGroupRole.manager;
    case 'user':
    default:
      return QuestionnaireGroupRole.user;
  }
}

String questionnaireGroupNicknameModeToFirestore(
  QuestionnaireGroupNicknameMode mode,
) {
  switch (mode) {
    case QuestionnaireGroupNicknameMode.selfNamed:
      return 'self_named';
    case QuestionnaireGroupNicknameMode.adminAssigned:
      return 'admin_assigned';
  }
}

QuestionnaireGroupNicknameMode parseQuestionnaireGroupNicknameMode(
  String? value,
) {
  switch (value) {
    case 'admin_assigned':
      return QuestionnaireGroupNicknameMode.adminAssigned;
    case 'self_named':
    default:
      return QuestionnaireGroupNicknameMode.selfNamed;
  }
}

String questionnaireGroupAccessModeToFirestore(
  QuestionnaireGroupAccessMode mode,
) {
  switch (mode) {
    case QuestionnaireGroupAccessMode.private:
      return 'private';
    case QuestionnaireGroupAccessMode.protected:
      return 'protected';
    case QuestionnaireGroupAccessMode.open:
      return 'open';
  }
}

QuestionnaireGroupAccessMode parseQuestionnaireGroupAccessMode(String? value) {
  switch (value) {
    case 'protected':
      return QuestionnaireGroupAccessMode.protected;
    case 'open':
      return QuestionnaireGroupAccessMode.open;
    case 'private':
    default:
      return QuestionnaireGroupAccessMode.private;
  }
}

String questionnaireGroupAccessNotificationTypeToFirestore(
  QuestionnaireGroupAccessNotificationType type,
) {
  switch (type) {
    case QuestionnaireGroupAccessNotificationType.invite:
      return 'invite';
    case QuestionnaireGroupAccessNotificationType.request:
      return 'request';
    case QuestionnaireGroupAccessNotificationType.removed:
      return 'removed';
  }
}

QuestionnaireGroupAccessNotificationType
parseQuestionnaireGroupAccessNotificationType(String? value) {
  switch (value) {
    case 'removed':
      return QuestionnaireGroupAccessNotificationType.removed;
    case 'request':
      return QuestionnaireGroupAccessNotificationType.request;
    case 'invite':
    default:
      return QuestionnaireGroupAccessNotificationType.invite;
  }
}

String questionnaireGroupAccessNotificationStatusToFirestore(
  QuestionnaireGroupAccessNotificationStatus status,
) {
  switch (status) {
    case QuestionnaireGroupAccessNotificationStatus.pending:
      return 'pending';
    case QuestionnaireGroupAccessNotificationStatus.accepted:
      return 'accepted';
    case QuestionnaireGroupAccessNotificationStatus.denied:
      return 'denied';
  }
}

QuestionnaireGroupAccessNotificationStatus
parseQuestionnaireGroupAccessNotificationStatus(String? value) {
  switch (value) {
    case 'accepted':
      return QuestionnaireGroupAccessNotificationStatus.accepted;
    case 'denied':
      return QuestionnaireGroupAccessNotificationStatus.denied;
    case 'pending':
    default:
      return QuestionnaireGroupAccessNotificationStatus.pending;
  }
}

String questionnaireGroupInvitationStatusToFirestore(
  QuestionnaireGroupInvitationStatus status,
) {
  return switch (status) {
    QuestionnaireGroupInvitationStatus.pending => 'pending',
    QuestionnaireGroupInvitationStatus.accepted => 'accepted',
    QuestionnaireGroupInvitationStatus.declined => 'declined',
    QuestionnaireGroupInvitationStatus.removed => 'removed',
  };
}

QuestionnaireGroupInvitationStatus parseQuestionnaireGroupInvitationStatus(
  String? value,
) {
  return switch (value) {
    'accepted' => QuestionnaireGroupInvitationStatus.accepted,
    'declined' || 'denied' => QuestionnaireGroupInvitationStatus.declined,
    'removed' => QuestionnaireGroupInvitationStatus.removed,
    _ => QuestionnaireGroupInvitationStatus.pending,
  };
}

class QuestionnaireGroup {
  final String id;
  final String name;
  final String? profilePictureUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String joinCode;
  final QuestionnaireGroupNicknameMode nicknameMode;
  final bool managersCanInvite;
  final List<String> memberIds;
  final int importedMemberCount;
  final bool isActive;
  final QuestionnaireGroupAccessMode accessMode;
  final bool inviteLinkEnabled;
  final bool adminElectionOpen;
  final DateTime? adminElectionEndsAt;

  const QuestionnaireGroup({
    required this.id,
    required this.name,
    this.profilePictureUrl,
    required this.createdBy,
    required this.createdAt,
    required this.joinCode,
    required this.nicknameMode,
    required this.managersCanInvite,
    required this.memberIds,
    required this.importedMemberCount,
    this.expiresAt,
    this.isActive = true,
    this.accessMode = QuestionnaireGroupAccessMode.private,
    this.inviteLinkEnabled = false,
    this.adminElectionOpen = false,
    this.adminElectionEndsAt,
  });

  QuestionnaireGroup copyWith({
    String? id,
    String? name,
    Object? profilePictureUrl = _unset,
    String? createdBy,
    DateTime? createdAt,
    Object? expiresAt = _unset,
    String? joinCode,
    QuestionnaireGroupNicknameMode? nicknameMode,
    bool? managersCanInvite,
    List<String>? memberIds,
    int? importedMemberCount,
    bool? isActive,
    QuestionnaireGroupAccessMode? accessMode,
    bool? inviteLinkEnabled,
    bool? adminElectionOpen,
    Object? adminElectionEndsAt = _unset,
  }) {
    return QuestionnaireGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      profilePictureUrl: identical(profilePictureUrl, _unset)
          ? this.profilePictureUrl
          : profilePictureUrl as String?,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: identical(expiresAt, _unset)
          ? this.expiresAt
          : expiresAt as DateTime?,
      joinCode: joinCode ?? this.joinCode,
      nicknameMode: nicknameMode ?? this.nicknameMode,
      managersCanInvite: managersCanInvite ?? this.managersCanInvite,
      memberIds: memberIds ?? this.memberIds,
      importedMemberCount: importedMemberCount ?? this.importedMemberCount,
      isActive: isActive ?? this.isActive,
      accessMode: accessMode ?? this.accessMode,
      inviteLinkEnabled: inviteLinkEnabled ?? this.inviteLinkEnabled,
      adminElectionOpen: adminElectionOpen ?? this.adminElectionOpen,
      adminElectionEndsAt: identical(adminElectionEndsAt, _unset)
          ? this.adminElectionEndsAt
          : adminElectionEndsAt as DateTime?,
    );
  }

  static QuestionnaireGroup fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return QuestionnaireGroup(
      id: snap.id,
      name: (data['name'] ?? '') as String,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      createdBy: (data['createdBy'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      joinCode: (data['joinCode'] ?? '') as String,
      nicknameMode: parseQuestionnaireGroupNicknameMode(
        data['nicknameMode'] as String?,
      ),
      managersCanInvite: data['managersCanInvite'] as bool? ?? false,
      memberIds: (data['memberIds'] as List?)?.cast<String>() ?? const [],
      importedMemberCount: data['importedMemberCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      accessMode: parseQuestionnaireGroupAccessMode(
        data['accessMode'] as String? ??
            ((data['isPrivate'] as bool? ?? true) ? 'private' : 'open'),
      ),
      inviteLinkEnabled: data['inviteLinkEnabled'] as bool? ?? false,
      adminElectionOpen: data['adminElectionStatus'] == 'open',
      adminElectionEndsAt: (data['adminElectionEndsAt'] as Timestamp?)
          ?.toDate(),
    );
  }

  static Map<String, Object?> toFirestore(
    QuestionnaireGroup group,
    SetOptions? _,
  ) {
    return {
      'name': group.name,
      'profilePictureUrl': group.profilePictureUrl,
      'createdBy': group.createdBy,
      'createdAt': Timestamp.fromDate(group.createdAt),
      'expiresAt': group.expiresAt != null
          ? Timestamp.fromDate(group.expiresAt!)
          : null,
      'joinCode': group.joinCode,
      'nicknameMode': questionnaireGroupNicknameModeToFirestore(
        group.nicknameMode,
      ),
      'managersCanInvite': group.managersCanInvite,
      'memberIds': group.memberIds,
      'importedMemberCount': group.importedMemberCount,
      'isActive': group.isActive,
      'accessMode': questionnaireGroupAccessModeToFirestore(group.accessMode),
      'inviteLinkEnabled': group.inviteLinkEnabled,
      'adminElectionStatus': group.adminElectionOpen ? 'open' : null,
      'adminElectionEndsAt': group.adminElectionEndsAt == null
          ? null
          : Timestamp.fromDate(group.adminElectionEndsAt!),
      'nameLowercase': group.name.toLowerCase(),
    };
  }
}

class QuestionnaireGroupAdminElection {
  final String id;
  final String status;
  final DateTime startedAt;
  final DateTime endsAt;
  final String initiatedBy;
  final List<String> candidateUids;
  final String? winnerUid;

  const QuestionnaireGroupAdminElection({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.endsAt,
    required this.initiatedBy,
    required this.candidateUids,
    this.winnerUid,
  });

  bool get isOpen => status == 'open';

  static QuestionnaireGroupAdminElection fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return QuestionnaireGroupAdminElection(
      id: snap.id,
      status: data['status'] as String? ?? 'open',
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      initiatedBy: data['initiatedBy'] as String? ?? '',
      candidateUids:
          (data['candidateUids'] as List?)?.cast<String>() ?? const [],
      winnerUid: data['winnerUid'] as String?,
    );
  }

  static Map<String, Object?> toFirestore(
    QuestionnaireGroupAdminElection election,
    SetOptions? _,
  ) {
    return {
      'status': election.status,
      'startedAt': Timestamp.fromDate(election.startedAt),
      'endsAt': Timestamp.fromDate(election.endsAt),
      'initiatedBy': election.initiatedBy,
      'candidateUids': election.candidateUids,
      'winnerUid': election.winnerUid,
    };
  }
}

class QuestionnaireGroupAdminElectionVote {
  final String voterUid;
  final String candidateUid;
  final DateTime castAt;

  const QuestionnaireGroupAdminElectionVote({
    required this.voterUid,
    required this.candidateUid,
    required this.castAt,
  });

  static QuestionnaireGroupAdminElectionVote fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return QuestionnaireGroupAdminElectionVote(
      voterUid: data['voterUid'] as String? ?? snap.id,
      candidateUid: data['candidateUid'] as String? ?? '',
      castAt: (data['castAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, Object?> toFirestore(
    QuestionnaireGroupAdminElectionVote vote,
    SetOptions? _,
  ) {
    return {
      'voterUid': vote.voterUid,
      'candidateUid': vote.candidateUid,
      'castAt': Timestamp.fromDate(vote.castAt),
    };
  }
}

class QuestionnaireGroupMember {
  final String uid;
  final QuestionnaireGroupRole role;
  final String? nickname;
  final DateTime joinedAt;
  final String joinedBy;

  const QuestionnaireGroupMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
    required this.joinedBy,
    this.nickname,
  });

  static QuestionnaireGroupMember fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return QuestionnaireGroupMember(
      uid: snap.id,
      role: parseQuestionnaireGroupRole(data['role'] as String?),
      nickname: data['nickname'] as String?,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      joinedBy: (data['joinedBy'] ?? '') as String,
    );
  }

  static Map<String, Object?> toFirestore(
    QuestionnaireGroupMember member,
    SetOptions? _,
  ) {
    return {
      'role': questionnaireGroupRoleToFirestore(member.role),
      'nickname': member.nickname,
      'joinedAt': Timestamp.fromDate(member.joinedAt),
      'joinedBy': member.joinedBy,
    };
  }
}

class QuestionnaireGroupInvitation {
  final String recipientUid;
  final String email;
  final String? displayName;
  final QuestionnaireGroupRole role;
  final QuestionnaireGroupInvitationStatus status;
  final DateTime invitedAt;
  final String invitedBy;
  final DateTime? resolvedAt;

  const QuestionnaireGroupInvitation({
    required this.recipientUid,
    required this.email,
    required this.role,
    required this.status,
    required this.invitedAt,
    required this.invitedBy,
    this.displayName,
    this.resolvedAt,
  });

  QuestionnaireGroupInvitation copyWith({
    QuestionnaireGroupInvitationStatus? status,
    Object? resolvedAt = _unset,
  }) {
    return QuestionnaireGroupInvitation(
      recipientUid: recipientUid,
      email: email,
      displayName: displayName,
      role: role,
      status: status ?? this.status,
      invitedAt: invitedAt,
      invitedBy: invitedBy,
      resolvedAt: identical(resolvedAt, _unset)
          ? this.resolvedAt
          : resolvedAt as DateTime?,
    );
  }

  static QuestionnaireGroupInvitation fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return QuestionnaireGroupInvitation(
      recipientUid: (data['recipientUid'] ?? snap.id) as String,
      email: (data['email'] ?? '') as String,
      displayName: data['displayName'] as String?,
      role: parseQuestionnaireGroupRole(data['role'] as String?),
      status: parseQuestionnaireGroupInvitationStatus(
        data['status'] as String?,
      ),
      invitedAt: (data['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedBy: (data['invitedBy'] ?? '') as String,
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, Object?> toFirestore(
    QuestionnaireGroupInvitation invitation,
    SetOptions? _,
  ) {
    return {
      'recipientUid': invitation.recipientUid,
      'email': invitation.email,
      'displayName': invitation.displayName,
      'role': questionnaireGroupRoleToFirestore(invitation.role),
      'status': questionnaireGroupInvitationStatusToFirestore(
        invitation.status,
      ),
      'invitedAt': Timestamp.fromDate(invitation.invitedAt),
      'invitedBy': invitation.invitedBy,
      'resolvedAt': invitation.resolvedAt == null
          ? null
          : Timestamp.fromDate(invitation.resolvedAt!),
    };
  }
}

class QuestionnaireGroupAllowedMember {
  final String email;
  final String? nickname;
  final QuestionnaireGroupRole role;
  final DateTime createdAt;
  final String createdBy;

  const QuestionnaireGroupAllowedMember({
    required this.email,
    required this.role,
    required this.createdAt,
    required this.createdBy,
    this.nickname,
  });

  static QuestionnaireGroupAllowedMember fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return QuestionnaireGroupAllowedMember(
      email: (data['email'] ?? snap.id) as String,
      nickname: data['nickname'] as String?,
      role: parseQuestionnaireGroupRole(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  static Map<String, Object?> toFirestore(
    QuestionnaireGroupAllowedMember member,
    SetOptions? _,
  ) {
    return {
      'email': member.email,
      'emailLowercase': member.email.toLowerCase(),
      'nickname': member.nickname,
      'role': questionnaireGroupRoleToFirestore(member.role),
      'createdAt': Timestamp.fromDate(member.createdAt),
      'createdBy': member.createdBy,
    };
  }
}

class QuestionnaireGroupAllowedDomain {
  final String domain;
  final QuestionnaireGroupRole role;
  final DateTime createdAt;
  final String createdBy;

  const QuestionnaireGroupAllowedDomain({
    required this.domain,
    required this.role,
    required this.createdAt,
    required this.createdBy,
  });

  static QuestionnaireGroupAllowedDomain fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return QuestionnaireGroupAllowedDomain(
      domain: (data['domain'] ?? snap.id) as String,
      role: parseQuestionnaireGroupRole(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  static Map<String, Object?> toFirestore(
    QuestionnaireGroupAllowedDomain domain,
    SetOptions? _,
  ) {
    return {
      'domain': domain.domain,
      'role': questionnaireGroupRoleToFirestore(domain.role),
      'createdAt': Timestamp.fromDate(domain.createdAt),
      'createdBy': domain.createdBy,
    };
  }
}

class QuestionnaireGroupAccessNotification {
  final String id;
  final String groupId;
  final String groupName;
  final String actorUid;
  final String actorDisplayName;
  final String recipientUid;
  final QuestionnaireGroupRole role;
  final QuestionnaireGroupAccessMode accessMode;
  final QuestionnaireGroupAccessNotificationType type;
  final QuestionnaireGroupAccessNotificationStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime? readAt;

  bool get countsAsUnread =>
      status == QuestionnaireGroupAccessNotificationStatus.pending ||
      (type == QuestionnaireGroupAccessNotificationType.removed &&
          readAt == null);

  const QuestionnaireGroupAccessNotification({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.actorUid,
    required this.actorDisplayName,
    required this.recipientUid,
    required this.role,
    required this.accessMode,
    required this.type,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.readAt,
  });

  QuestionnaireGroupAccessNotification copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? actorUid,
    String? actorDisplayName,
    String? recipientUid,
    QuestionnaireGroupRole? role,
    QuestionnaireGroupAccessMode? accessMode,
    QuestionnaireGroupAccessNotificationType? type,
    QuestionnaireGroupAccessNotificationStatus? status,
    DateTime? createdAt,
    Object? resolvedAt = _unset,
    Object? readAt = _unset,
  }) {
    return QuestionnaireGroupAccessNotification(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      actorUid: actorUid ?? this.actorUid,
      actorDisplayName: actorDisplayName ?? this.actorDisplayName,
      recipientUid: recipientUid ?? this.recipientUid,
      role: role ?? this.role,
      accessMode: accessMode ?? this.accessMode,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: identical(resolvedAt, _unset)
          ? this.resolvedAt
          : resolvedAt as DateTime?,
      readAt: identical(readAt, _unset) ? this.readAt : readAt as DateTime?,
    );
  }

  static QuestionnaireGroupAccessNotification fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return QuestionnaireGroupAccessNotification(
      id: snap.id,
      groupId: (data['groupId'] ?? '') as String,
      groupName: (data['groupName'] ?? '') as String,
      actorUid: (data['actorUid'] ?? '') as String,
      actorDisplayName: (data['actorDisplayName'] ?? '') as String,
      recipientUid: (data['recipientUid'] ?? '') as String,
      role: parseQuestionnaireGroupRole(data['role'] as String?),
      accessMode: parseQuestionnaireGroupAccessMode(
        data['accessMode'] as String?,
      ),
      type: parseQuestionnaireGroupAccessNotificationType(
        data['type'] as String?,
      ),
      status: parseQuestionnaireGroupAccessNotificationStatus(
        data['status'] as String?,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, Object?> toFirestore(
    QuestionnaireGroupAccessNotification notification,
    SetOptions? _,
  ) {
    return {
      'groupId': notification.groupId,
      'groupName': notification.groupName,
      'actorUid': notification.actorUid,
      'actorDisplayName': notification.actorDisplayName,
      'recipientUid': notification.recipientUid,
      'role': questionnaireGroupRoleToFirestore(notification.role),
      'accessMode': questionnaireGroupAccessModeToFirestore(
        notification.accessMode,
      ),
      'type': questionnaireGroupAccessNotificationTypeToFirestore(
        notification.type,
      ),
      'status': questionnaireGroupAccessNotificationStatusToFirestore(
        notification.status,
      ),
      'createdAt': Timestamp.fromDate(notification.createdAt),
      'resolvedAt': notification.resolvedAt != null
          ? Timestamp.fromDate(notification.resolvedAt!)
          : null,
      'readAt': notification.readAt != null
          ? Timestamp.fromDate(notification.readAt!)
          : null,
    };
  }
}

const Object _unset = Object();
