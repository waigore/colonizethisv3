import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../turn/turn_logging.dart';
import '../turn/turn_resolver.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';
import 'package:colonizethis_orders/src/orders/projected_effects.dart';

/// Projects effects of unresolved orders. SPEC/program/order-projections.md.
/// Dry-run of resolveTurnForGame; no world state mutation.

/// Projects effects for a single player. Merge that player's orders with empty
/// orders for others so the dry-run can complete.
ProjectedEffects projectOrderEffects({
  required Game game,
  required Orders orders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required String playerId,
  List<AssignedRecipe> defaultAssignments = const [],
}) {
  turnLog.d('projectOrderEffects run for player $playerId');
  if (tileMapByRegion.isEmpty) {
    turnLog.d(
      'projectOrderEffects with empty tileMapByRegion; extraction will be zero',
    );
  }
  Map<String, Map<String, int>>? productionByRecipeByPlayerId;
  final next = requireTurnResolutionComplete(
    resolveTurnForGame(
      game: game,
      topology: topology,
      orders: orders,
      tileMapByRegion: tileMapByRegion,
      defaultAssignments: defaultAssignments,
      onProductionComplete: defaultAssignments.isNotEmpty
          ? (map) => productionByRecipeByPlayerId = map
          : null,
    ),
  );
  final player = next.playerById(playerId);
  if (player == null) return const ProjectedEffects();

  final origPlayer = game.playerById(playerId);

  // Unit locations after resolution (province identity: use locationProvinceId per SPEC/game/world-model.md).
  final unitLocations = <String, String>{};
  for (final u in allUnitsFromWorld(next.worldState)) {
    if (u.ownerId == playerId) unitLocations[u.id] = u.locationProvinceId;
  }

  // Stockpile deltas (quantities after - quantities before).
  final stockpileDeltas = <String, int>{};
  for (final entry in player.stockpile.quantities.entries) {
    final after = entry.value;
    final before = origPlayer?.stockpile.quantityOf(entry.key) ?? 0;
    final delta = after - before;
    if (delta != 0) stockpileDeltas[entry.key] = delta;
  }
  final origQuantities = origPlayer?.stockpile.quantities ?? const {};
  for (final entry in origQuantities.entries) {
    if (!player.stockpile.quantities.containsKey(entry.key)) {
      stockpileDeltas[entry.key] = -entry.value;
    }
  }

  final productionByRecipe = productionByRecipeByPlayerId?[playerId];

  return ProjectedEffects(
    workerCount: player.workerPool.totalWorkers,
    treasuryDelta: origPlayer != null
        ? player.treasury - origPlayer.treasury
        : null,
    unitLocations: unitLocations,
    stockpileDeltas: stockpileDeltas.isNotEmpty ? stockpileDeltas : null,
    productionByRecipe:
        productionByRecipe != null && productionByRecipe.isNotEmpty
        ? productionByRecipe
        : null,
  );
}
