import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_pass_context.dart';

/// Suggests build-unit orders that are affordable and valid for [view.playerId].
///
/// Throughput hook: callers that enumerate multiple suggestion families against
/// the same `(game, view.playerId, currentOrders)` may supply
/// [sharedCandidateValidator] to amortize `PlayerView` / units-by-id
/// construction across families (Refs #2394). The shared instance must be
/// built with the same inputs; observable suggestions must match the default
/// path.
List<BuildUnitOrder> suggestBuildOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  final pass = SuggestionPassContext.forPlayerView(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestBuildOrders',
    sharedCandidateValidator: sharedCandidateValidator,
  );
  final playerId = pass.playerId;
  final player = view.player;
  final suggestions = <BuildUnitOrder>[];
  final candidateValidator = pass.candidateValidator;

  final capitalId = player.capitalProvinceId;
  if (capitalId == null) {
    orderSuggestionLog.w('suggestBuildOrders no capital player=$playerId');
    return suggestions;
  }

  // Military (regiment) builds.
  for (final entry in RegimentEconomyCatalog.byId.entries) {
    final unitType = entry.key;
    final candidate = BuildUnitOrder(
      unitType: unitType,
      isMilitary:
          buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military,
      spawnProvinceId: capitalId,
    );

    if (isBuildOrderAcceptedWithValidator(candidateValidator, candidate)) {
      suggestions.add(candidate);
    }
  }

  // Naval (ship) builds. SPEC/program/order-suggestions.md.
  for (final entry in ShipEconomyCatalog.byId.entries) {
    final unitType = entry.key;
    final candidate = BuildUnitOrder(
      unitType: unitType,
      isMilitary: false,
      spawnProvinceId: capitalId,
    );

    if (isBuildOrderAcceptedWithValidator(candidateValidator, candidate)) {
      suggestions.add(candidate);
    }
  }

  suggestions.sort((a, b) => a.unitType.compareTo(b.unitType));

  orderSuggestionLog.d(
    'suggestBuildOrders full list ${suggestions.map((o) => o.unitType).join(", ")}',
  );
  pass.logExit(candidateCount: suggestions.length, warnIfEmpty: true);
  return suggestions;
}
