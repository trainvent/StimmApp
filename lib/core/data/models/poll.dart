import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/home_item.dart';

class PollOption {
  final String id;
  final String label;
  const PollOption({required this.id, required this.label});

  factory PollOption.fromMap(Map<String, dynamic> m) =>
      PollOption(id: m['id'] as String, label: m['label'] as String);
  Map<String, dynamic> toMap() => {'id': id, 'label': label};
}

class Poll implements HomeItem {
  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final List<String> tags;
  final List<PollOption> options;
  final Map<String, int> votes; // optionId -> count
  @override
  final String createdBy;
  final DateTime createdAt;
  @override
  final DateTime expiresAt;
  @override
  final String status;
  @override
  final String scopeType;
  @override
  final String? continentCode;
  @override
  final String? countryCode;
  @override
  final String? stateOrRegion;
  @override
  final String? town;
  final String? groupId;
  final String? groupName;
  final String visibility;

  Poll({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.options,
    required this.votes,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.status = IConst.active,
    this.scopeType = 'global',
    this.continentCode,
    this.countryCode,
    this.groupId,
    this.groupName,
    this.visibility = 'public',
    String? stateOrRegion,
    @Deprecated('Use stateOrRegion') String? state,
    String? town,
    @Deprecated('Use town') String? city,
  }) : stateOrRegion = stateOrRegion ?? state,
       town = town ?? city;

  @override
  String? get state => stateOrRegion;

  @override
  String? get city => town;

  int get totalVotes => votes.values.fold(0, (a, b) => a + b);

  @override
  int get participantCount => totalVotes;

  Poll copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    List<PollOption>? options,
    Map<String, int>? votes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? status,
    String? scopeType,
    String? continentCode,
    String? countryCode,
    String? groupId,
    String? groupName,
    String? visibility,
    String? stateOrRegion,
    @Deprecated('Use stateOrRegion') String? state,
    String? town,
    @Deprecated('Use town') String? city,
  }) {
    return Poll(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      options: options ?? this.options,
      votes: votes ?? this.votes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      scopeType: scopeType ?? this.scopeType,
      continentCode: continentCode ?? this.continentCode,
      countryCode: countryCode ?? this.countryCode,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      visibility: visibility ?? this.visibility,
      stateOrRegion: stateOrRegion ?? state ?? this.stateOrRegion,
      town: town ?? city ?? this.town,
    );
  }

  static Poll fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data()!;
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final rawScopeType = data['scopeType'] as String?;
    final countryCode = (data['countryCode'] as String?)?.toUpperCase();
    final stateOrRegion =
        data['stateOrRegion'] as String? ?? data['state'] as String?;
    final town = data['town'] as String? ?? data['city'] as String?;
    final scopeType = rawScopeType != null && rawScopeType.isNotEmpty
        ? formScopeTypeToFirestore(parseFormScopeType(rawScopeType))
        : (town != null && town.isNotEmpty
              ? formScopeTypeToFirestore(FormScopeType.city)
              : (stateOrRegion != null && stateOrRegion.isNotEmpty
              ? formScopeTypeToFirestore(FormScopeType.stateOrRegion)
              : (countryCode != null && countryCode.isNotEmpty
                    ? formScopeTypeToFirestore(FormScopeType.country)
                    : formScopeTypeToFirestore(FormScopeType.global))));

    return Poll(
      id: snap.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      tags: (data['tags'] as List?)?.cast<String>() ?? const [],
      options:
          (data['options'] as List?)
              ?.map((e) => PollOption.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      votes: Map<String, int>.from(data['votes'] ?? const <String, int>{}),
      createdBy: (data['createdBy'] ?? '') as String,
      createdAt: createdAt,
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ??
          createdAt.add(const Duration(days: 7)),
      status: (data['status'] ?? IConst.active) as String,
      scopeType: scopeType,
      continentCode: data['continentCode'] as String?,
      countryCode: countryCode,
      groupId: data['groupId'] as String?,
      groupName: data['groupName'] as String?,
      visibility: (data['visibility'] ?? 'public') as String,
      stateOrRegion: stateOrRegion,
      town: town,
    );
  }

  static Map<String, Object?> toFirestore(Poll p, SetOptions? _) {
    return {
      'title': p.title,
      'description': p.description,
      'tags': p.tags,
      'options': p.options.map((o) => o.toMap()).toList(),
      'votes': p.votes,
      'createdBy': p.createdBy,
      'createdAt': Timestamp.fromDate(p.createdAt),
      'expiresAt': Timestamp.fromDate(p.expiresAt),
      'status': p.status,
      'titleLowercase': p.title.toLowerCase(),
      'scopeType': p.scopeType,
      'continentCode': p.continentCode,
      'countryCode': p.countryCode?.toUpperCase(),
      'groupId': p.groupId,
      'groupName': p.groupName,
      'visibility': p.visibility,
      'stateOrRegion': p.stateOrRegion,
      // Legacy compatibility for clients still reading `state`.
      'state': p.stateOrRegion,
      'town': p.town,
      'city': p.town,
    };
  }
}
