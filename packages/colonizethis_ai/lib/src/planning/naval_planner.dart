import 'dart:math' as math;

import 'colonial_naval_scoring.dart';
import 'planning_imports.dart';
import 'colonial_pressure.dart';
import 'observer_goal_phase.dart';
import '../perception/perception_snapshot.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_naval_filter.dart';
import 'planner_context.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

Orders runNavalPlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  PhasePlanOutcome? phasePlan,
}) {
  final colonial = snapshot.colonial;
  var weight = ctx.resolveNavalBaseWeight();
  final bool hasColonialTargets;
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
    hasColonialTargets = directive.colonialPreferenceActive;
    phasePriorityNwProvinceIdsSorted = directive.priorityNwProvinceIdsSorted;
  } else {
    hasColonialTargets =
        hasColonialAcquisitionTargets(colonial) &&
        !shouldSuppressNewWorldColonialOrders(
          snapshot: snapshot,
          game: ctx.game,
        );
  }
  if (hasColonialTargets) {
    weight += kColonialNavalWeightBonus;
  }
  if (hasColonialTargets && weight < kColonialNavalMinWeightWhenPressure) {
    weight = kColonialNavalMinWeightWhenPressure;
  }
  if (weight < 25) {
    _log.d('naval skipped nationId=${ctx.nationId} weight=$weight < 25');
    return ctx.orders;
  }

  var o = ctx.orders;

  final unitsById = unitsByIdFromWorld(ctx.game.worldState);
  final navalMoveCandidates = ctx.suggestionAPI.suggestNavalMoveOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    o,
    unitsById: unitsById,
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
    unitsById: unitsById,
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
