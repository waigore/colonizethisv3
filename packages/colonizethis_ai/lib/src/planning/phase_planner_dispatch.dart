/// Phase planner dispatcher (Refs #2509 S5 foundation).
///
/// Routes a single deterministic phase-planning pass for the active player
/// given an [AIWorldSnapshot]. The dispatcher does **not** emit orders and
/// does **not** call any side-effecting subsystem (suggestion API,
/// validators, build pipeline). It composes the per-domain pure-function
/// planner calls — `expand_phase_planner.dart`,
/// `colonial_phase_planner.dart`, `develop_phase_planner.dart` — into a
/// single [PhasePlanOutcome] keyed on the resolved [ObserverGoalPhase].
///
/// The orchestrator wiring in `domain_planner_orchestrator.dart` will
/// translate [PhasePlanOutcome] into the existing `runDiplomacyPlanner` /
/// `runConquestArmyMovePlanner` / economy-pass call chain in a later
/// slice (still tracked under #2509 S5 alongside the legacy
/// `colonial_pressure.dart` and `diplomacy_planner_peace_targets.dart`
/// deletions under #2509 S1). This module deliberately ships before that
/// wiring so the dispatcher contract is testable in isolation, with zero
/// behaviour change for live AI play.
///
/// Phase-to-planner mapping (Refs `SPEC/ai/phase-planner-architecture.md`
/// § Orchestrator dispatch):
///
///   [ObserverGoalPhase.expand]
///     - `planExpandDeclareWar(game, snapshot)`
///     - `planExpandPeace(game, snapshot)`
///     - `planExpandEconomy(game, snapshot)`
///     - `planExpandMilitary(game, snapshot,
///                           declaredWarTargetFactionId: dwTarget)`
///       where `dwTarget` is the same call's `planExpandDeclareWar`
///       return value (the dispatcher pairs the planner outputs the same
///       way the orchestrator will).
///
///   [ObserverGoalPhase.colonialLite]
///     - All four EXPAND planners above (the OW push continues per the
///       issue spec "Begin NW overture/naval penetration without
///       weakening OW push").
///     - `planColonialLiteOvertures(game, snapshot)`
///     - `planColonialLiteNaval(game, snapshot)`
///
///   [ObserverGoalPhase.colonial]
///     - `planColonialAcquisition(game, snapshot,
///                                personalityId: personalityId)`
///     - `planColonialPeace(game, snapshot)`
///     - `planColonialCivilian(game, snapshot)`
///     - `planColonialMilitary(game, snapshot,
///                             colonialDeclaredWarTargetFactionId:
///                                 cwTarget)`
///     - `planColonialNaval(game, snapshot,
///                          colonialDeclaredWarTargetFactionId: cwTarget)`
///       where `cwTarget` is the acquisition target's `targetFactionId`
///       only when [AcquisitionMethod.declareWar] resolved (Join Empire
///       and `purchase_land` acquisitions do not gate the military /
///       naval invasion-transport plans on a war target).
///
///   [ObserverGoalPhase.develop]
///     - `planDevelopPeace(game, snapshot)`
///     - `planDevelopCivilian(game, snapshot)`
///
/// Suppression model:
///   - EXPAND fields in [PhasePlanOutcome] are populated only for EXPAND
///     and COLONIAL-lite phases. COLONIAL and DEVELOP outcomes leave
///     `expand*` fields at their default-plan / empty values.
///   - COLONIAL-lite fields (`colonialLiteOverturesSorted`,
///     `colonialLiteNavalPlan`) populate only for COLONIAL-lite.
///   - Full-COLONIAL fields (`colonialAcquisitionTarget`,
///     `colonialPeaceTargetFactionIdsSorted`, `colonialMilitaryPlan`,
///     `colonialNavalPlan`, `colonialCivilianWorkOrders`) populate only
///     for COLONIAL. They never populate under COLONIAL-lite — the
///     safeguard suppresses NW `declareWar` / `joinEmpire` /
///     `purchase_land` / invasion transport by spec.
///   - DEVELOP fields populate only for DEVELOP.
///
/// The dispatcher is pure and deterministic — identical inputs always
/// yield identical [PhasePlanOutcome] instances (Refs #2509 Must-have #7).
///
/// Soft-phase priority weights (Refs #2847 Phase 1): every dispatch
/// also computes a [PhasePriorityWeights] profile via
/// [computePhasePriorityWeights] and stores it on
/// [PhasePlanOutcome.priorityWeights]. The weights are advisory in
/// this slice — no production scoring site reads them yet.
/// Downstream slices (Refs #2847 Phase 2+) will wire the weight slot
/// into the existing scoring functions in
/// `phase_planner_*_filter.dart` and
/// `domain_planner_orchestrator.dart`. Hard structural suppression
/// (see `SPEC/ai/phase-planner-architecture.md` § Planner module
/// contracts) remains the production source of truth until that
/// consumer wiring lands.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'colonial_phase_planner.dart';
import 'develop_phase_planner.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'phase_priority_weights.dart';

