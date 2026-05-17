import 'dart:math' as math;

import 'colonial_naval_scoring.dart';
import 'colonial_pressure.dart';
import 'planner_context.dart';
import 'planning_imports.dart';
import '../perception/summary_models.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

Orders runNavalPlanner({
  required PlannerContext ctx,
  ColonialSummary colonial = const ColonialSummary(),
}) {
  var weight = ctx.resolveWeightForDomain(
    kind: DomainWeightKind.militaryOrBase,
    base: 40,
  );
  final hasColonialTargets = hasColonialAcquisitionTargets(colonial);
  if (hasColonialTargets) {
    weight += kColonialNavalWeightBonus;
  }
  if (hasColonialTargets && weight < 70) {
    weight = 70;
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
        ? sortNavalMissionsForColonialPressure(navalMissionCandidates)
        : navalMissionCandidates;
    final rng = math.Random(ctx.seeds.militarySeed + 1001);
    final idx = hasColonialTargets
        ? 0
        : rng.nextInt(ranked.length);
    final chosen = ranked[idx];
    _log.i(
      'naval mission chosen nationId=${ctx.nationId} '
      'mission=${chosen.mission} fleetId=${chosen.fleetId}',
    );
    o = o.appendNavalMissionOrders(ctx.nationId, [chosen]);
  }

  return o;
}
