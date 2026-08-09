import 'package:colonizethis_data/colonizethis_data.dart'
    as regiment_catalog
    show cheapestRegimentBuildTreasuryCost;

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'cast_iron_labour_gate.dart'
    show isCastIronLabourPopulationBoundForLockRecoverySeller;
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

export 'expand_phase_planner_economy_peace_rebuild.dart';

/// EXPAND-phase economy directive returned by [planExpandEconomy].
///
/// Two independent booleans describe the orchestrator overrides for the
/// active player this turn. The planner stays a pure function: the
/// orchestrator (Refs #2509 S5) translates these flags into the actual
/// build-threshold reset and economy-weight cargo boost when wiring the
/// EXPAND dispatch.
///
/// The flags compose — a GP can both be told to force a regiment build
/// and to raise cargo preference in the same turn (canonical "rebuild
/// fast while overseas riches keep arriving" arm when reg = 0 and
/// effective treasury is still under the cheapest regiment cost).
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path.
class ExpandEconomyPlan {
  const ExpandEconomyPlan({
    required this.forceCheapestRegimentBuild,
    required this.boostTreasuryRecoveryCargo,
    this.boostCastIronLabourPeasantRecruitment = false,
  });

  /// Reusable "no override" plan returned for non-EXPAND callers, GPs
  /// at quota, defensive guards, and the priority-arm fall-through.
  static const ExpandEconomyPlan defaultPlan = ExpandEconomyPlan(
    forceCheapestRegimentBuild: false,
    boostTreasuryRecoveryCargo: false,
    boostCastIronLabourPeasantRecruitment: false,
  );

  /// True when the orchestrator should drop the build-pass economy
  /// threshold to zero and pick the cheapest entry in
  /// [RegimentEconomyCatalog] (military rebuild crisis).
  ///
  /// Set under either of the two regiment-rebuild arms in issue #2509
  /// § EXPAND phase planner § planExpandEconomy:
  /// (a) `regimentCount == 0` with a non-empty
  ///     [ConquestSummary.invadableProvinceIdsSorted] (the
  ///     `brokeBelowQuotaAtPeace` / `needRegimentsToExpand` legacy
  ///     condition collapsed into the phase planner); or
  /// (b) the trap condition
  ///     `0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
  ///     with non-empty invadable OW frontier and effective treasury
  ///     (cash + [pendingRichesTreasuryDelta]) at or above
  ///     [cheapestRegimentBuildTreasuryCost].
  final bool forceCheapestRegimentBuild;

  /// True when the orchestrator should add
  /// [kBelowQuotaPeaceTreasuryRecoveryCargoBoost] to economy weight so
  /// overseas cargo preference rises (deliver NW riches to stockpile)
  /// even in EXPAND.
  ///
  /// Set when below quota AND effective treasury (cash +
  /// [pendingRichesTreasuryDelta]) is strictly below
  /// [cheapestRegimentBuildTreasuryCost] (issue #2509 § EXPAND phase
  /// planner § planExpandEconomy "treasury < cheapest" arm). The
  /// boost composes with [forceCheapestRegimentBuild] so a GP that is
  /// told to force a build AND cannot currently afford one still gets
  /// the cargo signal to chase incoming riches.
  final bool boostTreasuryRecoveryCargo;

  /// True when the orchestrator should emit at least one peasant
  /// [RecruitWorkerOrder] before the build pass so a lock-recovery seller
  /// can grow raw labour toward a `castIron_from_iron` run
  /// (Refs #2847 § castIron labour population-bound fork).
  ///
  /// Set when [forceCheapestRegimentBuild] would also be true and
  /// [isCastIronLabourPopulationBoundForLockRecoverySeller] holds for the
  /// active player — material inputs are on hand, every owned worker is
  /// fed, yet the population ceiling is below one castIron run's labour.
  final bool boostCastIronLabourPeasantRecruitment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpandEconomyPlan &&
          other.forceCheapestRegimentBuild == forceCheapestRegimentBuild &&
          other.boostTreasuryRecoveryCargo == boostTreasuryRecoveryCargo &&
          other.boostCastIronLabourPeasantRecruitment ==
              boostCastIronLabourPeasantRecruitment;

  @override
  int get hashCode => Object.hash(
    forceCheapestRegimentBuild,
    boostTreasuryRecoveryCargo,
    boostCastIronLabourPeasantRecruitment,
  );

  @override
  String toString() =>
      'ExpandEconomyPlan('
      'forceCheapestRegimentBuild: $forceCheapestRegimentBuild, '
      'boostTreasuryRecoveryCargo: $boostTreasuryRecoveryCargo, '
      'boostCastIronLabourPeasantRecruitment: '
      '$boostCastIronLabourPeasantRecruitment)';
}