/// Combined output of a single [runPhasePlanners] dispatch.
///
/// Carries the resolved [phase] and the per-domain planner outputs for
/// that phase. Slots not used by the active phase carry default-plan or
/// empty values (see [PhasePlanOutcome] field docs for the suppression
/// matrix); the orchestrator can therefore consume every field
/// unconditionally without re-checking the phase. The class is
/// `const`-friendly so default returns reuse a single shared instance
/// per planner type and per phase ([defaultExpand], [defaultColonialLite],
/// [defaultColonial], [defaultDevelop]).
class PhasePlanOutcome {
  const PhasePlanOutcome({
    required this.phase,
    this.expandDeclareWarTargetFactionId,
    this.expandPeaceTargetFactionIdsSorted = const <String>[],
    this.expandEconomyPlan = ExpandEconomyPlan.defaultPlan,
    this.expandMilitaryPlan = ExpandMilitaryPlan.defaultPlan,
    this.expandGpOnlyInvadableFrontierActive = false,
    this.expandPrimaryInvadableGpBlockerFactionId,
    this.colonialLiteOverturesSorted = const <String>[],
    this.colonialLiteNavalPlan = ColonialLiteNavalPlan.defaultPlan,
    this.colonialAcquisitionTarget,
    this.colonialPeaceTargetFactionIdsSorted = const <String>[],
    this.colonialMilitaryPlan = ColonialMilitaryPlan.defaultPlan,
    this.colonialNavalPlan = ColonialNavalPlan.defaultPlan,
    this.colonialCivilianWorkOrders = const <WorkOrder>[],
    this.developPeaceTargetFactionIdsSorted = const <String>[],
    this.developCivilianWorkOrders = const <WorkOrder>[],
    this.priorityWeights = PhasePriorityWeights.earlySprintDefault,
  });

  /// Resolved phase from [observerGoalPhaseFor]. Drives the suppression
  /// matrix on every other field: callers can read all fields
  /// unconditionally but only the slots listed for the active phase
  /// carry non-default content.
  final ObserverGoalPhase phase;

  /// EXPAND declare-war target from `planExpandDeclareWar`, or `null`
  /// when none of the priority arms qualify. Populated for
  /// [ObserverGoalPhase.expand] and [ObserverGoalPhase.colonialLite]
  /// (the OW push continues during the colonial-lite safeguard).
  /// `null` for [ObserverGoalPhase.colonial] and [ObserverGoalPhase.develop].
  final String? expandDeclareWarTargetFactionId;

  /// EXPAND peace targets from `planExpandPeace`. Same population
  /// matrix as [expandDeclareWarTargetFactionId].
  final List<String> expandPeaceTargetFactionIdsSorted;

  /// EXPAND economy directive from `planExpandEconomy`. Same population
  /// matrix as [expandDeclareWarTargetFactionId]; defaults to
  /// [ExpandEconomyPlan.defaultPlan] outside EXPAND / COLONIAL-lite.
  final ExpandEconomyPlan expandEconomyPlan;

  /// EXPAND conquest destination filter from `planExpandMilitary`. The
  /// dispatcher passes [expandDeclareWarTargetFactionId] as the
  /// `declaredWarTargetFactionId` argument so the military plan is
  /// paired with the declare-war pick the same way the orchestrator
  /// will.
  final ExpandMilitaryPlan expandMilitaryPlan;

  /// Whether the invadable Old World frontier is held only by Great
  /// Powers (no minor owns any invadable OW province). Populated from
  /// [expandIsOldWorldGpOnlyInvadableFrontier] for
  /// [ObserverGoalPhase.expand] and [ObserverGoalPhase.colonialLite];
  /// `false` for COLONIAL and DEVELOP.
  final bool expandGpOnlyInvadableFrontierActive;

