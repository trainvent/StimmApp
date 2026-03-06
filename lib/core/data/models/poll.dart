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
  final String? city;

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
    String? stateOrRegion,
    @Deprecated('Use stateOrRegion') String? state,
    this.city,
  }) : stateOrRegion = stateOrRegion ?? state;

  @override
  String? get state => stateOrRegion;

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
    String? stateOrRegion,
    @Deprecated('Use stateOrRegion') String? state,
    String? city,
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
      stateOrRegion: stateOrRegion ?? state ?? this.stateOrRegion,
      city: city ?? this.city,
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
    final city = data['city'] as String?;
    final scopeType = rawScopeType != null && rawScopeType.isNotEmpty
        ? formScopeTypeToFirestore(parseFormScopeType(rawScopeType))
        : (stateOrRegion != null && stateOrRegion.isNotEmpty
              ? formScopeTypeToFirestore(FormScopeType.stateOrRegion)
              : (countryCode != null && countryCode.isNotEmpty
                    ? formScopeTypeToFirestore(FormScopeType.country)
                    : formScopeTypeToFirestore(FormScopeType.global)));

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
      stateOrRegion: stateOrRegion,
      city: city,
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
      'stateOrRegion': p.stateOrRegion,
      // Legacy compatibility for clients still reading `state`.
      'state': p.stateOrRegion,
      'city': p.city,
    };
  }
}
