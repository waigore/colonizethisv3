import 'package:colonizethis_data/colonizethis_data.dart';

/// AI category buckets that group the seven game tech categories for Full-AI
/// research diversification. SPEC/program/order-suggestions.md § Research orders.
enum ResearchAiBucket { naval, military, economic, exploration }

/// Fixed tiebreak order for equal-weight buckets: naval > military > economic >
/// exploration. Also the deterministic iteration order for bucket selection.
const List<ResearchAiBucket> researchAiBucketOrder = <ResearchAiBucket>[
  ResearchAiBucket.naval,
  ResearchAiBucket.military,
  ResearchAiBucket.economic,
  ResearchAiBucket.exploration,
];

/// Maps a game tech category to its AI bucket. Unmapped categories (and
/// `new-world` / `diplomatic` / `civilian`) fall back to exploration.
ResearchAiBucket researchBucketForCategory(String category) {
  switch (category) {
    case 'naval':
    case 'transport':
      return ResearchAiBucket.naval;
    case 'military':
      return ResearchAiBucket.military;
    case 'gathering':
    case 'labour':
      return ResearchAiBucket.economic;
    default:
      return ResearchAiBucket.exploration;
  }
}

/// Deterministic 0..99 roll from [seed] (stable pure-int hash; no RNG state).
int diversifyResearchRoll(int seed) {
  var x = seed & 0x7fffffff;
  x = (x * 1103515245 + 12345) & 0x7fffffff;
  return x % 100;
}

/// Greedy-cheapest tech id for [pool]'s head, or — for slots `>= 1` when
/// [diversify] and the per-slot blend rolls in — the greedy-first tech in the
/// highest-weight AI bucket not yet [represented]. Falls back to greedy when
/// the chosen bucket has no available tech. [pool] is greedy-sorted by caller.
String pickDiversifiedResearchTech({
  required int slotIndex,
  required List<TechDefinition> pool,
  required bool diversify,
  required Map<ResearchAiBucket, int> bucketWeights,
  required Set<ResearchAiBucket> represented,
  required int researchSeed,
  required int diversifyWeight,
}) {
  if (!diversify || slotIndex == 0) return pool.first.id;
  if (diversifyResearchRoll(researchSeed + slotIndex) >= diversifyWeight) {
    return pool.first.id;
  }
  final bucket = chooseDiversifiedResearchBucket(
    pool: pool,
    bucketWeights: bucketWeights,
    represented: represented,
  );
  if (bucket == null) return pool.first.id;
  for (final tech in pool) {
    if (researchBucketForCategory(tech.category) == bucket) return tech.id;
  }
  return pool.first.id;
}

/// Highest-weight AI bucket that is both unrepresented and has at least one
/// tech in [pool], ties broken by [researchAiBucketOrder]. Null when none
/// qualifies.
ResearchAiBucket? chooseDiversifiedResearchBucket({
  required List<TechDefinition> pool,
  required Map<ResearchAiBucket, int> bucketWeights,
  required Set<ResearchAiBucket> represented,
}) {
  final available = <ResearchAiBucket>{
    for (final tech in pool) researchBucketForCategory(tech.category),
  };
  final candidates = researchAiBucketOrder
      .where((b) => !represented.contains(b) && available.contains(b))
      .toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final byWeight = (bucketWeights[b] ?? 0).compareTo(bucketWeights[a] ?? 0);
    if (byWeight != 0) return byWeight;
    return researchAiBucketOrder
        .indexOf(a)
        .compareTo(researchAiBucketOrder.indexOf(b));
  });
  return candidates.first;
}
