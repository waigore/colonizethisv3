import 'dart:math';

/// Returns a permutation of `0 .. poolLength - 1` using [List.shuffle] with
/// [Random] seeded by [seed].
///
/// Matches the consumer order of shuffling a same-length list with the same
/// seed (Fisher–Yates). Used for province name pools during setup and for
/// sea-zone preset assignment (`SPEC/game/naming.md`).
List<int> shuffledPoolIndices({required int poolLength, required int seed}) {
  if (poolLength <= 0) return const [];
  final rng = Random(seed);
  return List.generate(poolLength, (i) => i)..shuffle(rng);
}
