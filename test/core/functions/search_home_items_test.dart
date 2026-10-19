import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/functions/search_home_items.dart';

Petition item(
  String id,
  String title, {
  String description = '',
  List<String> tags = const [],
}) => Petition(
  id: id,
  title: title,
  description: description,
  tags: tags,
  createdBy: 'author',
  createdAt: DateTime(2026),
  signatureCount: 0,
);

void main() {
  test('matches substrings, all words, and words across fields', () {
    final form = item(
      '1',
      'Zufriedenheitsumfrage Arbeitsplatz',
      description: 'Bessere Bedingungen',
      tags: ['Beruf'],
    );
    for (final query in [
      'ARBEITSPLATZ',
      'platz',
      '  Arbeitsplatz   zufrieden  ',
      'Beruf Bedingungen',
    ]) {
      expect(searchHomeItems([form], query), [form]);
    }
    expect(searchHomeItems([form], 'Arbeitsplatz Schule'), isEmpty);
  });

  test('normalizes German spellings and decomposed umlauts', () {
    final form = item('1', 'Grüne Straßen für Köln und Äpfel');
    for (final query in [
      'gruene strassen koeln aepfel',
      'grune straßen koln apfel',
      'gru\u0308ne',
    ]) {
      expect(searchHomeItems([form], query), [form]);
    }
  });

  test('treats regex characters literally', () {
    final form = item('1', 'Budget [2026] (a+b)');
    expect(searchHomeItems([form], '[2026]'), [form]);
    expect(searchHomeItems([form], '.*'), isEmpty);
  });

  test('ranks exact title, title, tags, description and preserves ties', () {
    final description = item(
      'description',
      'Other',
      description: 'Arbeitsplatz',
    );
    final tag = item('tag', 'Other', tags: ['Arbeitsplatz']);
    final title = item('title', 'Umfrage Arbeitsplatz');
    final title2 = item('title2', 'Arbeitsplatz Umfrage');
    final exact = item('exact', 'Arbeitsplatz');
    final forms = [description, tag, title, title2, exact];
    expect(searchHomeItems(forms, 'arbeitsplatz'), [
      exact,
      title,
      title2,
      tag,
      description,
    ]);
    expect(searchHomeItems(forms, '   '), forms);
    expect(forms.first, description);
  });
}