/// Returns the deterministic EXPAND-phase economy directive for the
/// active player as an [ExpandEconomyPlan].
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandEconomy):
///
///   "Force-regiment-rebuild when:
///      ow < 10 AND (
///        regimentCount == 0 AND hasInvadableProvinces
///          → set buildThreshold = 0, force cheapest regiment
///        OR
///        0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar
///          AND treasury >= cheapestRegimentBuildTreasuryCost
///          → set buildThreshold = 0, force cheapest regiment
///        OR
///        treasury < cheapestRegimentBuildTreasuryCost
///          → add cargo preference boost (deliver riches to stockpile)
///      )"
///
/// Effective treasury used by the regiment-affordability and cargo
/// arms is `player.treasury + pendingRichesTreasuryDelta(...)` so the
/// planner agrees with the build pipeline that already credits the
/// same-turn `richesToTreasury` phase income before `buildWork`
/// (Refs #2509 § Observer goal phases § EXPAND "Pending riches
/// treasury"). The OW improvements / NW suppressions arms of the spec
/// are out of scope for this planner contract — those orders are
/// produced by `planDevelopCivilian` (DEVELOP) and the conquest
/// army-move planner (EXPAND military) respectively; the EXPAND
/// economy planner only emits the build/cargo override directive.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) to read
///     [Player.treasury] and [Player.stockpile] (for the pending-riches
///     credit) and walks [WorldState.armies] via [regimentCountForPlayer]
///     for the standing regiment count.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ConquestSummary.oldWorldProvincesOwned] (quota guard) and
///     [ConquestSummary.invadableProvinceIdsSorted] (the "has invadable
///     frontier" arms of the spec).
///
/// Output:
///   - [ExpandEconomyPlan.defaultPlan] when the active player is at or
///     above [kObserverConquestMinOwProvincesPerGp] OW provinces (not
///     in EXPAND territory for this planner) or when
///     [Game.playerById] returns `null` (defensive guard for snapshots
///     pointing at non-existent players; matches the
///     [planExpandDeclareWar] guard).
///   - `forceCheapestRegimentBuild: true` when arm A
///     (`regimentCount == 0` and non-empty invadable OW frontier) holds.
///     Treasury is intentionally **not** part of arm A's gate per the
///     issue spec — the orchestrator's existing build pipeline still
///     handles the case where no regiment is affordable yet, but the
///     phase planner signals intent unconditionally so the rebuild
///     trap cannot stick.
///   - `forceCheapestRegimentBuild: true` when arm B
///     (`0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
///     and non-empty invadable OW frontier and effective treasury
///     ≥ cheapest regiment cost) holds.
///   - `boostTreasuryRecoveryCargo: true` when arm C
///     (effective treasury < cheapest regiment cost) holds, including
///     under the geographic peer-war lock. The cargo signal is the
///     planner-output the resource-need NW=0.60 weight floor in
///     `phase_priority_weights.dart` consumes (Refs #2847 §
///     Resource-need overrides); suppressing it under the lock would
///     also disable the override the soft-phase design depends on
///     (the H5 lock-suppression that earlier landed on this arm has
///     been reverted in favour of restoring the override coupling).
///     Composes with arm A whenever both predicates hold.
///   - `forceCheapestRegimentBuild: true` when arm D holds (Refs #2847
///     § H3): geographic peer-war lock with zero NW ownership,
///     `0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`,
///     and non-empty invadable OW frontier — without the arm-B treasury
///     gate (build pipeline affordability unchanged).
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ExpandEconomyPlan]s (Refs #2509 Must-have #7).
ExpandEconomyPlan planExpandEconomy({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return ExpandEconomyPlan.defaultPlan;
  }
  final player = game.playerById(snapshot.playerId);
  if (player == null) {
    return ExpandEconomyPlan.defaultPlan;
  }

  final hasInvadable = snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  final regimentCount = regimentCountForPlayer(game, snapshot.playerId);
  final effectiveTreasury =
      player.treasury + pendingRichesTreasuryDelta(stockpile: player.stockpile);
  final cheapest = cheapestRegimentBuildTreasuryCost();

  // Arm A: regimentCount == 0 AND hasInvadable -> force rebuild
  // (no treasury gate per spec; the build pipeline still applies its
  // own affordability check, but the directive remains so the phase
  // planner cannot be silently overridden by a treasury hiccup).
  final armA = regimentCount == 0 && hasInvadable;

  // Arm B: 0 < regimentCount < min AND hasInvadable AND effective
  // treasury affords the cheapest regiment.
  final armB =
      regimentCount > 0 &&
      regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar &&
      hasInvadable &&
      effectiveTreasury >= cheapest;

  final futilityLock = expandIsGeographicPeerWarLockNoNwTreasuryRecovery(
    game: game,
    snapshot: snapshot,
  );

  // Arm D (Refs #2847 § H3): trap-band force rebuild without treasury
  // gate when overseas cargo recovery is futile.
  final armD =
      futilityLock &&
      regimentCount > 0 &&
      regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar &&
      hasInvadable;

  // Arm C: effective treasury below cheapest regiment cost (independent
  // of regimentCount per the spec literal wording — boosts cargo so a
  // GP in EXPAND with low cash always benefits from delivering riches,
  // matching the SPEC/ai/ai-architecture.md "Treasury recovery cargo"
  // intent). Fires under the geographic peer-war lock too: the cargo
  // signal is what the resource-need NW=0.60 weight floor consumes in
  // `phase_priority_weights.dart`, so suppressing the boost under the
  // lock also disables the override the issue's soft-phase design
  // depends on (Refs #2847 § Resource-need overrides). Cargo delivery
  // may be futile until the GP acquires its first NW colony, but the
  // signal correctly marks the GP as needing overseas income so
  // downstream NW scoring biases activate.
  final armC = effectiveTreasury < cheapest;

  final forceRebuild = armA || armB || armD;
  // Treasury-independent like the economy-planner fabric staging path: the
  // recruit must be eligible on population-bound gate turns even when the
  // EXPAND rebuild directive is inactive (no invadable frontier that turn).
  final boostCastIronLabourPeasantRecruitment =
      isCastIronLabourPopulationBoundForLockRecoverySeller(
        game: game,
        playerId: snapshot.playerId,
      );

  return ExpandEconomyPlan(
    forceCheapestRegimentBuild: forceRebuild,
    boostTreasuryRecoveryCargo: armC,
    boostCastIronLabourPeasantRecruitment:
        boostCastIronLabourPeasantRecruitment,
  );
}