  /// Primary OW invadable GP blocker from
  /// [expandPrimaryInvadableOldWorldGpBlocker]. Populated for EXPAND and
  /// COLONIAL-lite; `null` for COLONIAL and DEVELOP or when no GP owns
  /// an invadable OW province.
  final String? expandPrimaryInvadableGpBlockerFactionId;

  /// COLONIAL-lite overtures from `planColonialLiteOvertures`. Populated
  /// only for [ObserverGoalPhase.colonialLite]; empty otherwise.
  final List<String> colonialLiteOverturesSorted;

  /// COLONIAL-lite naval directive from `planColonialLiteNaval`.
  /// Populated only for [ObserverGoalPhase.colonialLite]; defaults to
  /// [ColonialLiteNavalPlan.defaultPlan] otherwise.
  final ColonialLiteNavalPlan colonialLiteNavalPlan;

  /// Full-COLONIAL acquisition target from `planColonialAcquisition`,
  /// or `null` when no acquisition method is achievable this turn.
  /// Populated only for [ObserverGoalPhase.colonial]; structurally
  /// suppressed under COLONIAL-lite (the safeguard does not emit
  /// `declareWar` / `joinEmpire` / `purchase_land`).
  final ColonialAcquisitionTarget? colonialAcquisitionTarget;

  /// Full-COLONIAL peace targets from `planColonialPeace`. Populated
  /// only for [ObserverGoalPhase.colonial]; empty otherwise.
  final List<String> colonialPeaceTargetFactionIdsSorted;

  /// Full-COLONIAL conquest destination filter from
  /// `planColonialMilitary`. The dispatcher passes the acquisition
  /// target's `targetFactionId` as `colonialDeclaredWarTargetFactionId`
  /// only when [colonialAcquisitionTarget]'s method is
  /// [AcquisitionMethod.declareWar]; otherwise it passes `null` so the
  /// orchestrator picks via the at-war fallback arm.
  final ColonialMilitaryPlan colonialMilitaryPlan;

  /// Full-COLONIAL invasion-transport directive from
  /// `planColonialNaval`. Pairs with [colonialMilitaryPlan] on the
  /// same `colonialDeclaredWarTargetFactionId` argument so the two
  /// plans target the same provinces this turn when an
  /// [AcquisitionMethod.declareWar] target was chosen.
  final ColonialNavalPlan colonialNavalPlan;

  /// Full-COLONIAL civilian build orders from `planColonialCivilian`.
  /// Populated only for [ObserverGoalPhase.colonial]; empty otherwise.
  final List<WorkOrder> colonialCivilianWorkOrders;

  /// DEVELOP peace targets from `planDevelopPeace`. Populated only for
  /// [ObserverGoalPhase.develop]; empty otherwise.
  final List<String> developPeaceTargetFactionIdsSorted;

  /// DEVELOP civilian build orders from `planDevelopCivilian`.
  /// Populated only for [ObserverGoalPhase.develop]; empty otherwise.
  final List<WorkOrder> developCivilianWorkOrders;

  /// Soft-phase priority weight profile for this dispatch (Refs
  /// #2847 Phase 1 scaffolding). Computed by
  /// [computePhasePriorityWeights] from
  /// `(snapshot, game, expandEconomyPlan)`. The slot is
  /// **advisory** in this slice — no production scoring site reads
  /// it yet. Downstream consumer-wiring slices (Refs #2847 Phase 2+)
  /// will migrate `phase_planner_*_filter.dart` resolvers and
  /// `domain_planner_orchestrator.dart` scoring sites from hard
  /// structural suppression to weight multipliers sourced from this
  /// slot.
  ///
  /// Defaults to [PhasePriorityWeights.earlySprintDefault] for
  /// const-friendly construction; [runPhasePlanners] overrides the
  /// default with the actual computed weight profile on every
  /// dispatch.
  final PhasePriorityWeights priorityWeights;

  /// Reusable "EXPAND defaults, no targets" outcome. Returned when the
  /// EXPAND-phase planner set short-circuits at outer guards (missing
  /// player, empty OW invadable, OW at/above quota).
  static const PhasePlanOutcome defaultExpand = PhasePlanOutcome(
    phase: ObserverGoalPhase.expand,
  );

  /// Reusable "COLONIAL-lite defaults" outcome. Returned when both
  /// EXPAND and COLONIAL-lite planner sets short-circuit at outer
  /// guards under the colonial-lite safeguard.
  static const PhasePlanOutcome defaultColonialLite = PhasePlanOutcome(
    phase: ObserverGoalPhase.colonialLite,
  );

