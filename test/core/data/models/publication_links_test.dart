import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/form_import.dart';
import 'package:stimmapp/core/data/models/form_template.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/publication_links.dart';
import 'package:stimmapp/core/data/models/survey.dart';

void main() {
  const links = PublicationLinks(
    youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ',
    websiteUrl: 'https://example.org/about',
  );

  test(
    'recognizes video URLs and rejects lookalike hosts and non-video pages',
    () {
      for (final url in [
        links.youtubeUrl!,
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=10',
        'https://m.youtube.com/shorts/dQw4w9WgXcQ',
        'https://youtube.com/live/dQw4w9WgXcQ',
      ]) {
        expect(PublicationLinks.youtubeUri(url), isNotNull, reason: url);
      }
      for (final url in [
        'https://youtube.com.evil.org/watch?v=dQw4w9WgXcQ',
        'https://youtube.com/@channel',
        'https://youtube.com/watch',
        'https://youtube.com/watch?v=invalid',
        'http://youtu.be/dQw4w9WgXcQ',
        'javascript:alert(1)',
      ]) {
        expect(PublicationLinks.youtubeUri(url), isNull, reason: url);
      }
    },
  );

  test('website links require HTTPS and reject credentials and whitespace', () {
    expect(
      PublicationLinks.websiteUri(' https://example.org/about '),
      isNotNull,
    );
    for (final url in [
      null,
      '',
      'example.org',
      'http://example.org',
      'https://user:password@example.org',
      'https://example.org/a b',
      'mailto:test@example.org',
      'https://',
    ]) {
      expect(PublicationLinks.websiteUri(url), isNull, reason: '$url');
    }
  });

  test('links survive Firestore reads, copies, and writes for all publication types', () async {
    final db = FakeFirebaseFirestore();
    final ref = db.collection('items').doc('item');
    await ref.set({
      'title': 'Supporting information',
      'description': 'Read the supporting information before participating.',
      'links': links.toJson(),
    });
    final snapshot = await ref.get();
    final petition = Petition.fromFirestore(
      snapshot,
      null,
    ).copyWith(title: 'Updated');
    final poll = Poll.fromFirestore(snapshot, null).copyWith(title: 'Updated');
    final survey = Survey.fromFirestore(
      snapshot,
      null,
    ).copyWith(title: 'Updated');
    for (final data in [
      Petition.toFirestore(petition, null),
      Poll.toFirestore(poll, null),
      Survey.toFirestore(survey, null),
    ]) {
      expect(data['links'], links.toJson());
    }
    expect(
      petition.copyWith(links: const PublicationLinks()).links.toJson(),
      isEmpty,
    );
  });

  test(
    'templates and portable imports retain links and validate destinations',
    () {
      final template = FormTemplate.fromJson(
        const FormTemplate(
          id: 'template',
          name: 'Example',
          links: links,
        ).toJson(),
      );
      expect(template.links!.toJson(), links.toJson());
      final portable = {
        'version': 1,
        'type': 'petition',
        'title': 'Supporting information',
        'description': 'Read the supporting information before participating.',
        'links': links.toJson(),
      };
      final imported = FormImport.parse(
        jsonEncode(portable),
        target: FormImportTarget.petition,
        allowedTags: {},
      );
      expect(imported.links!.toJson(), links.toJson());
      expect(
        () => FormImport.parse(
          jsonEncode({
            ...portable,
            'links': {'websiteUrl': 'javascript:alert(1)'},
          }),
          target: FormImportTarget.petition,
          allowedTags: {},
        ),
        throwsFormatException,
      );
      expect(FormTemplate.fromJson({'id': 'old', 'name': 'Old'}).links, isNull);
    },
  );
}
