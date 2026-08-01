import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_interface.dart';
import 'package:stimmapp/core/services/crash_reporting_service.dart';

typedef ParticipantProfileErrorReporter =
    void Function(Object error, StackTrace stackTrace, String uid);

class ParticipantProfileLoader {
  ParticipantProfileLoader(
    this._users, {
    ParticipantProfileErrorReporter? reportError,
    this.profileLoadTimeout = const Duration(seconds: 10),
  }) : _reportError = reportError ?? _reportParticipantProfileError;

  final UserInterface _users;
  final ParticipantProfileErrorReporter _reportError;
  final Duration profileLoadTimeout;

  Future<List<UserProfile>> load(Iterable<String> uids) {
    return Future.wait(uids.map(_loadOne));
  }

  Future<UserProfile> _loadOne(String uid) async {
    try {
      final profile = await _users.getById(uid).timeout(profileLoadTimeout);
      if (profile == null) {
        throw StateError('Participant profile does not exist');
      }
      return profile;
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, uid);
      return UserProfile.erroneous(uid);
    }
  }

  static void _reportParticipantProfileError(
    Object error,
    StackTrace stackTrace,
    String uid,
  ) {
    debugPrint(
      '[ParticipantProfileLoader] Failed to load participant profile '
      'uid=$uid: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
    unawaited(
      CrashReportingService.instance.recordNonFatal(
        error,
        stackTrace,
        reason: 'Failed to load participant profile uid=$uid',
      ),
    );
  }
}