  /// Reusable "COLONIAL defaults" outcome. Returned when the
  /// full-COLONIAL planner set short-circuits at outer guards (missing
  /// player, empty NW invadable, below quota).
  static const PhasePlanOutcome defaultColonial = PhasePlanOutcome(
    phase: ObserverGoalPhase.colonial,
  );

  /// Reusable "DEVELOP defaults" outcome. Returned when both DEVELOP
  /// planners short-circuit (no GP wars, no owned land, no idle
  /// Builders).
  static const PhasePlanOutcome defaultDevelop = PhasePlanOutcome(
    phase: ObserverGoalPhase.develop,
  );

  @override
  String toString() =>
      'PhasePlanOutcome(phase: $phase, '
      'expandDeclareWarTargetFactionId: $expandDeclareWarTargetFactionId, '
      'expandPeaceTargetFactionIdsSorted: '
      '$expandPeaceTargetFactionIdsSorted, '
      'expandEconomyPlan: $expandEconomyPlan, '
      'expandMilitaryPlan: $expandMilitaryPlan, '
      'expandGpOnlyInvadableFrontierActive: '
      '$expandGpOnlyInvadableFrontierActive, '
      'expandPrimaryInvadableGpBlockerFactionId: '
      '$expandPrimaryInvadableGpBlockerFactionId, '
      'colonialLiteOverturesSorted: $colonialLiteOverturesSorted, '
      'colonialLiteNavalPlan: $colonialLiteNavalPlan, '
      'colonialAcquisitionTarget: $colonialAcquisitionTarget, '
      'colonialPeaceTargetFactionIdsSorted: '
      '$colonialPeaceTargetFactionIdsSorted, '
      'colonialMilitaryPlan: $colonialMilitaryPlan, '
      'colonialNavalPlan: $colonialNavalPlan, '
      'colonialCivilianWorkOrders: $colonialCivilianWorkOrders, '
      'developPeaceTargetFactionIdsSorted: '
      '$developPeaceTargetFactionIdsSorted, '
      'developCivilianWorkOrders: $developCivilianWorkOrders, '
      'priorityWeights: $priorityWeights)';
}

