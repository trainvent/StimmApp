import 'dart:convert';

import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';

/// Portable content only. Identity, responses and publication state are never imported.
class FormImport {
  static const maxBytes = 256 * 1024;

  static PollTemplate parse(
    String source, {
    required String expectedType,
    required Set<String> allowedTags,
  }) {
    void invalid(String field) => throw FormatException(field);
    if (utf8.encode(source).length > maxBytes) invalid('file');
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) invalid('document');
    final json = decoded as Map<String, dynamic>;
    const fields = {
      'version',
      'type',
      'title',
      'description',
      'questions',
      'tags',
      'durationDays',
      'openUntilClosed',
      'scopeType',
      'countryUnion',
    };
    for (final key in json.keys) {
      if (!fields.contains(key)) invalid(key);
    }
    if (json['version'] != 1 || json['version'] is! int) invalid('version');
    final type = json['type'];
    if (type != expectedType && !(expectedType == 'poll' && type == 'survey')) {
      invalid('type');
    }
    String text(dynamic value, String field, int min, int max) {
      if (value is! String) invalid(field);
      final result = (value as String).trim();
      if (result.length < min || result.length > max) invalid(field);
      return result;
    }

    final title = text(
      json['title'],
      'title',
      AppLimits.minTitleLength,
      AppLimits.maxTitleLength,
    );
    final description = text(
      json['description'],
      'description',
      AppLimits.minDescriptionLength,
      AppLimits.maxDescriptionLength,
    );
    List<String>? tags;
    if (json.containsKey('tags')) {
      final values = json['tags'];
      if (values is! List ||
          values.isEmpty ||
          values.length > AppLimits.maxTagAmount) {
        invalid('tags');
      }
      tags = (values as List).map((value) {
        if (value is! String || !allowedTags.contains(value)) invalid('tags');
        return value as String;
      }).toList();
      if (tags.toSet().length != tags.length) invalid('tags');
    }
    final duration = json['durationDays'];
    if (json.containsKey('durationDays') &&
        (duration is! int ||
            duration < 1 ||
            duration > AppLimits.defaultFormDurationDays)) {
      invalid('durationDays');
    }
    if (json.containsKey('openUntilClosed') && json['openUntilClosed'] is! bool) {
      invalid('openUntilClosed');
    }
    final scope = json['scopeType'];
    if (json.containsKey('scopeType') &&
        !{
          'global',
          'countryUnion',
          'country',
          'stateOrRegion',
          'city',
        }.contains(scope)) {
      invalid('scopeType');
    }
    final union = json['countryUnion'];
    if ((scope == 'countryUnion' && !{'EU', 'UN'}.contains(union)) ||
        (json.containsKey('countryUnion') && scope != 'countryUnion')) {
      invalid('countryUnion');
    }
    List<PollTemplateQuestion>? questions;
    if (expectedType == 'petition') {
      if (json.containsKey('questions')) invalid('questions');
    } else {
      final values = json['questions'];
      if (values is! List ||
          values.isEmpty ||
          values.length > AppLimits.maxSurveyQuestions) {
        invalid('questions');
      }
      questions = (values as List).map((value) {
        if (value is! Map ||
            value.keys.any((key) => key != 'title' && key != 'options')) {
          invalid('questions');
        }
        final question = value as Map;
        final options = question['options'];
        if (options is! List ||
            options.length < 2 ||
            options.length > AppLimits.maxSurveyOptionsPerQuestion) {
          invalid('options');
        }
        final labels = (options as List)
            .map(
              (option) =>
                  text(option, 'options', 1, AppLimits.maxSurveyOptionLength),
            )
            .toList();
        if (labels.map((label) => label.toLowerCase()).toSet().length !=
            labels.length) {
          invalid('options');
        }
        return PollTemplateQuestion(
          title: text(
            question['title'],
            'questions.title',
            1,
            AppLimits.maxSurveyQuestionLength,
          ),
          options: labels,
        );
      }).toList();
    }
    return PollTemplate(
      id: '',
      name: title,
      title: title,
      description: description,
      questions: questions,
      tags: tags,
      scopeType: scope as String?,
      countryUnion: union as String?,
      durationDays: duration as int?,
      openUntilClosed: json['openUntilClosed'] as bool?,
    );
  }
}
