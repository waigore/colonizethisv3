import 'dart:math' as math;

import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'colonial_naval_scoring.dart';
import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

Orders runNavalPlanner({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  ColonialSummary colonial = const ColonialSummary(),
}) {
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  var weight =
      primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.defend ||
          primaryGoal == StrategicGoal.expand
      ? domainWeights.military
      : 40;
  final hasColonialTargets =
      colonial.invadableNewWorldProvinceIdsSorted.isNotEmpty ||
      colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty;
  final colonialExpansionPressure =
      hasColonialTargets &&
      colonial.newWorldProvincesOwned < kColonialFewNwProvincesThreshold;
  if (hasColonialTargets) {
    weight += kColonialNavalWeightBonus;
  }
  if (colonialExpansionPressure && weight < 70) {
    weight = 70;
  }
  if (weight < 25) {
    _log.d('naval skipped nationId=$nationId weight=$weight < 25');
    return orders;
  }

  var o = orders;

  final unitsById = unitsByIdFromWorld(game.worldState);
  final navalMoveCandidates = suggestionAPI.suggestNavalMoveOrders(
    view,
    game,
    topology,
    o,
    unitsById: unitsById,
  );
  _log.d(
    'naval move eval nationId=$nationId '
    'candidatesCount=${navalMoveCandidates.length}',
  );
  if (navalMoveCandidates.isNotEmpty) {
    final rng = math.Random(seeds.militarySeed + 1000);
    final cap = navalMoveCandidates.length.clamp(0, 3);
    final take = hasColonialTargets
        ? cap
        : (cap > 0 ? 1 + rng.nextInt(cap) : 0);
    if (take > 0) {
      final ranked = hasColonialTargets
          ? sortNavalMovesForColonialPressure(
              navalMoveCandidates,
              topology,
              colonial,
            )
          : navalMoveCandidates;
      final selected = ranked.take(take).toList();
      _log.i(
        'naval move chosen nationId=$nationId '
        'take=$take selectedCount=${selected.length}',
      );
      o = o.appendNavalMoveOrders(nationId, selected);
    }
  }

  final navalMissionCandidates = suggestionAPI.suggestNavalMissionOrders(
    view,
    game,
    topology,
    o,
    unitsById: unitsById,
  );
  _log.d(
    'naval mission eval nationId=$nationId '
    'candidatesCount=${navalMissionCandidates.length}',
  );
  if (navalMissionCandidates.isNotEmpty) {
    final ranked = hasColonialTargets
        ? sortNavalMissionsForColonialPressure(navalMissionCandidates)
        : navalMissionCandidates;
    final rng = math.Random(seeds.militarySeed + 1001);
    final idx = hasColonialTargets
        ? 0
        : rng.nextInt(ranked.length);
    final chosen = ranked[idx];
    _log.i(
      'naval mission chosen nationId=$nationId '
      'mission=${chosen.mission} fleetId=${chosen.fleetId}',
    );
    o = o.appendNavalMissionOrders(nationId, [chosen]);
  }

  return o;
}
