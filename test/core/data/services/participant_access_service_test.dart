import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/participant_access_service.dart';

void main() {
  test('public pagination never substitutes private evaluator data', () async {
    final requests = <String>[];
    final service = ParticipantAccessService(
      request: (name, args) async {
        requests.add(name);
        expect(args['type'], 'petition');
        expect(args['formId'], 'form');
        final first = args['offset'] == 0;
        return {
          'entries': first
              ? [
                  {
                    'profile': {'uid': '', 'signAnonymously': true},
                  },
                ]
              : [
                  {
                    'profile': {'uid': 'public', 'displayName': 'Public'},
                  },
                ],
          'nextOffset': first ? 200 : null,
        };
      },
    );
    final rows = await service.fetch('petition', 'form');
    final anonymous = rows.first['profile'] as UserProfile;
    expect(anonymous.uid, isEmpty);
    expect(anonymous.signAnonymously, isTrue);
    expect(anonymous.email, isNull);
    expect(requests, ['getPublicParticipants', 'getPublicParticipants']);
  });
  test(
    'private exports use evaluator endpoint and decode timestamps',
    () async {
      final service = ParticipantAccessService(
        request: (name, args) async {
          expect(name, 'getParticipantResults');
          return {
            'entries': [
              {
                'profile': {
                  'uid': 'private',
                  'signAnonymously': true,
                  'email': 'private@example.com',
                  'dateOfBirth': {'timestampMillis': 946684800000},
                },
                'reason': 'Private reason',
              },
            ],
            'nextOffset': null,
          };
        },
      );
      final rows = await service.fetch('petition', 'form', evaluator: true);
      final profile = rows.single['profile'] as UserProfile;
      expect(profile.email, 'private@example.com');
      expect(
        profile.dateOfBirth,
        DateTime.fromMillisecondsSinceEpoch(946684800000),
      );
      expect(rows.single['reason'], 'Private reason');
    },
  );
  test(
    'authorization failures propagate without a raw-data fallback',
    () async {
      final service = ParticipantAccessService(
        request: (_, _) async {
          throw StateError('permission-denied');
        },
      );
      await expectLater(
        service.fetch('petition', 'form', evaluator: true),
        throwsStateError,
      );
    },
  );
}
