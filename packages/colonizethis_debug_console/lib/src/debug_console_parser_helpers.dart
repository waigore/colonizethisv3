/// Upper bound for spawn commands (`/spawn_civilian`, `/spawn_regiment`, `/spawn_ship`).
const int kDebugConsoleMaxSpawnCount = 25;

/// Upper bound for credit commands; parser clamps here.
const int kDebugConsoleMaxTreasuryCreditAmount = 9999;

/// Parses optional spawn count at [position] (1-based token index).
///
/// When fewer than [position] tokens exist, returns count `1`.
/// On invalid or out-of-range values, returns an error message in the record.
({int count, String? error}) parseOptionalCount(
  List<String> tokens,
  int position,
) {
  final parsedCount = tokens.length >= position
      ? int.tryParse(tokens[position - 1])
      : 1;
  if (parsedCount == null) {
    return (
      count: 0,
      error:
          'Count must be an integer between 1 and $kDebugConsoleMaxSpawnCount.',
    );
  }
  if (parsedCount < 1 || parsedCount > kDebugConsoleMaxSpawnCount) {
    return (
      count: 0,
      error: 'Count must be between 1 and $kDebugConsoleMaxSpawnCount.',
    );
  }
  return (count: parsedCount, error: null);
}

/// Parses a positive integer amount and clamps to [kDebugConsoleMaxTreasuryCreditAmount].
({int requested, int credited, String? error}) parseAmountWithClamp(
  String token,
) {
  final rawAmount = int.tryParse(token);
  if (rawAmount == null) {
    return (requested: 0, credited: 0, error: 'Amount must be an integer.');
  }
  if (rawAmount < 1) {
    return (requested: 0, credited: 0, error: 'Amount must be at least 1.');
  }
  final creditedAmount = rawAmount > kDebugConsoleMaxTreasuryCreditAmount
      ? kDebugConsoleMaxTreasuryCreditAmount
      : rawAmount;
  return (requested: rawAmount, credited: creditedAmount, error: null);
}

String? canonicalIdForInput(String input, Iterable<String> candidates) {
  for (final candidate in candidates) {
    if (candidate.toLowerCase() == input) {
      return candidate;
    }
  }
  return null;
}

/// Shared spawn-by-supported-id path for `/spawn_regiment` and `/spawn_ship`.
({String? typeId, int count, String? error}) parseSpawnBySupportedId({
  required List<String> tokens,
  required String usage,
  required String unknownIdMessage,
  required Set<String> supportedIds,
}) {
  if (tokens.length < 2) {
    return (typeId: null, count: 0, error: usage);
  }
  final typeId = tokens[1].trim().toLowerCase();
  if (!supportedIds.contains(typeId)) {
    return (typeId: null, count: 0, error: unknownIdMessage);
  }
  final countResult = parseOptionalCount(tokens, 3);
  if (countResult.error != null) {
    return (typeId: null, count: 0, error: countResult.error);
  }
  return (typeId: typeId, count: countResult.count, error: null);
}

/// Shared credit-by-canonical-id path for `/add_worker` and `/add_resource`.
({String? canonicalId, int requested, int credited, String? error})
parseCreditByCanonicalId({
  required List<String> tokens,
  required String usage,
  required String unknownIdMessage,
  required Iterable<String> candidates,
}) {
  if (tokens.length < 3) {
    return (canonicalId: null, requested: 0, credited: 0, error: usage);
  }
  final canonicalId = canonicalIdForInput(
    tokens[1].trim().toLowerCase(),
    candidates,
  );
  if (canonicalId == null) {
    return (
      canonicalId: null,
      requested: 0,
      credited: 0,
      error: unknownIdMessage,
    );
  }
  final amountResult = parseAmountWithClamp(tokens[2]);
  if (amountResult.error != null) {
    return (
      canonicalId: null,
      requested: 0,
      credited: 0,
      error: amountResult.error,
    );
  }
  return (
    canonicalId: canonicalId,
    requested: amountResult.requested,
    credited: amountResult.credited,
    error: null,
  );
}
