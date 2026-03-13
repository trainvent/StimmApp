import 'package:cloud_firestore/cloud_firestore.dart';

enum PollGroupRole { admin, manager, user }

enum PollGroupNicknameMode { selfNamed, adminAssigned }

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
  }) {
    return PollGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: identical(expiresAt, _unset) ? this.expiresAt : expiresAt as DateTime?,
      joinCode: joinCode ?? this.joinCode,
      nicknameMode: nicknameMode ?? this.nicknameMode,
      managersCanInvite: managersCanInvite ?? this.managersCanInvite,
      memberIds: memberIds ?? this.memberIds,
      importedMemberCount: importedMemberCount ?? this.importedMemberCount,
      isActive: isActive ?? this.isActive,
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

const Object _unset = Object();
