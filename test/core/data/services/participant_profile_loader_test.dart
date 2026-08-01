import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_interface.dart';
import 'package:stimmapp/core/data/services/participant_profile_loader.dart';

class _FakeUsers implements UserInterface {
  _FakeUsers(this.read);

  final Future<UserProfile?> Function(String uid) read;

  @override
  Future<UserProfile?> getById(String uid) => read(uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('keeps successful profiles and marks a failed profile', () async {
    final reportedUids = <String>[];
    final loader = ParticipantProfileLoader(
      _FakeUsers((uid) async {
        if (uid == 'broken') throw StateError('malformed profile');
        return UserProfile(uid: uid, displayName: 'User $uid');
      }),
      reportError: (error, stackTrace, uid) => reportedUids.add(uid),
    );

    final profiles = await loader.load(['working', 'broken']);

    expect(profiles.map((profile) => profile.uid), ['working', 'broken']);
    expect(profiles.first.hasLoadError, isFalse);
    expect(profiles.last.hasLoadError, isTrue);
    expect(reportedUids, ['broken']);
  });

  test('times out a profile read instead of loading forever', () async {
    final neverCompletes = Completer<UserProfile?>();
    final reportedUids = <String>[];
    final loader = ParticipantProfileLoader(
      _FakeUsers((uid) => neverCompletes.future),
      profileLoadTimeout: const Duration(milliseconds: 5),
      reportError: (error, stackTrace, uid) => reportedUids.add(uid),
    );

    final profiles = await loader.load(['stuck']);

    expect(profiles.single, isA<UserProfile>());
    expect(profiles.single.hasLoadError, isTrue);
    expect(reportedUids, ['stuck']);
  });

  test('marks a missing profile as erroneous and reports it', () async {
    final reportedUids = <String>[];
    final loader = ParticipantProfileLoader(
      _FakeUsers((uid) async => null),
      reportError: (error, stackTrace, uid) => reportedUids.add(uid),
    );

    final profiles = await loader.load(['deleted-user']);

    expect(profiles.single.hasLoadError, isTrue);
    expect(reportedUids, ['deleted-user']);
  });
}
