import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/form_import.dart';

void main() {
  final petition = <String, dynamic>{
    'version': 1,
    'type': 'petition',
    'title': 'A greener neighbourhood',
    'description': 'Please plant more trees in our neighbourhood.',
  };
  dynamic parse(Map<String, dynamic> data, {String type = 'petition'}) =>
      FormImport.parse(
        jsonEncode(data),
        expectedType: type,
        allowedTags: {'Environment'},
      );

  test('imports petition content without importing identity or audience', () {
    final result = parse({
      ...petition,
      'tags': ['Environment'],
      'durationDays': 14,
    });
    expect(result.title, petition['title']);
    expect(result.durationDays, 14);
    expect(result.includesAudience, false);
    expect(result.scopeType, isNull);
    expect(result.questions, isNull);
  });
  test('imports all poll questions and ordered options', () {
    final result = parse({
      ...petition,
      'type': 'poll',
      'questions': [
        {
          'title': 'Which tree?',
          'options': ['Oak', 'Maple'],
        },
        {
          'title': 'Where?',
          'options': ['Park', 'Street'],
        },
      ],
    }, type: 'poll');
    expect(result.questions.length, 2);
    expect(result.questions.first.options, ['Oak', 'Maple']);
  });
  test('rejects invalid types, unsupported fields and out-of-range values', () {
    for (final change in <Map<String, dynamic>>[
      {'version': 2},
      {'type': 'poll'},
      {'createdBy': 'another-user'},
      {'durationDays': 0},
      {'durationDays': 43},
      {'durationDays': 1.5},
      {'openUntilClosed': 'yes'},
      {'scopeType': 'continent'},
      {'scopeType': 'countryUnion'},
      {'countryUnion': 'EU'},
      {
        'tags': ['unknown'],
      },
      {
        'tags': ['Environment', 'Environment'],
      },
      {'title': ''},
      {'description': null},
      {'questions': []},
    ]) {
      expect(
        () => parse({...petition, ...change}),
        throwsFormatException,
        reason: '$change',
      );
    }
  });
  test('rejects malformed and oversized JSON', () {
    for (final source in ['{', '[]', 'null', ' ' * (FormImport.maxBytes + 1)]) {
      expect(
        () =>
            FormImport.parse(source, expectedType: 'petition', allowedTags: {}),
        throwsFormatException,
      );
    }
  });
  test('rejects incomplete questions and duplicate answers', () {
    for (final questions in [
      [],
      [
        {
          'title': 'Question',
          'options': ['Only'],
        },
      ],
      [
        {
          'title': 'Question',
          'options': ['Yes', 'yes'],
        },
      ],
      List.generate(
        21,
        (_) => {
          'title': 'Question',
          'options': ['Yes', 'No'],
        },
      ),
    ]) {
      expect(
        () => parse({
          ...petition,
          'type': 'poll',
          'questions': questions,
        }, type: 'poll'),
        throwsFormatException,
      );
    }
  });
}
