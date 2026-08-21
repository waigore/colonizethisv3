/// Shared list parse helper for [Game] JSON decode (Refs #4334, #4571).
library;

List<T> parseGameModelList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  final list = raw as List<dynamic>? ?? const [];
  return list
      .map(
        (e) => fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)),
      )
      .toList();
}
