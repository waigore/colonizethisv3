/// Soft-phase priority weight scaffolding for [runPhasePlanners] (Refs
/// #2847 Phase 1 — weight system core).
///
/// Issue #2847 redesigns the phase-planner architecture from hard
/// structural suppression (EXPAND never imports
/// `colonial_phase_planner.dart`; the dispatcher omits whole planner
/// modules per phase) to **soft priority weighting** where every
/// planner module is callable from every phase and the active phase
/// only biases candidate scores via per-domain weight multipliers.
///
/// This module ships the **scaffolding-only** slice of that redesign:
/// [PhasePriorityWeights] is a pure value class produced by
/// [computePhasePriorityWeights] from a single
/// `(AIWorldSnapshot, Game, ExpandEconomyPlan)` triple, and
/// [PhasePlanOutcome] carries the result on a new `priorityWeights`
/// slot. The weights are **not consumed by any production scoring
/// site in this slice** — they are advisory inputs that downstream
/// slices (Refs #2847 Phase 2+) will wire into the existing scoring
/// functions in `phase_planner_*_filter.dart` and
/// `domain_planner_orchestrator.dart`. Hard structural suppression as
/// described in `SPEC/ai/phase-planner-architecture.md` § Planner
/// module contracts remains the production source of truth until that
/// consumer wiring lands.
///
/// The scaffolding ships in isolation so the weight contract (curve
/// values, override predicates, determinism) is testable on its own
/// without disturbing any live behaviour. See
/// `SPEC/ai/phase-planner-architecture.md` § Soft-phase priority
/// weights for the normative curve / override tables.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'expand_phase_planner.dart' show ExpandEconomyPlan;

/// Per-domain priority weights for one phase-planner dispatch (Refs
/// #2847 § Soft-phase priority weights).
///
/// Every field is a deterministic `double` in `[0.0, 1.0]` derived
/// from the `(AIWorldSnapshot, Game, ExpandEconomyPlan)` triple by
/// [computePhasePriorityWeights]. The four weights model "how much
/// should the planner bias toward this domain right now":
///
/// - [oldWorldConquest] — OW invasion / declare-war / military-pass
///   priority.
/// - [newWorldAcquisition] — NW acquisition (declareWar, joinEmpire,
///   purchase_land, invasion-transport) priority.
/// - [oldWorldCivilian] — OW civilian build / improvement priority.
/// - [newWorldCivilian] — NW civilian build / improvement priority.
///
/// Curve plateau values below `kPhasePriorityCurveEarlySprintCeiling`
/// keep the early-game OW sprint dominant; the curve crosses near OW
/// = `kObserverConquestMinOwProvincesPerGp` (10) so behaviour at the
/// hard-phase EXPAND→COLONIAL inflection approximates today's
/// dispatch. Override predicates lift NW floors when the snapshot
/// indicates a GP cannot bootstrap OW conquest without an income or
/// regiment lift; `oldWorldConquest` is never weakened by an
/// override.
///
/// Equality and `hashCode` are structural so identical inputs
/// produce `==`-equal instances (Refs #2509 Must-have #7
/// determinism).
class PhasePriorityWeights {
  const PhasePriorityWeights({
    required this.oldWorldConquest,
    required this.newWorldAcquisition,
    required this.oldWorldCivilian,
    required this.newWorldCivilian,
  });

  final double oldWorldConquest;
  final double newWorldAcquisition;
  final double oldWorldCivilian;
  final double newWorldCivilian;

