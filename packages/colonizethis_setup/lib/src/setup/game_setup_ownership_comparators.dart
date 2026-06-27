part of 'game_setup_ownership.dart';

/// Deterministic faction ordering: **higher [targetPerFaction] value first**,
/// ties broken by **ascending faction id**. Single source of truth for the
/// "by target desc, then id asc" growth/packing order previously inlined in
/// `_lockedGrowthOrder`, the multi-component `facsOrdered` sort, and the
/// per-component `fs` sort. Tie-break exactness (id-asc) is preserved so locked
/// assignment output stays byte-identical (Refs #3740).
int compareByTargetDescThenIdAsc(
  String a,
  String b,
  Map<String, int> targetPerFaction,
) {
  final c = targetPerFaction[b]!.compareTo(targetPerFaction[a]!);
  if (c != 0) return c;
  return a.compareTo(b);
}

/// Deterministic landmass/component ordering: **larger collection first**, ties
/// broken by the **ascending minimum element id**. Single source of truth for
/// the "by size desc, then min-id asc" order previously inlined in
/// `_landmassEntriesSortedBySize` and the multi-component sort. Both call sites
/// pass non-empty province collections; the min-id tie-break is preserved
/// exactly (Refs #3740).
int compareBySizeDescThenMinIdAsc(Iterable<String> a, Iterable<String> b) {
  final c = b.length.compareTo(a.length);
  if (c != 0) return c;
  final amin = a.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
  final bmin = b.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
  return amin.compareTo(bmin);
}
