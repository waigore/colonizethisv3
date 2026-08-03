import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'diplomatic_candidate_scoring_shared.dart';
import 'expand_phase_planner.dart';
import 'goal_manager.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_diplomacy_filter.dart';
import 'phase_planner_dispatch.dart';
import 'planning_helpers.dart'
    show
        anyInvadableProvinceOwnedByGreatPower,
        factionOwnsInvadableOldWorldProvince;
import 'planning_imports.dart';

export 'diplomatic_candidate_scoring_declare_war_context_projection.dart';
export 'diplomatic_candidate_scoring_declare_war_context_build.dart';

/// Context builder for the declare-war scoring family.
///
/// Holds [DeclareWarTargetContext], the precomputed per-target projection
/// consumed by the declare-war score ladder in
/// `diplomatic_candidate_scoring_declare_war.dart` and the bonus addends in
/// `diplomatic_candidate_scoring_declare_war_bonuses.dart`. Split out of the
/// score-ladder module so the context-builder and score-ladder concerns live
/// in separate files (Refs #3749; de-parted into its own library Refs #4079
/// Slice A — bumped to package-private (no leading `_`) so sibling scoring
/// libraries can import it). Behaviour is unchanged.
final class DeclareWarTargetContext {
  DeclareWarTargetContext({
    required this.order,
    required this.nationId,
    required this.game,
    required this.snapshot,
    required this.agendaId,
    required this.thresholds,
    required this.maxRelationForDeclareWar,
    required this.behindVictoryPace,
    required this.suppressGpDeclareWar,
    required this.invadableOwners,
    required this.provinceOwner,
    required this.warCooldownTurns,
    required this.currentTurn,
    required this.anyMinorOwnsOldWorld,
    required this.primaryGoal,
    required this.warDesireForTarget,
    required this.relation,
    required this.relationScore,
    required this.adjacentOwners,
    required this.isAdjacentOwner,
    required this.isColonialAdjacentOwner,
    required this.isMinorTarget,
    required this.ownsInvadableNw,
    required this.colonialPressure,
    required this.nwAcquisitionWeight,
    required this.oldWorldConquestWeight,
    required this.isTribeTarget,
    required this.stalledOwExpansion,
    required this.ownsInvadableOwMinor,
    required this.weakerDistantMinor,
    required this.hasInvadableMinorOwner,
    required this.minorsHoldOldWorldProvinces,
    required this.atWarInvadableOwMinor,
    required this.activeMinorConflicts,
    required this.hasAdjacentInvadableMinorOwner,
    required this.isAdjacentGp,
    required this.invadableGpBlocker,
    required this.invadableGpBlockerWeaker,
    required this.invadableOwOwnedByGp,
    required this.tribeOwnsOwInvadable,
    required this.phasePlan,
  });

  final DiplomaticOrder order;
  final String nationId;
  final Game game;
  final AIWorldSnapshot snapshot;
  final String agendaId;
  final PersonalityThresholds thresholds;
  final int maxRelationForDeclareWar;
  final bool behindVictoryPace;
  final bool suppressGpDeclareWar;
  final Set<String> invadableOwners;
  final Map<String, String> provinceOwner;
  final int warCooldownTurns;
  final int currentTurn;
  final bool anyMinorOwnsOldWorld;
  final StrategicGoal? primaryGoal;
  final int Function(String targetFactionId, num relationScore)
  warDesireForTarget;
  final DiplomacyRelation? relation;
  final num relationScore;
  final List<String> adjacentOwners;
  final bool isAdjacentOwner;
  final bool isColonialAdjacentOwner;
  final bool isMinorTarget;
  final bool ownsInvadableNw;
  final bool colonialPressure;