/// Returns the [PhasePlanOutcome] for the active player on this turn by
/// dispatching to the per-phase pure-function planner module corresponding
/// to [observerGoalPhaseFor]'s result.
///
/// Inputs:
///   - [game]: source of player roster, world state, and faction lookups
///     consumed by the per-phase planners. The dispatcher passes the
///     same [Game] instance into every per-domain planner so memoizable
///     helpers (e.g. `getProvinceOwnerMap`) see consistent state across
///     the dispatch.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying the conquest /
///     colonial / threats / economy summaries every planner reads.
///   - [personalityId]: optional active-player personality id. Forwarded
///     to `planColonialAcquisition` for the Must-have #4 personality
///     bias (`napoleon` etc. prefer `declareWar` over `joinEmpire`).
///     `null` keeps the legacy Join Empire-first ordering. The argument
///     is dead for non-COLONIAL phases (no other planner consumes it).
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [PhasePlanOutcome] instances (Refs #2509 Must-have
/// #7). It performs no I/O, no logging, and no order emission.
PhasePlanOutcome runPhasePlanners({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? personalityId,
}) {
  final phase = observerGoalPhaseFor(snapshot: snapshot, game: game);
  switch (phase) {
    case ObserverGoalPhase.expand:
      return _expandOutcome(game: game, snapshot: snapshot);
    case ObserverGoalPhase.colonialLite:
      return _colonialLiteOutcome(game: game, snapshot: snapshot);
    case ObserverGoalPhase.colonial:
      return _colonialOutcome(
        game: game,
        snapshot: snapshot,
        personalityId: personalityId,
      );
    case ObserverGoalPhase.develop:
      return _developOutcome(game: game, snapshot: snapshot);
  }
}

PhasePlanOutcome _expandOutcome({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final declareWarTarget = planExpandDeclareWar(game: game, snapshot: snapshot);
  final expandFrontier = _expandFrontierContext(game: game, snapshot: snapshot);
  final expandEconomyPlan = planExpandEconomy(game: game, snapshot: snapshot);
  return PhasePlanOutcome(
    phase: ObserverGoalPhase.expand,
    expandDeclareWarTargetFactionId: declareWarTarget,
    expandPeaceTargetFactionIdsSorted: planExpandPeace(
      game: game,
      snapshot: snapshot,
    ),
    expandEconomyPlan: expandEconomyPlan,
    expandMilitaryPlan: planExpandMilitary(
      game: game,
      snapshot: snapshot,
      declaredWarTargetFactionId: declareWarTarget,
    ),
    expandGpOnlyInvadableFrontierActive:
        expandFrontier.gpOnlyInvadableFrontierActive,
    expandPrimaryInvadableGpBlockerFactionId:
        expandFrontier.primaryInvadableGpBlockerFactionId,
    priorityWeights: computePhasePriorityWeights(
      snapshot: snapshot,
      game: game,
      expandEconomyPlan: expandEconomyPlan,
    ),
  );
}

PhasePlanOutcome _colonialLiteOutcome({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final declareWarTarget = planExpandDeclareWar(game: game, snapshot: snapshot);
  final expandFrontier = _expandFrontierContext(game: game, snapshot: snapshot);
  final expandEconomyPlan = planExpandEconomy(game: game, snapshot: snapshot);
  return PhasePlanOutcome(
    phase: ObserverGoalPhase.colonialLite,
    expandDeclareWarTargetFactionId: declareWarTarget,
    expandPeaceTargetFactionIdsSorted: planExpandPeace(
      game: game,
      snapshot: snapshot,
    ),
    expandEconomyPlan: expandEconomyPlan,
    expandMilitaryPlan: planExpandMilitary(
      game: game,
      snapshot: snapshot,
      declaredWarTargetFactionId: declareWarTarget,
    ),
    expandGpOnlyInvadableFrontierActive:
        expandFrontier.gpOnlyInvadableFrontierActive,
    expandPrimaryInvadableGpBlockerFactionId:
        expandFrontier.primaryInvadableGpBlockerFactionId,
    colonialLiteOverturesSorted: planColonialLiteOvertures(
      game: game,
      snapshot: snapshot,
    ),
    colonialLiteNavalPlan: planColonialLiteNaval(
      game: game,
      snapshot: snapshot,
    ),
    priorityWeights: computePhasePriorityWeights(
      snapshot: snapshot,
      game: game,
      expandEconomyPlan: expandEconomyPlan,
    ),
  );
}

PhasePlanOutcome _colonialOutcome({
  required Game game,
  required AIWorldSnapshot snapshot,
  required String? personalityId,
}) {
  final acquisition = planColonialAcquisition(
    game: game,
    snapshot: snapshot,
    personalityId: personalityId,
  );
  final declaredColonialTarget =
      (acquisition != null &&
          acquisition.method == AcquisitionMethod.declareWar)
      ? acquisition.targetFactionId
      : null;
  return PhasePlanOutcome(
    phase: ObserverGoalPhase.colonial,
    colonialAcquisitionTarget: acquisition,
    colonialPeaceTargetFactionIdsSorted: planColonialPeace(
      game: game,
      snapshot: snapshot,
    ),
    colonialMilitaryPlan: planColonialMilitary(
      game: game,
      snapshot: snapshot,
      colonialDeclaredWarTargetFactionId: declaredColonialTarget,
    ),
    colonialNavalPlan: planColonialNaval(
      game: game,
      snapshot: snapshot,
      colonialDeclaredWarTargetFactionId: declaredColonialTarget,
    ),
    colonialCivilianWorkOrders: planColonialCivilian(
      game: game,
      snapshot: snapshot,
    ),
    priorityWeights: computePhasePriorityWeights(
      snapshot: snapshot,
      game: game,
      expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
    ),
  );
}

PhasePlanOutcome _developOutcome({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  return PhasePlanOutcome(
    phase: ObserverGoalPhase.develop,
    developPeaceTargetFactionIdsSorted: planDevelopPeace(
      game: game,
      snapshot: snapshot,
    ),
    developCivilianWorkOrders: planDevelopCivilian(
      game: game,
      snapshot: snapshot,
    ),
    priorityWeights: computePhasePriorityWeights(
      snapshot: snapshot,
      game: game,
      expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
    ),
  );
}

({
  bool gpOnlyInvadableFrontierActive,
  String? primaryInvadableGpBlockerFactionId,
})
_expandFrontierContext({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  return (
    gpOnlyInvadableFrontierActive: expandIsOldWorldGpOnlyInvadableFrontier(
      game: game,
      snapshot: snapshot,
    ),
    primaryInvadableGpBlockerFactionId: expandPrimaryInvadableOldWorldGpBlocker(
      game: game,
      snapshot: snapshot,
    ),
  );
}
