import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

typedef PrivacyRequest = Future<dynamic> Function(
  String name,
  Map<String, dynamic> arguments,
);

/// Private identities never enter the public participant stream.
class ParticipantAccessService {
  ParticipantAccessService({PrivacyRequest? request})
    : _request = request ?? _call;

  final PrivacyRequest _request;

  static Future<dynamic> _call(
    String name,
    Map<String, dynamic> arguments,
  ) async =>
      (await FirebaseFunctions.instance.httpsCallable(name).call(arguments))
          .data;

  static dynamic _decode(dynamic value) {
    if (value is Map) {
      if (value.length == 1 && value['timestampMillis'] is num) {
        return Timestamp.fromMillisecondsSinceEpoch(
          (value['timestampMillis'] as num).toInt(),
        );
      }
      return value.map(
        (key, field) => MapEntry(key.toString(), _decode(field)),
      );
    }
    if (value is List) return value.map(_decode).toList();
    return value;
  }

  Future<List<Map<String, dynamic>>> fetch(
    String type,
    String formId, {
    bool evaluator = false,
  }) async {
    final entries = <Map<String, dynamic>>[];
    int? offset = 0;
    while (offset != null) {
      final result = Map<String, dynamic>.from(
        await _request(
          evaluator ? 'getParticipantResults' : 'getPublicParticipants',
          {'type': type, 'formId': formId, 'offset': offset},
        ) as Map,
      );
      for (final raw in result['entries'] as List) {
        final entry = Map<String, dynamic>.from(_decode(raw) as Map);
        final profile = Map<String, dynamic>.from(entry['profile'] as Map);
        entries.add({
          ...entry,
          'profile': UserProfile.fromJson(profile, profile['uid'] as String),
        });
      }
      offset = result['nextOffset'] as int?;
    }
    return entries;
  }

  /// Refresh only while subscribed; never cache a private identity in public data.
  Stream<T> _watch<T>(Future<T> Function() fetch) {
    Timer? timer;
    var loading = false;
    late StreamController<T> controller;
    Future<void> refresh() async {
      if (loading) return;
      loading = true;
      try {
        final data = await fetch();
        if (controller.hasListener) controller.add(data);
      } catch (error, stack) {
        if (controller.hasListener) controller.addError(error, stack);
      } finally {
        loading = false;
      }
    }

    controller = StreamController<T>.broadcast(
      onListen: () {
        refresh();
        timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );
    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> watch(String type, String formId) =>
      _watch(() => fetch(type, formId));

  Stream<UserProfile?> watchPublicProfile(String uid) =>
      _watch(() => publicProfile(uid));

  Future<UserProfile?> publicProfile(String uid) async {
    final data = await _request('getPublicProfile', {'uid': uid});
    return data == null
        ? null
        : UserProfile.fromJson(Map<String, dynamic>.from(data as Map), uid);
  }
}