  /// Soft-phase NW acquisition weight for the active player turn (Refs
  /// #2847 Phase 3 diplomacy declare-war wiring). Sourced from
  /// `resolvePhaseDiplomacyDeclareWarColonialPressureWeight(phasePlan)`
  /// when a [PhasePlanOutcome] is threaded through, otherwise mapped
  /// from the legacy boolean
  /// `shouldSuppressNewWorldDeclareWarInvasionAndPurchase` (`true ->
  /// 0.0`, `false -> 1.0`) so callers without a phase plan keep the
  /// pre-soft-phase hard-suppress semantics.
  ///
  /// Consumed by `_declareWarSuppressedExpandColonialScore`,
  /// `_declareWarSuppressedColonialLiteScore`, and the
  /// `_declareWarSuppressedWarConcentrationScore` colonial-pressure
  /// carve-out: when `nwAcquisitionWeight <= 0.0` the NW colonial
  /// declare-war candidates (tribe / NW owner / colonial-adjacent
  /// owner) collapse to `kDeclareWarNonAdjacentSuppressedScore`
  /// (legacy hard-suppress equivalent); when `> 0.0` the NW candidates
  /// remain scorable and the colonial-pressure carve-out preserves
  /// stalled-OW tribe declare-war scoring. The default soft-phase
  /// curve never produces `0.0` (min `0.05` at OW≤7) so the production
  /// hot path now keeps NW declare-war reachable at low priority
  /// instead of being structurally collapsed under EXPAND /
  /// COLONIAL-lite (Refs #2847 § Soft-phase priority weights).
  final double nwAcquisitionWeight;

  /// Soft-phase OW conquest weight for the active player turn (Refs
  /// #2847 Phase 3 diplomacy declare-war OW scoring). Sourced from
  /// `resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(phasePlan)`
  /// when a [PhasePlanOutcome] is threaded through; callers without a
  /// phase plan use `1.0` (legacy full-magnitude OW bonuses).
  ///
  /// Consumed by `_scoreDeclareWarBonuses` via
  /// [declareWarOldWorldConquestScaledBonus] on OW-expansion addends
  /// (stalled-OW minor priority, adjacent invadable minor bonuses,
  /// invadable-GP-blocker bonuses, score floors). NW-tribe addends use
  /// [nwAcquisitionWeight] instead.
  final double oldWorldConquestWeight;

  final bool isTribeTarget;

  /// Whether the active player's Old-World expansion is under observer
  /// conquest expansion pressure
  /// (`isObserverConquestExpansionPressure(snapshot.conquest
  /// .oldWorldProvincesOwned)`), computed once in [build].
  ///
  /// Single source of truth for the observer expansion-pressure projection in
  /// the declare-war scoring family: the suppression and bonus branches read
  /// this precomputed field instead of recomputing the predicate inline (Refs
  /// #3717 diplomatic-scoring dedup), avoiding redundant per-branch
  /// recomputation on the hot planning path
  /// (`colonizethis-turn-resolution-budget.mdc`).
  final bool stalledOwExpansion;
  final bool ownsInvadableOwMinor;
  final bool weakerDistantMinor;
  final bool hasInvadableMinorOwner;
  final bool minorsHoldOldWorldProvinces;
  final bool atWarInvadableOwMinor;
  final Set<String> activeMinorConflicts;
  final bool hasAdjacentInvadableMinorOwner;
  final bool isAdjacentGp;
  final bool invadableGpBlocker;
  final bool invadableGpBlockerWeaker;
  final bool invadableOwOwnedByGp;
  final bool tribeOwnsOwInvadable;

  /// Optional dispatched phase plan threaded from
  /// `runDiplomacyPlannerWithResult`. When non-null, the suppression
  /// scoring branches (`_declareWarSuppressedDevelopPhaseScore`,
  /// `_declareWarSuppressedColonialLiteScore`,
  /// `_declareWarSuppressedExpandColonialScore`) read the active phase
  /// off this single dispatched value via the
  /// `resolvePhaseDiplomacyDeclareWar*Suppression*Active` resolvers
  /// instead of recomputing `observerGoalPhaseFor` per candidate.
  ///
  /// `null` preserves the legacy per-candidate phase compute for tests
  /// and other callers that pre-date the orchestrator threading; the
  /// orchestrator always passes `phasePlan` so production runs route
  /// through the phase-derived value (Refs #2509 S5).
  final PhasePlanOutcome? phasePlan;
}
