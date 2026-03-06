import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/home_item.dart';

class Petition implements HomeItem {
  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final List<String> tags;
  final int signatureCount;
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
  final String? imageUrl;

  Petition({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.signatureCount,
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
    this.imageUrl,
  }) : stateOrRegion = stateOrRegion ?? state;

  @override
  String? get state => stateOrRegion;

  @override
  int get participantCount => signatureCount;

  Petition copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    int? signatureCount,
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
    String? imageUrl,
  }) {
    return Petition(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      signatureCount: signatureCount ?? this.signatureCount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      scopeType: scopeType ?? this.scopeType,
      continentCode: continentCode ?? this.continentCode,
      countryCode: countryCode ?? this.countryCode,
      stateOrRegion: stateOrRegion ?? state ?? this.stateOrRegion,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static Petition fromFirestore(
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

    return Petition(
      id: snap.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      tags: (data['tags'] as List?)?.cast<String>() ?? const [],
      signatureCount: (data['signatureCount'] ?? 0) as int,
      createdBy: (data['createdBy'] ?? '') as String,
      createdAt: createdAt,
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ??
          createdAt.add(const Duration(days: 28)),
      status: (data['status'] ?? IConst.active) as String,
      scopeType: scopeType,
      continentCode: data['continentCode'] as String?,
      countryCode: countryCode,
      stateOrRegion: stateOrRegion,
      city: city,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  static Map<String, Object?> toFirestore(Petition p, SetOptions? _) {
    return {
      'title': p.title,
      'description': p.description,
      'tags': p.tags,
      'signatureCount': p.signatureCount,
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
      'imageUrl': p.imageUrl,
    };
  }
}
