import 'package:cloud_firestore/cloud_firestore.dart';

enum PollGroupRole { admin, manager, user }

enum PollGroupNicknameMode { selfNamed, adminAssigned }

enum PollGroupAccessMode { private, protected, open }

enum PollGroupAccessNotificationType { invite, request }

enum PollGroupAccessNotificationStatus { pending, accepted, denied }

String pollGroupRoleToFirestore(PollGroupRole role) {
  switch (role) {
    case PollGroupRole.admin:
      return 'admin';
    case PollGroupRole.manager:
      return 'manager';
    case PollGroupRole.user:
      return 'user';
  }
}

PollGroupRole parsePollGroupRole(String? value) {
  switch (value) {
    case 'admin':
      return PollGroupRole.admin;
    case 'manager':
      return PollGroupRole.manager;
    case 'user':
    default:
      return PollGroupRole.user;
  }
}

String pollGroupNicknameModeToFirestore(PollGroupNicknameMode mode) {
  switch (mode) {
    case PollGroupNicknameMode.selfNamed:
      return 'self_named';
    case PollGroupNicknameMode.adminAssigned:
      return 'admin_assigned';
  }
}

PollGroupNicknameMode parsePollGroupNicknameMode(String? value) {
  switch (value) {
    case 'admin_assigned':
      return PollGroupNicknameMode.adminAssigned;
    case 'self_named':
    default:
      return PollGroupNicknameMode.selfNamed;
  }
}

String pollGroupAccessModeToFirestore(PollGroupAccessMode mode) {
  switch (mode) {
    case PollGroupAccessMode.private:
      return 'private';
    case PollGroupAccessMode.protected:
      return 'protected';
    case PollGroupAccessMode.open:
      return 'open';
  }
}

PollGroupAccessMode parsePollGroupAccessMode(String? value) {
  switch (value) {
    case 'protected':
      return PollGroupAccessMode.protected;
    case 'open':
      return PollGroupAccessMode.open;
    case 'private':
    default:
      return PollGroupAccessMode.private;
  }
}

String pollGroupAccessNotificationTypeToFirestore(
  PollGroupAccessNotificationType type,
) {
  switch (type) {
    case PollGroupAccessNotificationType.invite:
      return 'invite';
    case PollGroupAccessNotificationType.request:
      return 'request';
  }
}

PollGroupAccessNotificationType parsePollGroupAccessNotificationType(
  String? value,
) {
  switch (value) {
    case 'request':
      return PollGroupAccessNotificationType.request;
    case 'invite':
    default:
      return PollGroupAccessNotificationType.invite;
  }
}

String pollGroupAccessNotificationStatusToFirestore(
  PollGroupAccessNotificationStatus status,
) {
  switch (status) {
    case PollGroupAccessNotificationStatus.pending:
      return 'pending';
    case PollGroupAccessNotificationStatus.accepted:
      return 'accepted';
    case PollGroupAccessNotificationStatus.denied:
      return 'denied';
  }
}

PollGroupAccessNotificationStatus parsePollGroupAccessNotificationStatus(
  String? value,
) {
  switch (value) {
    case 'accepted':
      return PollGroupAccessNotificationStatus.accepted;
    case 'denied':
      return PollGroupAccessNotificationStatus.denied;
    case 'pending':
    default:
      return PollGroupAccessNotificationStatus.pending;
  }
}

class PollGroup {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String joinCode;
  final PollGroupNicknameMode nicknameMode;
  final bool managersCanInvite;
  final List<String> memberIds;
  final int importedMemberCount;
  final bool isActive;
  final PollGroupAccessMode accessMode;
  final bool inviteLinkEnabled;

  const PollGroup({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.joinCode,
    required this.nicknameMode,
    required this.managersCanInvite,
    required this.memberIds,
    required this.importedMemberCount,
    this.expiresAt,
    this.isActive = true,
    this.accessMode = PollGroupAccessMode.private,
    this.inviteLinkEnabled = false,
  });

  PollGroup copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    Object? expiresAt = _unset,
    String? joinCode,
    PollGroupNicknameMode? nicknameMode,
    bool? managersCanInvite,
    List<String>? memberIds,
    int? importedMemberCount,
    bool? isActive,
    PollGroupAccessMode? accessMode,
    bool? inviteLinkEnabled,
  }) {
    return PollGroup(
      id: id ?? this.id,
      name: name ?? this.name,
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
    );
  }

  static PollGroup fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return PollGroup(
      id: snap.id,
      name: (data['name'] ?? '') as String,
      createdBy: (data['createdBy'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      joinCode: (data['joinCode'] ?? '') as String,
      nicknameMode: parsePollGroupNicknameMode(data['nicknameMode'] as String?),
      managersCanInvite: data['managersCanInvite'] as bool? ?? false,
      memberIds: (data['memberIds'] as List?)?.cast<String>() ?? const [],
      importedMemberCount: data['importedMemberCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      accessMode: parsePollGroupAccessMode(
        data['accessMode'] as String? ??
            ((data['isPrivate'] as bool? ?? true) ? 'private' : 'open'),
      ),
      inviteLinkEnabled: data['inviteLinkEnabled'] as bool? ?? false,
    );
  }

  static Map<String, Object?> toFirestore(PollGroup group, SetOptions? _) {
    return {
      'name': group.name,
      'createdBy': group.createdBy,
      'createdAt': Timestamp.fromDate(group.createdAt),
      'expiresAt': group.expiresAt != null
          ? Timestamp.fromDate(group.expiresAt!)
          : null,
      'joinCode': group.joinCode,
      'nicknameMode': pollGroupNicknameModeToFirestore(group.nicknameMode),
      'managersCanInvite': group.managersCanInvite,
      'memberIds': group.memberIds,
      'importedMemberCount': group.importedMemberCount,
      'isActive': group.isActive,
      'accessMode': pollGroupAccessModeToFirestore(group.accessMode),
      'inviteLinkEnabled': group.inviteLinkEnabled,
      'nameLowercase': group.name.toLowerCase(),
    };
  }
}

