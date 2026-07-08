/// Shared region-scoped military destination filter for EXPAND (OW) and
/// COLONIAL (NW) conquest plans (Refs #3941 step 3).
///
/// [ExpandMilitaryPlan] and [ColonialMilitaryPlan] keep their public type
/// names and docs; both plan builders defer the declared-war / at-war owner
/// partition to [planRegionMilitaryDestinations] so the priority-arm logic
/// lives in one place. Callers still supply region-specific invadable lists
/// and outer phase guards themselves.
library;

import 'package:colonizethis_logic/ai_api.dart' show getProvinceOwnerMap;
import 'package:colonizethis_models/colonizethis_models.dart' show Game;

/// Sorted destination / owner lists for a region-scoped military plan, or
/// `null` when the priority arms fall through to the caller's default plan.
typedef RegionMilitaryDestinationLists = ({
  List<String> destinationProvinceIdsSorted,
  List<String> targetOwnerFactionIdsSorted,
});

/// Partitions [invadableProvinceIdsSorted] by owner using the same priority
/// arms as the EXPAND and COLONIAL military planners:
///
/// 1. **Declared-war target** — when [declaredWarTargetFactionId] is non-null
///    and owns at least one invadable province, return those destinations and
///    a single-owner list.
/// 2. **At-war owners fallback** — when no declare-war target is given,
///    return the union of invadable provinces owned by factions in
///    [atWarWithFactionIds], with owners sorted ascending.
/// 3. **Fall-through** — return `null` so the caller emits its default plan
///    (empty destination / owner lists).
///
/// Pure and deterministic for fixed inputs (Refs #2509 Must-have #7). Does not
/// apply phase quota gates or player-existence checks — those remain in
/// [planExpandMilitary] / [planColonialMilitary].
RegionMilitaryDestinationLists? planRegionMilitaryDestinations({
  required Game game,
  required List<String> invadableProvinceIdsSorted,
  required List<String> atWarWithFactionIds,
  String? declaredWarTargetFactionId,
}) {
  if (invadableProvinceIdsSorted.isEmpty) {
    return null;
  }

  final provinceOwner = getProvinceOwnerMap(game);

  if (declaredWarTargetFactionId != null) {
    final destinations = <String>[
      for (final pid in invadableProvinceIdsSorted)
        if (provinceOwner[pid] == declaredWarTargetFactionId) pid,
    ];
    if (destinations.isEmpty) {
      return null;
    }
    destinations.sort();
    return (
      destinationProvinceIdsSorted: List<String>.unmodifiable(destinations),
      targetOwnerFactionIdsSorted: List<String>.unmodifiable(<String>[
        declaredWarTargetFactionId,
      ]),
    );
  }

  final atWarSet = atWarWithFactionIds.toSet();
  final atWarOwners = <String>{};
  final destinations = <String>[];
  for (final pid in invadableProvinceIdsSorted) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!atWarSet.contains(owner)) continue;
    destinations.add(pid);
    atWarOwners.add(owner);
  }
  if (destinations.isEmpty) {
    return null;
  }
  destinations.sort();
  final owners = atWarOwners.toList()..sort();
  return (
    destinationProvinceIdsSorted: List<String>.unmodifiable(destinations),
    targetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}
