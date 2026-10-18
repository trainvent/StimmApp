import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/data/services/participant_access_service.dart';

ParticipantAccessService fakeParticipantAccess(
  FakeFirebaseFirestore db,
) => ParticipantAccessService(
  request: (name, args) async {
    if (name == 'getPublicProfile') {
      final data =
          (await db.collection('users').doc(args['uid'] as String).get())
              .data();
      return data == null
          ? null
          : {
              'uid': args['uid'],
              'displayName': data['displayName'],
              'profilePictureUrl': data['profilePictureUrl'],
              if (data['publicProfileShowLink'] == true)
                'websiteUrl': data['websiteUrl'],
              if (data['publicProfileShowFullName'] == true) ...{
                'givenName': data['givenName'],
                'surname': data['surname'],
              },
              if (data['publicProfileShowAddress'] == true)
                'address': data['address'],
              'hidePublications': data['hidePublications'] == true,
            };
    }
    final type = args['type'] as String;
    final collection = {
      'petition': 'signatures',
      'poll': 'votes',
      'survey': 'responses',
    }[type]!;
    final records = await db
        .collection('${type}s')
        .doc(args['formId'] as String)
        .collection(collection)
        .get();
    return {
      'entries': [
        for (final doc in records.docs)
          {
            'profile': {
              'uid': doc.id,
              ...(await db.collection('users').doc(doc.id).get()).data() ?? {},
            },
            ...doc.data(),
            if (doc.data()['signedAt'] is Timestamp)
              'signedAt':
                  (doc.data()['signedAt'] as Timestamp).millisecondsSinceEpoch,
          },
      ],
      'nextOffset': null,
    };
  },
);
