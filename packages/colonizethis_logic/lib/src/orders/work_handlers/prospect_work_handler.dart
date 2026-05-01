import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../orders_application_helpers.dart';
import 'shared_work_assignment.dart';
import 'work_order_handler.dart';

Game tryApplyProspectWorkOrder({
  required Game game,
  required Map<String, TileMapResult>? tileMapByRegion,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required void Function(String, Unit) updateUnit,
}) {
  if (targetTileKey.isEmpty ||
      unit.currentWork != null ||
      !isExplorerUnit(unit.type)) {
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

class ProspectWorkOrderHandler implements WorkOrderHandler {
  const ProspectWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetProspect;

  @override
  bool tryApply(
    WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    context.state = context.state.copyWith(
      game: tryApplyProspectWorkOrder(
        game: context.state.game,
        tileMapByRegion: context.state.tileMapByRegion,
        player: context.player,
        unit: unit,
        targetTileKey: targetTileKey,
        updateUnit: context.updateUnit,
      ),
    );
    return true;
  }
}
