import '../perception/perception_snapshot.dart';
import 'expand_phase_planner_military_plan.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';
import 'region_military_destination_filter.dart';

export 'expand_phase_planner_military_plan.dart';
export 'expand_phase_planner_military_war_count.dart';

/// Returns the deterministic EXPAND-phase conquest destination filter
/// for the active player as an [ExpandMilitaryPlan].
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandMilitary):
///
///   "Conquest army moves toward OW invadable provinces only.
///      → Source: invadableProvinceIdsSorted, filtered to provinces
///        owned by the declare-war target (or any at-war owner if no
///        target).
///      → Use existing runConquestArmyMovePlanner with EXPAND-only
///        destination filter.
///      → No NW army moves (structural — planner never queries
///        colonial summary)."
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ConquestSummary.invadableProvinceIdsSorted] by owner faction.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ConquestSummary.invadableProvinceIdsSorted] (the OW-only
///     candidate pool),
///     [ConquestSummary.oldWorldProvincesOwned] (the EXPAND outer
///     quota gate), and [ThreatSummary.atWarWith] (the Priority 2
///     fallback when no declare-war target is given).
///   - [declaredWarTargetFactionId]: optional declare-war target from
///     [planExpandDeclareWar] for the same turn; when non-null, the
///     planner restricts conquest destinations to provinces owned by
///     that faction (Priority 1).
///
/// Priority arms (first match wins; each arm produces a sorted-ascending,
/// deduplicated province list):
///   1. **Declared-war target** — when [declaredWarTargetFactionId] is
///      non-null and owns at least one province in
///      [ConquestSummary.invadableProvinceIdsSorted], the plan
///      restricts to those provinces and lists only the target as
///      `priorityTargetOwnerFactionIdsSorted`.
///   2. **At-war owners fallback** — when no declare-war target is given
///      and at least one faction in [ThreatSummary.atWarWith] owns an
///      OW invadable province, the plan restricts to the union of those
///      provinces and lists the at-war owners sorted ascending.
///   3. **Default plan** — when the declare-war target owns nothing in
///      OW invadable, or when no declare-war target is given and no
///      at-war faction owns OW invadable, or for the outer guards (at
///      quota, missing player, empty OW invadable). Empty plan signals
///      the orchestrator to fall back to its existing free-choice
///      conquest behaviour over the full invadable set.
///
/// Structural NW suppression: this function reads only
/// [ConquestSummary.invadableProvinceIdsSorted] (OW-only by builder
/// contract). It never reads [ColonialSummary.invadableNewWorldProvinceIdsSorted],
/// so a New World province cannot appear in the plan even when the
/// snapshot exposes one (Refs #2509 § EXPAND phase planner
/// "Suppressions" / Phase planner unit tests § "EXPAND NW
/// suppression"). The actual order emission and the conquest army-move
/// pass live in `runConquestArmyMovePlanner`; the orchestrator (#2509
/// S5) wires this plan in as a filter on that pass.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ExpandMilitaryPlan]s (Refs #2509 Must-have #7).
ExpandMilitaryPlan planExpandMilitary({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? declaredWarTargetFactionId,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  if (game.playerById(snapshot.playerId) == null) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  final invadable = snapshot.conquest.invadableProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ExpandMilitaryPlan.defaultPlan;
  }

  // Shared OW/NW priority-arm partition (Refs #3941 step 3).
  final destinations = planRegionMilitaryDestinations(
    game: game,
    invadableProvinceIdsSorted: invadable,
    atWarWithFactionIds: snapshot.threats.atWarWith,
    declaredWarTargetFactionId: declaredWarTargetFactionId,
  );
  if (destinations == null) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  return ExpandMilitaryPlan(
    priorityDestinationProvinceIdsSorted:
        destinations.destinationProvinceIdsSorted,
    priorityTargetOwnerFactionIdsSorted:
        destinations.targetOwnerFactionIdsSorted,
  );
}
