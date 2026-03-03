class ContentModerationService {
  ContentModerationService._();

  static final ContentModerationService instance = ContentModerationService._();

  static const List<String> _blockedTerms = <String>[
    'asshole',
    'bastard',
    'bitch',
    'bullshit',
    'cunt',
    'dick',
    'fag',
    'fuck',
    'hitler',
    'motherfucker',
    'nazi',
    'nigger',
    'penis',
    'pussy',
    'rape',
    'retard',
    'schlampe',
    'scheisse',
    'scheiße',
    'sex',
    'shit',
    'slut',
    'spast',
    'whore',
    'wichser',
  ];

  List<String> findBlockedTerms(Iterable<String?> texts) {
    final hits = <String>{};
    for (final text in texts) {
      final normalized = text?.trim().toLowerCase();
      if (normalized == null || normalized.isEmpty) {
        continue;
      }
      for (final term in _blockedTerms) {
        if (normalized.contains(term)) {
          hits.add(term);
        }
      }
    }
    return hits.toList()..sort();
  }

  bool containsObjectionableContent(Iterable<String?> texts) {
    return findBlockedTerms(texts).isNotEmpty;
  }
}
