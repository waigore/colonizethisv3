import '../perception/perception_snapshot.dart';
import 'colonial_phase_planner_naval_plan.dart';
import 'expand_phase_planner_economy.dart' show ExpandEconomyPlan;
import 'phase_priority_weights.dart' show isNwLockRecoveryPathEActive;
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;

export 'colonial_phase_planner_naval_plan.dart';

/// COLONIAL invasion-transport directive (issue #2509 § planColonialNaval).
ColonialNavalPlan planColonialNaval({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? colonialDeclaredWarTargetFactionId,
  ExpandEconomyPlan expandEconomyPlan =
      ExpandEconomyPlan.defaultPlan,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
      !isNwLockRecoveryPathEActive(
        snapshot: snapshot,
        expandEconomyPlan: expandEconomyPlan,
      )) {
    return ColonialNavalPlan.defaultPlan;
  }
  if (game.playerById(snapshot.playerId) == null) {
    return ColonialNavalPlan.defaultPlan;
  }
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ColonialNavalPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);

  if (colonialDeclaredWarTargetFactionId != null) {
    final destinations = <String>[
      for (final pid in invadable)
        if (provinceOwner[pid] == colonialDeclaredWarTargetFactionId) pid,
    ];
    if (destinations.isEmpty) {
      return ColonialNavalPlan.defaultPlan;
    }
    destinations.sort();
    return ColonialNavalPlan(
      priorityInvasionTransportProvinceIdsSorted: List<String>.unmodifiable(
        destinations,
      ),
      priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(<String>[
        colonialDeclaredWarTargetFactionId,
      ]),
    );
  }

  final atWarSet = snapshot.threats.atWarWith.toSet();
  final atWarOwners = <String>{};
  final destinations = <String>[];
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!atWarSet.contains(owner)) continue;
    destinations.add(pid);
    atWarOwners.add(owner);
  }
  if (destinations.isEmpty) {
    return ColonialNavalPlan.defaultPlan;
  }
  destinations.sort();
  final owners = atWarOwners.toList()..sort();
  return ColonialNavalPlan(
    priorityInvasionTransportProvinceIdsSorted: List<String>.unmodifiable(
      destinations,
    ),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}
