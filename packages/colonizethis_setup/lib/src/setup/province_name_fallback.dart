/// Deterministic procedural fallback for province/capital names when naming
/// config is missing or empty. SPEC/game/naming.md § Fallback.
library;

import 'dart:math';

const List<String> _stubs = [
  'Tan',
  'Ver',
  'Mor',
  'Ash',
  'Elm',
  'Oak',
  'Red',
  'Stone',
  'Clear',
  'Fair',
  'North',
  'High',
  'Low',
  'Briar',
  'Cedar',
];

const List<String> _suffixes = [
  'ton',
  'ville',
  'ford',
  'burg',
  'dale',
  'field',
  'port',
  'wood',
  'shire',
  'mouth',
  'gate',
  'haven',
  'ridge',
  'vale',
];

const int _maxRetries = 100;

/// Generates a province name (stub + suffix) that is not in [usedNames].
/// Adds the returned name to [usedNames]. Deterministic for a given [seed].
/// If the first candidate is taken, appends " 2", " 3", … until unique.
String generateUniqueProvinceName(int seed, Set<String> usedNames) {
  final rng = Random(seed);
  final stub = _stubs[rng.nextInt(_stubs.length)];
  final suffix = _suffixes[rng.nextInt(_suffixes.length)];
  var candidate = stub + suffix;
  if (!usedNames.contains(candidate)) {
    usedNames.add(candidate);
    return candidate;
  }
  for (var n = 2; n <= _maxRetries; n++) {
    candidate = '$stub$suffix $n';
    if (!usedNames.contains(candidate)) {
      usedNames.add(candidate);
      return candidate;
    }
  }
  // Extremely unlikely: fallback to seed-based unique string
  final fallback = '$stub$suffix (${seed & 0xFFFF})';
  usedNames.add(fallback);
  return fallback;
}
