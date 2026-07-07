import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/services/file_output/export_content_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_writer.dart';

class AccountDataExportService {
  AccountDataExportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ExportFileWriter? writer,
  }) : _firestore = firestore ?? locator.database,
       _auth = auth ?? locator.auth,
       _writer = writer ?? ExportFileWriter(locator.databaseService);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ExportFileWriter _writer;
  final ExportContentService _jsonService = const _RawJsonExportService();

  Future<String> saveCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('not_authenticated');
    }

    final data = await _buildExport(user);
    final content = const JsonEncoder.withIndent('  ').convert(data);
    return _writer.save('stimmapp_account_data', content, _jsonService);
  }

  Future<Map<String, Object?>> _buildExport(User user) async {
    final uid = user.uid;
    final exportedAt = DateTime.now().toUtc().toIso8601String();

    final profileDoc = await _firestore
        .collection(DatabaseCollections.users)
        .doc(uid)
        .get();

    final results = await Future.wait([
      _createdCollection(DatabaseCollections.petitions, uid),
      _createdCollection(DatabaseCollections.polls, uid),
      _createdCollection(DatabaseCollections.surveys, uid),
      _createdCollection(DatabaseCollections.pollGroups, uid),
      _userSubcollection(uid, 'signedPetitions'),
      _userSubcollection(uid, 'votedPolls'),
      _userSubcollection(uid, 'completedSurveys'),
      _userSubcollection(uid, DatabaseCollections.blockedUsers),
      _userSubcollection(uid, DatabaseCollections.groupAccessNotifications),
      _userSubcollection(uid, 'dailyPublishing'),
    ]);

    return {
      'exportedAt': exportedAt,
      'scope':
          'Includes account metadata, profile, created publications, created groups, and user-owned participation/settings records. Does not include other users signatures, votes, or survey responses on your publications.',
      'auth': _authData(user),
      'profile': profileDoc.exists ? _documentData(profileDoc) : null,
      'createdPublications': {
        'petitions': results[0],
        'polls': results[1],
        'surveys': results[2],
      },
      'createdGroups': results[3],
      'participation': {
        'signedPetitions': results[4],
        'votedPolls': results[5],
        'completedSurveys': results[6],
      },
      'userCollections': {
        'blockedUsers': results[7],
        'groupAccessNotifications': results[8],
        'dailyPublishing': results[9],
      },
    };
  }

  Map<String, Object?> _authData(User user) {
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'phoneNumber': user.phoneNumber,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'creationTime': user.metadata.creationTime?.toUtc().toIso8601String(),
      'lastSignInTime': user.metadata.lastSignInTime?.toUtc().toIso8601String(),
      'providerIds': user.providerData
          .map((provider) => provider.providerId)
          .toList(growable: false),
    };
  }

  Future<List<Map<String, Object?>>> _createdCollection(
    String collection,
    String uid,
  ) async {
    final snap = await _firestore
        .collection(collection)
        .where('createdBy', isEqualTo: uid)
        .get();
    return snap.docs.map(_documentData).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _userSubcollection(
    String uid,
    String collection,
  ) async {
    final snap = await _firestore
        .collection(DatabaseCollections.users)
        .doc(uid)
        .collection(collection)
        .get();
    return snap.docs.map(_documentData).toList(growable: false);
  }

  Map<String, Object?> _documentData(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return {
      'id': doc.id,
      'path': doc.reference.path,
      ..._jsonSafeMap(doc.data() ?? const <String, dynamic>{}),
    };
  }

  Map<String, Object?> _jsonSafeMap(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _jsonSafeValue(value)));
  }

  Object? _jsonSafeValue(Object? value) {
    return switch (value) {
      Timestamp timestamp => timestamp.toDate().toUtc().toIso8601String(),
      DateTime dateTime => dateTime.toUtc().toIso8601String(),
      GeoPoint point => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      },
      DocumentReference reference => reference.path,
      Iterable<Object?> values => values.map(_jsonSafeValue).toList(),
      Map<Object?, Object?> map => map.map(
        (key, value) => MapEntry(key.toString(), _jsonSafeValue(value)),
      ),
      _ => value,
    };
  }
}

class _RawJsonExportService extends ExportContentService {
  const _RawJsonExportService();

  @override
  ExportFileFormat get format => ExportFileFormat.json;

  @override
  String build(_) {
    throw UnsupportedError('Raw JSON export is already serialized.');
  }
}