class PollGroupMember {
  final String uid;
  final PollGroupRole role;
  final String? nickname;
  final DateTime joinedAt;
  final String joinedBy;

  const PollGroupMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
    required this.joinedBy,
    this.nickname,
  });

  static PollGroupMember fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return PollGroupMember(
      uid: snap.id,
      role: parsePollGroupRole(data['role'] as String?),
      nickname: data['nickname'] as String?,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      joinedBy: (data['joinedBy'] ?? '') as String,
    );
  }

  static Map<String, Object?> toFirestore(
    PollGroupMember member,
    SetOptions? _,
  ) {
    return {
      'role': pollGroupRoleToFirestore(member.role),
      'nickname': member.nickname,
      'joinedAt': Timestamp.fromDate(member.joinedAt),
      'joinedBy': member.joinedBy,
    };
  }
}

class PollGroupAllowedMember {
  final String email;
  final String? nickname;
  final PollGroupRole role;
  final DateTime createdAt;
  final String createdBy;

  const PollGroupAllowedMember({
    required this.email,
    required this.role,
    required this.createdAt,
    required this.createdBy,
    this.nickname,
  });

  static PollGroupAllowedMember fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return PollGroupAllowedMember(
      email: (data['email'] ?? snap.id) as String,
      nickname: data['nickname'] as String?,
      role: parsePollGroupRole(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  static Map<String, Object?> toFirestore(
    PollGroupAllowedMember member,
    SetOptions? _,
  ) {
    return {
      'email': member.email,
      'emailLowercase': member.email.toLowerCase(),
      'nickname': member.nickname,
      'role': pollGroupRoleToFirestore(member.role),
      'createdAt': Timestamp.fromDate(member.createdAt),
      'createdBy': member.createdBy,
    };
  }
}

class PollGroupAllowedDomain {
  final String domain;
  final PollGroupRole role;
  final DateTime createdAt;
  final String createdBy;

  const PollGroupAllowedDomain({
    required this.domain,
    required this.role,
    required this.createdAt,
    required this.createdBy,
  });

  static PollGroupAllowedDomain fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return PollGroupAllowedDomain(
      domain: (data['domain'] ?? snap.id) as String,
      role: parsePollGroupRole(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  static Map<String, Object?> toFirestore(
    PollGroupAllowedDomain domain,
    SetOptions? _,
  ) {
    return {
      'domain': domain.domain,
      'role': pollGroupRoleToFirestore(domain.role),
      'createdAt': Timestamp.fromDate(domain.createdAt),
      'createdBy': domain.createdBy,
    };
  }
}

class PollGroupAccessNotification {
  final String id;
  final String groupId;
  final String groupName;
  final String actorUid;
  final String actorDisplayName;
  final String recipientUid;
  final PollGroupRole role;
  final PollGroupAccessMode accessMode;
  final PollGroupAccessNotificationType type;
  final PollGroupAccessNotificationStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const PollGroupAccessNotification({
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
  });

  PollGroupAccessNotification copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? actorUid,
    String? actorDisplayName,
    String? recipientUid,
    PollGroupRole? role,
    PollGroupAccessMode? accessMode,
    PollGroupAccessNotificationType? type,
    PollGroupAccessNotificationStatus? status,
    DateTime? createdAt,
    Object? resolvedAt = _unset,
  }) {
    return PollGroupAccessNotification(
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
    );
  }

  static PollGroupAccessNotification fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return PollGroupAccessNotification(
      id: snap.id,
      groupId: (data['groupId'] ?? '') as String,
      groupName: (data['groupName'] ?? '') as String,
      actorUid: (data['actorUid'] ?? '') as String,
      actorDisplayName: (data['actorDisplayName'] ?? '') as String,
      recipientUid: (data['recipientUid'] ?? '') as String,
      role: parsePollGroupRole(data['role'] as String?),
      accessMode: parsePollGroupAccessMode(data['accessMode'] as String?),
      type: parsePollGroupAccessNotificationType(data['type'] as String?),
      status: parsePollGroupAccessNotificationStatus(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, Object?> toFirestore(
    PollGroupAccessNotification notification,
    SetOptions? _,
  ) {
    return {
      'groupId': notification.groupId,
      'groupName': notification.groupName,
      'actorUid': notification.actorUid,
      'actorDisplayName': notification.actorDisplayName,
      'recipientUid': notification.recipientUid,
      'role': pollGroupRoleToFirestore(notification.role),
      'accessMode': pollGroupAccessModeToFirestore(notification.accessMode),
      'type': pollGroupAccessNotificationTypeToFirestore(notification.type),
      'status': pollGroupAccessNotificationStatusToFirestore(
        notification.status,
      ),
      'createdAt': Timestamp.fromDate(notification.createdAt),
      'resolvedAt': notification.resolvedAt != null
          ? Timestamp.fromDate(notification.resolvedAt!)
          : null,
    };
  }
}

const Object _unset = Object();
