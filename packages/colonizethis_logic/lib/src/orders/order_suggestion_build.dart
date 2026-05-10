import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/player_view.dart';
import 'order_suggestion_context.dart';

/// Suggests build-unit orders that are affordable and valid for [view.playerId].
List<BuildUnitOrder> suggestBuildOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  orderSuggestionLog.d('suggestBuildOrders player=${view.playerId}');
  final playerId = view.playerId;
  final player = view.player;
  final suggestions = <BuildUnitOrder>[];
  final candidateValidator = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: currentOrders,
  );

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
    'suggestBuildOrders player=$playerId candidates=${suggestions.length}',
  );
  orderSuggestionLog.d(
    'suggestBuildOrders full list ${suggestions.map((o) => o.unitType).join(", ")}',
  );
  if (suggestions.isEmpty) {
    orderSuggestionLog.w('suggestBuildOrders no candidates player=$playerId');
  }
  return suggestions;
}
