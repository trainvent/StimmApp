import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';

class DuplicatePollTemplateNameException implements Exception {
  const DuplicatePollTemplateNameException();
}

/// Templates are private to an account on this device, separate from drafts.
class PollTemplateRepository {
  PollTemplateRepository(this.preferences, String userId)
    : _key = 'poll_templates_v1_${Uri.encodeComponent(userId)}';

  final SharedPreferences preferences;
  final String _key;

  List<PollTemplate> load() {
    final encoded = preferences.getStringList(_key) ?? const [];
    return encoded
        .map(
          (value) =>
              PollTemplate.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  bool containsName(String name, {String? excludingId}) => load().any(
    (template) =>
        template.id != excludingId &&
        template.name.trim().toLowerCase() == name.trim().toLowerCase(),
  );

  Future<void> save(PollTemplate template) async {
    if (containsName(template.name, excludingId: template.id)) {
      throw const DuplicatePollTemplateNameException();
    }
    final templates = load()..removeWhere((item) => item.id == template.id);
    templates.insert(0, template);
    await _write(templates);
  }

  Future<void> delete(String id) async {
    await _write(load()..removeWhere((item) => item.id == id));
  }

  Future<void> _write(List<PollTemplate> templates) async {
    final saved = await preferences.setStringList(
      _key,
      templates.map((template) => jsonEncode(template.toJson())).toList(),
    );
    if (!saved) throw StateError('Could not persist poll templates');
  }
}
