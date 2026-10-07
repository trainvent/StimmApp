import 'package:cloud_firestore/cloud_firestore.dart';

/// Only the fields shown on another person's profile card.
class PublicProfile {
  const PublicProfile({required this.uid, this.nickname, this.imageUrl});
  final String uid;
  final String? nickname;
  final String? imageUrl;

  factory PublicProfile.fromMap(String uid, Map<String, dynamic> data) =>
      PublicProfile(
        uid: uid,
        nickname: data['displayName'] as String?,
        imageUrl: data['profilePictureUrl'] as String?,
      );
}

class PublicProfileForm {
  const PublicProfileForm({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
  });
  final String id;
  final String type;
  final String title;
  final DateTime createdAt;
  String get route => '/$type/$id';

  factory PublicProfileForm.fromDocument(
    String type,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) => PublicProfileForm(
    id: doc.id,
    type: type,
    title: doc.data()['title'] as String? ?? '',
    createdAt:
        (doc.data()['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
