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
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch_outcome.dart';
import 'phase_planner_dispatch_phases.dart';

export 'phase_planner_dispatch_outcome.dart' show PhasePlanOutcome;


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
/// Whether full-COLONIAL planner outputs on [outcome] may be consumed by
/// orchestrator adapters (Refs #2847 EXPAND universal colonial dispatch).
///
/// [ObserverGoalPhase.colonialLite] stays excluded — the safeguard
/// suppresses NW invasion transport and army moves per issue #2509.
bool phasePlanFullColonialOutputsActive(PhasePlanOutcome outcome) {
  switch (outcome.phase) {
    case ObserverGoalPhase.colonial:
      return true;
    case ObserverGoalPhase.colonialLite:
    case ObserverGoalPhase.develop:
      return false;
    case ObserverGoalPhase.expand:
      return outcome.priorityWeights.newWorldAcquisition > 0.0;
  }
}

PhasePlanOutcome runPhasePlanners({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? personalityId,
}) {
  final phase = observerGoalPhaseFor(snapshot: snapshot, game: game);
  switch (phase) {
    case ObserverGoalPhase.expand:
      return expandPhasePlanOutcome(
        game: game,
        snapshot: snapshot,
        personalityId: personalityId,
      );
    case ObserverGoalPhase.colonialLite:
      return colonialLitePhasePlanOutcome(game: game, snapshot: snapshot);
    case ObserverGoalPhase.colonial:
      return colonialPhasePlanOutcome(
        game: game,
        snapshot: snapshot,
        personalityId: personalityId,
      );
    case ObserverGoalPhase.develop:
      return developPhasePlanOutcome(game: game, snapshot: snapshot);
  }
}
