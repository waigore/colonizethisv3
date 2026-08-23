import '../perception/perception_snapshot.dart';
import 'phase_destination_result.dart';
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;

/// Deterministic COLONIAL-lite naval directive returned by
/// [planColonialLiteNaval].
///
/// Carries the priority subset of
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted] (NW only) the
/// orchestrator (#2509 S5) should treat as the COLONIAL-lite naval
/// exploration / cargo focus this turn, restricted to provinces owned
/// by tribes or minor nations. Two paired list fields keep the value
/// class symmetric with [ColonialMilitaryPlan] so test fixtures and
/// orchestrator wiring can swap between them with the same shape:
/// `priorityNwProvinceIdsSorted` is the conquest-style destination
/// list (province ids) and `priorityTargetOwnerFactionIdsSorted` is
/// the corresponding owner-faction roster, both deduplicated and
/// sorted ascending so identical inputs always yield identical plans
/// (Refs #2509 Must-have #7).
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path. Value equality compares both list contents so tests
/// can assert against literal constructions without relying on
/// identity.
final class ColonialLiteNavalPlan extends PhaseDestinationResult {
  const ColonialLiteNavalPlan({
    required List<String> priorityNwProvinceIdsSorted,
    required List<String> priorityTargetOwnerFactionIdsSorted,
  }) : super(
         priorityProvinceIdsSorted: priorityNwProvinceIdsSorted,
         priorityTargetOwnerFactionIdsSorted:
             priorityTargetOwnerFactionIdsSorted,
       );

  /// Reusable "no override" plan returned for the outer defensive
  /// guards (missing player, empty NW invadable) and for the
  /// priority-arm fall-through (no tribe / minor faction owns any NW
  /// invadable province). The orchestrator (#2509 S5) treats
  /// `defaultPlan` as "no COLONIAL-lite naval focus this turn" and
  /// leaves the existing naval suggestion pipeline to its legacy
  /// free-choice behaviour.
  static const ColonialLiteNavalPlan defaultPlan = ColonialLiteNavalPlan(
    priorityNwProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ColonialSummary.invadableNewWorldProvinceIdsSorted]
  /// (NW only by builder contract) whose owners are tribes or minor
  /// nations -- the COLONIAL-lite naval exploration / cargo focus
  /// this turn. Sorted ascending so identical inputs yield identical
  /// lists (Refs #2509 Must-have #7). Empty for [defaultPlan].
  ///
  /// The orchestrator (#2509 S5) is expected to combine this list
  /// with `MapTopology` (via
  /// `newWorldSeaZonesAdjacentToInvadableProvinces` in
  /// `colonial_naval_scoring.dart`) to derive the actual sea-zone
  /// naval-move destinations. Cargo routing (deliver riches to OW
  /// stockpile) is satisfied at the orchestrator layer by the
  /// existing colonial naval pathing the directive does not override.
  List<String> get priorityNwProvinceIdsSorted => priorityProvinceIdsSorted;

  /// Faction ids of the tribes / minor nations owning the provinces
  /// in [priorityNwProvinceIdsSorted]. Sorted ascending and
  /// deduplicated. Never includes any Great Power id -- GPs are
  /// structurally excluded by [planColonialLiteNaval] because
  /// COLONIAL-lite is the safeguard for **tribe / minor** NW
  /// penetration only (issue #2509 § COLONIAL-lite "establishOverture
  /// toward visible NW tribe / minor owners"). Empty for [defaultPlan].
  @override
  List<String> get priorityTargetOwnerFactionIdsSorted =>
      super.priorityTargetOwnerFactionIdsSorted;

  @override
  String toString() =>
      'ColonialLiteNavalPlan('
      'priorityNwProvinceIdsSorted: $priorityNwProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

/// COLONIAL-lite naval directive. Cite `SPEC/ai/ai-architecture.md`
/// § COLONIAL-lite and issue #2509 rather than restating the contract here.
ColonialLiteNavalPlan planColonialLiteNaval({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (game.playerById(snapshot.playerId) == null) {
    return ColonialLiteNavalPlan.defaultPlan;
  }
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ColonialLiteNavalPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);
  final priorityProvinces = <String>[];
  final priorityOwners = <String>{};
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (game.playerById(owner) != null) continue;
    priorityProvinces.add(pid);
    priorityOwners.add(owner);
  }
  if (priorityProvinces.isEmpty) {
    return ColonialLiteNavalPlan.defaultPlan;
  }
  priorityProvinces.sort();
  final owners = priorityOwners.toList()..sort();
  return ColonialLiteNavalPlan(
    priorityNwProvinceIdsSorted: List<String>.unmodifiable(priorityProvinces),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}
