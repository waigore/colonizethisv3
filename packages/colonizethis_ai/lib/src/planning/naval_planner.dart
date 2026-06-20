import 'dart:math' as math;

import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'colonial_naval_scoring.dart';
import 'planning_imports.dart';
import 'observer_goal_phase.dart';
import '../perception/perception_snapshot.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_naval_filter.dart';
import 'planner_context.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

/// Minimum naval planner weight for the run gate (`weight >= kNavalRunMinWeight`).
const int kNavalRunMinWeight = 25;

/// Naval planner run-gate inputs.
///
/// Pure record of the values [runNavalPlanner] computes before its
/// `weight < kNavalRunMinWeight` short-circuit. The orchestrator
/// (Refs #2832 trace decision-provenance) consumes it via
/// [computeNavalRunGate] without re-running the planner so the trace
/// can report `thresholds.domainGates.navalPlannerRan` deterministically
/// without leaking planner internals.
class NavalRunGate {
  const NavalRunGate({required this.weight, required this.hasColonialTargets});

  final int weight;
  final bool hasColonialTargets;

  bool get willRun => weight >= kNavalRunMinWeight;
}

/// Computes the [NavalRunGate] for the naval planner using the same gate
/// arithmetic [runNavalPlanner] applies before its weight short-circuit.
///
/// Pure and deterministic — identical inputs always yield identical
/// outputs. No I/O, no logging.
NavalRunGate computeNavalRunGate({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  PhasePlanOutcome? phasePlan,
}) {
  final colonial = snapshot.colonial;
  var weight = ctx.resolveNavalBaseWeight();
  final bool hasColonialTargets;
  if (phasePlan != null) {
    final directive = resolvePhaseNavalDirective(phasePlan: phasePlan);
    hasColonialTargets = directive.colonialPreferenceActive;
  } else {
    hasColonialTargets =
        hasColonialAcquisitionTargets(colonial) &&
        !shouldSuppressNewWorldColonialOrders(
          snapshot: snapshot,
          game: ctx.game,
        );
  }
  // Refs #2847 Phase 3 naval colonial-pressure floor wiring: source the
  // colonial-pressure weight bonus and minimum-weight floor from the
  // soft-phase NW acquisition weight on the dispatched phase plan
  // instead of the legacy boolean directive. The null-phase-plan
  // fallback maps the legacy boolean (`hasColonialTargets`) to
  // `1.0 / 0.0` so callers without a `PhasePlanOutcome` preserve
  // pre-Phase-3 behaviour exactly (identity-equal at the curve
  // extremes). At the early-sprint default curve
  // (`newWorldAcquisition = 0.05` for OW <= 7) the bonus / floor
  // collapse to token nudges below `kNavalRunMinWeight` so the OW
  // conquest sprint is not dominated by colonial-pressure pulls;
  // under the resource-need override (`newWorldAcquisition = 0.60`
  // when treasury / NW / cargo predicates hold) the floor crosses
  // `kNavalRunMinWeight` and engages naval planning under EXPAND
  // recovery without requiring the GP to reach COLONIAL first.
  final colonialPressureWeight = phasePlan != null
      ? resolvePhaseNavalColonialPressureWeight(phasePlan: phasePlan)
      : (hasColonialTargets ? 1.0 : 0.0);
  final colonialPressureBonus = navalColonialPressureWeightBonus(
    colonialPressureWeight: colonialPressureWeight,
  );
  final colonialPressureFloor = navalColonialPressureMinWeightFloor(
    colonialPressureWeight: colonialPressureWeight,
  );
  weight += colonialPressureBonus;
  if (weight < colonialPressureFloor) {
    weight = colonialPressureFloor;
  }
  return NavalRunGate(weight: weight, hasColonialTargets: hasColonialTargets);
}

Orders runNavalPlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  PhasePlanOutcome? phasePlan,
}) {
  final colonial = snapshot.colonial;
  final gate = computeNavalRunGate(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: phasePlan,
  );
  final hasColonialTargets = gate.hasColonialTargets;
  // S5 wiring (Refs #2509): the phase-planner naval directive resolver
  // surfaces both the boolean colonial-pressure gate and the per-phase
  // priority NW province subset. Today the boolean drives the weight
  // boost / take cap; the subset tightens move ranking via
  // `sortNavalMovesForColonialPressure` so fleets approach the phase-
  // active acquisition frontier ahead of unrelated invadable NW
  // neighbors. Empty / null leaves the legacy two-tier scoring intact.
  List<String> phasePriorityNwProvinceIdsSorted = const <String>[];
  if (phasePlan != null) {
    final directive = resolvePhaseNavalDirective(phasePlan: phasePlan);
    phasePriorityNwProvinceIdsSorted = directive.priorityNwProvinceIdsSorted;
  }
  if (!gate.willRun) {
    _log.d(
      'naval skipped nationId=${ctx.nationId} weight=${gate.weight} '
      '< $kNavalRunMinWeight',
    );
    return ctx.orders;
  }

  var o = ctx.orders;

  final resolution = orderResolutionContextFromView(ctx.view, ctx.game);
  final navalMoveCandidates = ctx.suggestionAPI.suggestNavalMoveOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    o,
    resolution: resolution,
  );
  _log.d(
    'naval move eval nationId=${ctx.nationId} '
    'candidatesCount=${navalMoveCandidates.length}',
  );
  if (navalMoveCandidates.isNotEmpty) {
    final rng = math.Random(ctx.seeds.militarySeed + 1000);
    final cap = navalMoveCandidates.length.clamp(0, 3);
    final take = hasColonialTargets
        ? cap
        : (cap > 0 ? 1 + rng.nextInt(cap) : 0);
    if (take > 0) {
      final ranked = hasColonialTargets
          ? sortNavalMovesForColonialPressure(
              navalMoveCandidates,
              ctx.topology,
              colonial,
              phasePriorityNwProvinceIdsSorted:
                  phasePriorityNwProvinceIdsSorted,
            )
          : navalMoveCandidates;
      final selected = ranked.take(take).toList();
      _log.i(
        'naval move chosen nationId=${ctx.nationId} '
        'take=$take selectedCount=${selected.length}',
      );
      o = o.appendNavalMoveOrders(ctx.nationId, selected);
    }
  }

  final navalMissionCandidates = ctx.suggestionAPI.suggestNavalMissionOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    o,
    resolution: resolution,
  );
  _log.d(
    'naval mission eval nationId=${ctx.nationId} '
    'candidatesCount=${navalMissionCandidates.length}',
  );
  if (navalMissionCandidates.isNotEmpty) {
    final ranked = hasColonialTargets
        ? sortNavalMissionsForColonialPressure(
            navalMissionCandidates,
            phasePriorityNwProvinceIdsSorted: phasePriorityNwProvinceIdsSorted,
          )
        : navalMissionCandidates;
    final rng = math.Random(ctx.seeds.militarySeed + 1001);
    final idx = hasColonialTargets ? 0 : rng.nextInt(ranked.length);
    final chosen = ranked[idx];
    _log.i(
      'naval mission chosen nationId=${ctx.nationId} '
      'mission=${chosen.mission} fleetId=${chosen.fleetId}',
    );
    o = o.appendNavalMissionOrders(ctx.nationId, [chosen]);
  }

  return o;
}
