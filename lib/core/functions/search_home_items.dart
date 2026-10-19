import 'package:stimmapp/core/data/models/home_item.dart';

/// Literal, case-insensitive search. Every word must occur in at least one field.
/// Umlaut spellings (ä/ae/a, ö/oe/o, ü/ue/u) and ß/ss are equivalent.
List<T> searchHomeItems<T extends HomeItem>(Iterable<T> items, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return items.toList();
  final words = normalizedQuery.split(' ');
  final matches = <({T item, int rank, int index})>[];
  var index = 0;
  for (final item in items) {
    final title = _normalize(item.title);
    final description = _normalize(item.description);
    final tags = item.tags.map(_normalize).toList();
    final fields = [title, description, ...tags];
    if (words.every((word) => fields.any((field) => field.contains(word)))) {
      final rank = title == normalizedQuery
          ? 0
          : words.every(title.contains)
          ? 1
          : words.every(
              (word) => [title, ...tags].any((field) => field.contains(word)),
            )
          ? 2
          : 3;
      matches.add((item: item, rank: rank, index: index));
    }
    index++;
  }
  // Keep the source's ordering (normally newest first) for equal relevance.
  matches.sort((a, b) {
    final relevance = a.rank.compareTo(b.rank);
    return relevance != 0 ? relevance : a.index.compareTo(b.index);
  });
  return matches.map((match) => match.item).toList();
}

String _normalize(String text) => text
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss')
    .replaceAll('ae', 'a')
    .replaceAll('oe', 'o')
    .replaceAll('ue', 'u')
    .replaceAll(RegExp('[\u0300-\u036f]'), '')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');
