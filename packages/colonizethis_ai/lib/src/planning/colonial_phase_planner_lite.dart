import '../perception/perception_snapshot.dart';
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;

export 'colonial_phase_planner_lite_naval.dart';

/// Returns the deterministic list of NW tribe / minor faction ids the active
/// COLONIAL-lite player should `establishOverture` toward this turn.
///
/// Contract (issue #2509 § COLONIAL-lite § planColonialLiteOvertures):
///
///   "Inputs: Game, AIWorldSnapshot.
///    Returns: List<DiplomacyOrder> (establishOverture only).
///
///    For each visible NW tribe/minor owner in
///    adjacentNewWorldOwnerFactionIdsSorted ∪
///    preferredColonialTargetFactionIdsSorted:
///      → If no embassy yet, suggest establishOverture(tribe).
///      → Never emit declareWar, joinEmpire chain advance, or
///        purchase_land here.
///    Tiebreak: lowest factionId (deterministic)."
///
/// COLONIAL-lite is the parallel COLONIAL safeguard inside EXPAND scheduled
/// at turn ≥120 with OW ≥9 and below quota and global `newWorld|` carrying
/// non-GP ownership (issue #2509 § COLONIAL-lite). It is the **only**
/// exception to EXPAND's total NW suppression and prevents the deadlock
/// where no GP reaches OW = 10 and zero NW colonisation ever begins. The
/// orchestrator (#2509 S5) is expected to dispatch this planner only when
/// `observerGoalPhaseFor` resolves to [ObserverGoalPhase.colonialLite]; the
/// function itself does not re-check the phase, matching the other planner
/// contracts in this module.
///
/// Return type is `List<String>` of target faction ids (not the underlying
/// [DiplomaticOrder] objects) for parity with [planColonialPeace] and
/// `planExpandPeace`: the orchestrator translates the id list into the
/// concrete `establishOverture` order envelope, applying the deferred
/// suggestion-API validation step (#2509 S5). The list is sorted ascending
/// so identical inputs always yield identical outputs (Refs #2509 Must-have
/// #7) and the lowest-factionId tiebreak from the spec is preserved.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard, walks the GP filter on each candidate
///     ([Game.playerById] for tribes / minors returns `null`), and reads
///     [Game.overtureStates] to filter out targets that already advanced
///     past the `tradeConsulate` stage with the active player.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.adjacentNewWorldOwnerFactionIdsSorted] and
///     [ColonialSummary.preferredColonialTargetFactionIdsSorted]. Both
///     lists are unioned (sorted-deduplicated) before the GP / embassy
///     filters run.
///
/// Filter pipeline (each stage is structural, not configurable):
///   1. **Missing active player** -> empty list (the planner cannot
///      compute a per-player overture set without an owning [Player]).
///   2. **Empty candidate union** -> empty list (no visible NW tribe /
///      minor owner -- nothing to overture this turn).
///   3. **GP candidate filter** -> drop any candidate id where
///      [Game.playerById] returns a non-null [Player]. GPs do not
///      receive `establishOverture` per the spec ("Never emit
///      declareWar ... here" implies GP-vs-GP wars are out of scope for
///      this planner; GP-vs-GP peace is the [planColonialPeace] /
///      `planExpandPeace` contract).
///   4. **Embassy filter** -> drop any candidate where the active
///      player already holds an [OvertureState] with the target whose
///      [OvertureState.hasEmbassy] is `true` (stage in `{embassy, nap,
///      joinEmpire}`). The active-player constraint matters because
///      `game.overtureStates` lists per-GP entries -- a sibling GP's
///      embassy must not block the active player from initiating its
///      own overture.
///   5. **Sort ascending** -> deterministic list output (Refs #2509
///      Must-have #7).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists.
List<String> planColonialLiteOvertures({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final activePlayerId = snapshot.playerId;
  if (game.playerById(activePlayerId) == null) {
    return const [];
  }

  final candidates = <String>{};
  candidates.addAll(snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted);
  candidates.addAll(snapshot.colonial.preferredColonialTargetFactionIdsSorted);
  if (candidates.isEmpty) {
    return const [];
  }

  final result = <String>[];
  for (final factionId in candidates) {
    if (game.playerById(factionId) != null) continue;
    final alreadyEmbassied = game.overtureStates.any(
      (o) =>
          o.gpId == activePlayerId && o.targetId == factionId && o.hasEmbassy,
    );
    if (alreadyEmbassied) continue;
    result.add(factionId);
  }
  result.sort();
  return result;
}
