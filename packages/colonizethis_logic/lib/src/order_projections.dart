import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_production.dart';
import 'order_engine.dart';
import 'turn_resolver.dart';

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
  final next = resolveTurnForGame(
    game: game,
    topology: topology,
    orders: orders,
    tileMapByRegion: tileMapByRegion,
    defaultAssignments: defaultAssignments,
  );
  final player = next.players.cast<Player?>().firstWhere(
        (p) => p?.id == playerId,
        orElse: () => null,
      );
  if (player == null) return const ProjectedEffects();

  final origPlayer = game.players.cast<Player?>().firstWhere(
        (p) => p?.id == playerId,
        orElse: () => null,
      );

  // Unit locations after resolution.
  final unitLocations = <String, String>{};
  for (final u in next.worldState.oldWorld.units) {
    if (u.ownerId == playerId) unitLocations[u.id] = u.provinceId;
  }
  for (final u in next.worldState.newWorld.units) {
    if (u.ownerId == playerId) unitLocations[u.id] = u.provinceId;
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

  return ProjectedEffects(
    workerCount: player.workerPool.totalWorkers,
    treasuryDelta: origPlayer != null ? player.treasury - origPlayer.treasury : null,
    unitLocations: unitLocations,
    stockpileDeltas: stockpileDeltas.isNotEmpty ? stockpileDeltas : null,
  );
}
