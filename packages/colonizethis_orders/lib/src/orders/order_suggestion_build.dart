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

  bool accept(BuildUnitOrder candidate) =>
      isBuildOrderAcceptedWithValidator(candidateValidator, candidate);

  // Military (regiment) builds, then naval (ship) builds. The shared emitter
  // preserves catalog iteration order; the final sort yields the observable
  // order. SPEC/program/order-suggestions.md.
  emitAcceptedCandidates<BuildUnitOrder>(
    candidates: [
      for (final entry in RegimentEconomyCatalog.byId.entries)
        BuildUnitOrder(
          unitType: entry.key,
          isMilitary:
              buildUnitCategoryForUnitType(entry.key) ==
              BuildUnitCategory.military,
          spawnProvinceId: capitalId,
        ),
    ],
    accept: accept,
    into: suggestions,
  );
  emitAcceptedCandidates<BuildUnitOrder>(
    candidates: [
      for (final entry in ShipEconomyCatalog.byId.entries)
        BuildUnitOrder(
          unitType: entry.key,
          isMilitary: false,
          spawnProvinceId: capitalId,
        ),
    ],
    accept: accept,
    into: suggestions,
  );

  suggestions.sort((a, b) => a.unitType.compareTo(b.unitType));

  orderSuggestionLog.d(
    'suggestBuildOrders full list ${suggestions.map((o) => o.unitType).join(", ")}',
  );
  pass.logExit(candidateCount: suggestions.length, warnIfEmpty: true);
  return suggestions;
}