  /// Reusable "early-sprint default" weights returned by
  /// [computePhasePriorityWeights] for any `oldWorldProvincesOwned`
  /// value at or below [kPhasePriorityCurveEarlySprintCeiling] when
  /// no override predicate fires. Used as the dispatcher's default
  /// slot value so the scaffolding produces a stable instance for
  /// short-circuit returns and test fixtures.
  static const PhasePriorityWeights earlySprintDefault = PhasePriorityWeights(
    oldWorldConquest: 0.95,
    newWorldAcquisition: 0.05,
    oldWorldCivilian: 0.90,
    newWorldCivilian: 0.10,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhasePriorityWeights &&
          other.oldWorldConquest == oldWorldConquest &&
          other.newWorldAcquisition == newWorldAcquisition &&
          other.oldWorldCivilian == oldWorldCivilian &&
          other.newWorldCivilian == newWorldCivilian;

  @override
  int get hashCode => Object.hash(
    oldWorldConquest,
    newWorldAcquisition,
    oldWorldCivilian,
    newWorldCivilian,
  );

  @override
  String toString() =>
      'PhasePriorityWeights('
      'oldWorldConquest: $oldWorldConquest, '
      'newWorldAcquisition: $newWorldAcquisition, '
      'oldWorldCivilian: $oldWorldCivilian, '
      'newWorldCivilian: $newWorldCivilian)';
}

/// Upper-bound OW count for the early-sprint plateau on the priority
/// curves. At and below this `ow` value every weight value sits on
/// its early-sprint plateau (`oldWorldConquest = 0.95`,
/// `newWorldAcquisition = 0.05`, `oldWorldCivilian = 0.90`,
/// `newWorldCivilian = 0.10`).
const int kPhasePriorityCurveEarlySprintCeiling = 7;

/// NW acquisition floor lifted when the treasury-recovery resource
/// need fires (Refs #2847 § Resource-need overrides). Predicate:
/// `economy.treasury == 0 && colonial.newWorldProvincesOwned == 0
/// && expandEconomyPlan.boostTreasuryRecoveryCargo == true`.
const double kPhasePriorityNwTreasuryRecoveryFloor = 0.60;

/// NW acquisition floor lifted when the zero-regiment resource need
/// fires (Refs #2847 § Resource-need overrides). Predicate:
/// `regimentCountForPlayer(game, snapshot.playerId) == 0
/// && conquest.invadableProvinceIdsSorted.isNotEmpty`.
const double kPhasePriorityNwZeroRegimentFloor = 0.30;

/// Returns the [PhasePriorityWeights] for one phase-planner dispatch
/// (Refs #2847 Phase 1 scaffolding).
///
/// The function is **pure** and deterministic — identical
/// `(snapshot, game, expandEconomyPlan)` inputs always yield
/// field-equal [PhasePriorityWeights] (Refs #2509 Must-have #7). It
/// performs no I/O, no logging, and never invokes any planner
/// module.
///
/// Inputs:
///   - [snapshot] — `AIWorldSnapshot` for the active player; the
///     function reads `conquest.oldWorldProvincesOwned`,
///     `conquest.invadableProvinceIdsSorted`,
///     `colonial.newWorldProvincesOwned`, and `economy.treasury`.
///   - [game] — required only by the zero-regiment override
///     predicate, which calls [regimentCountForPlayer] on the active
///     player. The function does not mutate [game].
///   - [expandEconomyPlan] — the `ExpandEconomyPlan` already
///     computed by `planExpandEconomy` for this turn (carried on
///     [PhasePlanOutcome.expandEconomyPlan]). Pass
///     [ExpandEconomyPlan.defaultPlan] when no EXPAND plan is
///     available (e.g. COLONIAL / DEVELOP phases where EXPAND
///     planners do not run, or test fixtures).
PhasePriorityWeights computePhasePriorityWeights({
  required AIWorldSnapshot snapshot,
  required Game game,
  required ExpandEconomyPlan expandEconomyPlan,
}) {
  final ow = snapshot.conquest.oldWorldProvincesOwned;
  final curve = _curveWeightsForOw(ow);
  final nwFloor = _nwAcquisitionFloor(
    snapshot: snapshot,
    game: game,
    expandEconomyPlan: expandEconomyPlan,
  );
  final nwAcquisition = nwFloor > curve.newWorldAcquisition
      ? nwFloor
      : curve.newWorldAcquisition;
  if (nwAcquisition == curve.newWorldAcquisition) {
    return curve;
  }
  return PhasePriorityWeights(
    oldWorldConquest: curve.oldWorldConquest,
    newWorldAcquisition: nwAcquisition,
    oldWorldCivilian: curve.oldWorldCivilian,
    newWorldCivilian: curve.newWorldCivilian,
  );
}

PhasePriorityWeights _curveWeightsForOw(int ow) {
  if (ow <= kPhasePriorityCurveEarlySprintCeiling) {
    return PhasePriorityWeights.earlySprintDefault;
  }
  switch (ow) {
    case 8:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.90,
        newWorldAcquisition: 0.10,
        oldWorldCivilian: 0.85,
        newWorldCivilian: 0.15,
      );
    case 9:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.80,
        newWorldAcquisition: 0.20,
        oldWorldCivilian: 0.75,
        newWorldCivilian: 0.25,
      );
    case 10:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.60,
        newWorldAcquisition: 0.40,
        oldWorldCivilian: 0.55,
        newWorldCivilian: 0.45,
      );
    case 11:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.40,
        newWorldAcquisition: 0.60,
        oldWorldCivilian: 0.35,
        newWorldCivilian: 0.65,
      );
    case 12:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.20,
        newWorldAcquisition: 0.80,
        oldWorldCivilian: 0.15,
        newWorldCivilian: 0.85,
      );
    default:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.10,
        newWorldAcquisition: 0.90,
        oldWorldCivilian: 0.05,
        newWorldCivilian: 0.95,
      );
  }
}

double _nwAcquisitionFloor({
  required AIWorldSnapshot snapshot,
  required Game game,
  required ExpandEconomyPlan expandEconomyPlan,
}) {
  var floor = 0.0;
  if (snapshot.economy.treasury == 0 &&
      snapshot.colonial.newWorldProvincesOwned == 0 &&
      expandEconomyPlan.boostTreasuryRecoveryCargo) {
    if (kPhasePriorityNwTreasuryRecoveryFloor > floor) {
      floor = kPhasePriorityNwTreasuryRecoveryFloor;
    }
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      regimentCountForPlayer(game, snapshot.playerId) == 0) {
    if (kPhasePriorityNwZeroRegimentFloor > floor) {
      floor = kPhasePriorityNwZeroRegimentFloor;
    }
  }
  return floor;
}
