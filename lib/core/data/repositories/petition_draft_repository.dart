import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/data/models/petition_draft.dart';

class PetitionDraftRepository {
  PetitionDraftRepository(this.preferences, String userId)
    : _key = 'petition_drafts_v1_${Uri.encodeComponent(userId)}';

  final SharedPreferences preferences;
  final String _key;

  List<PetitionDraft> load() => (preferences.getStringList(_key) ?? const [])
      .map(
        (value) =>
            PetitionDraft.fromJson(jsonDecode(value) as Map<String, dynamic>),
      )
      .toList();

  Future<void> save(PetitionDraft draft) async {
    final drafts = load()..removeWhere((item) => item.form.id == draft.form.id);
    drafts.insert(0, draft);
    await _write(drafts);
  }

  Future<void> delete(String id) async =>
      _write(load()..removeWhere((item) => item.form.id == id));

  Future<void> _write(List<PetitionDraft> drafts) async {
    if (!await preferences.setStringList(
      _key,
      drafts.map((draft) => jsonEncode(draft.toJson())).toList(),
    )) {
      throw StateError('Could not persist petition drafts');
    }
  }
}
