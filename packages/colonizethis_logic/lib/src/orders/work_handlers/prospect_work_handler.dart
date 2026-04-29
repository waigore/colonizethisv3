import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../orders_application_helpers.dart';
import 'shared_work_assignment.dart';

Game tryApplyProspectWorkOrder({
  required Game game,
  required Map<String, TileMapResult>? tileMapByRegion,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required void Function(String, Unit) updateUnit,
}) {
  if (targetTileKey.isEmpty || unit.currentWork != null || !isExplorerUnit(unit.type)) {
    return game;
  }
  if (!isMineralEligibleTile(game, tileMapByRegion, targetTileKey)) return game;

  final existing = game.worldState.playerProspectedTiles[player.id] ?? const {};
  final newProspected = Set<String>.from(existing)..add(targetTileKey);
  final updated = game.copyWith(
    worldState: game.worldState.copyWith(
      playerProspectedTiles: {
        ...game.worldState.playerProspectedTiles,
        player.id: newProspected,
      },
    ),
  );
  completeInstantCivilianOrder(updateUnit, unit, targetTileKey);
  return updated;
}
