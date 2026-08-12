/// [PhasePlanOutcome] value type for [runPhasePlanners] (Refs #2509 S5 / #4079 Slice C).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'colonial_phase_planner.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch_outcome_defaults.dart';
import 'phase_planner_dispatch_outcome_to_string.dart';
import 'phase_priority_weights.dart';

export 'phase_planner_dispatch_outcome_defaults.dart';

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
    this.expandDistractionPeaceTargetFactionIdsSorted = const <String>[],
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
  /// matrix as [expandDeclareWarTargetFactionId]. Great-Power-only by
  /// construction (`planExpandPeace` filters [ThreatSummary.atWarWith]
  /// to [Game.playerById] members); minor / tribe distraction peace is
  /// carried separately on [expandDistractionPeaceTargetFactionIdsSorted].
  final List<String> expandPeaceTargetFactionIdsSorted;

  /// EXPAND below-quota tribe distraction peace targets (Refs #2847
  /// § H5). Sourced from
  /// [belowQuotaRegimentThinTribeDistractionPeaceTargets] — the at-war
  /// tribes owning no invadable OW frontier province, for a regiment-thin
  /// below-quota GP, sorted ascending. Same population matrix as
  /// [expandDeclareWarTargetFactionId] (EXPAND / COLONIAL-lite only;
  /// empty for COLONIAL / DEVELOP).
  ///
  /// Carried separately from [expandPeaceTargetFactionIdsSorted] so the
  /// Great-Power-only contract of `planExpandPeace` stays intact while
  /// the production diplomacy path
  /// (`diplomacy_planner.dart` `_stalledPeacePlannerResultIfNeeded` via
  /// `distractionPeaceTargetsFromPhasePlan`) still emits the
  /// distraction `offerPeace` orders the no-`phasePlan`
  /// `collectStalledGreatPowerPeaceTargets` fallback already carries.
  /// Restores the distraction-peace pivot to the production phase-plan
  /// path it regressed out of when the S5 GP-only `planExpandPeace`
  /// adapter took over (Refs #2509 S5; #2847 § H5).
  final List<String> expandDistractionPeaceTargetFactionIdsSorted;

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
  /// [isOldWorldGpOnlyInvadableFrontier] for
  /// [ObserverGoalPhase.expand] and [ObserverGoalPhase.colonialLite];
  /// `false` for COLONIAL and DEVELOP.
  final bool expandGpOnlyInvadableFrontierActive;

  /// Primary OW invadable GP blocker from
  /// [primaryInvadableOldWorldGpBlocker]. Populated for EXPAND and
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
  static const PhasePlanOutcome defaultExpand = phasePlanOutcomeDefaultExpand;

  /// Reusable "COLONIAL-lite defaults" outcome. Returned when both
  /// EXPAND and COLONIAL-lite planner sets short-circuit at outer
  /// guards under the colonial-lite safeguard.
  static const PhasePlanOutcome defaultColonialLite =
      phasePlanOutcomeDefaultColonialLite;

  /// Reusable "COLONIAL defaults" outcome. Returned when the
  /// full-COLONIAL planner set short-circuits at outer guards (missing
  /// player, empty NW invadable, below quota).
  static const PhasePlanOutcome defaultColonial = phasePlanOutcomeDefaultColonial;

  /// Reusable "DEVELOP defaults" outcome. Returned when both DEVELOP
  /// planners short-circuit (no GP wars, no owned land, no idle
  /// Builders).
  static const PhasePlanOutcome defaultDevelop = phasePlanOutcomeDefaultDevelop;

  @override
  String toString() => phasePlanOutcomeToString(this);
}
