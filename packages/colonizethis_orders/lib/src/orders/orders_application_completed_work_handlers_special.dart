import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'orders_application_helpers.dart';
import 'build_rail_work_rules.dart';
import 'orders_application_context.dart';
import 'orders_application_completed_work_handlers.dart';
import 'purchase_land_work_completion.dart';
import 'work_updated_players.dart';

BuildWorkState completedWorkBuildRail(CompletedWorkContext ctx) {
  final s = ctx.state;
  final u = ctx.unit;
  final cw = ctx.cw;
  final player = s.game.playerById(u.ownerId);
  final roadLevel = s.work.tileState.roadLevel(cw.tileKey);
  final terrain = terrainTypeForTileKey(s.tileMapByRegion, cw.tileKey);
  final reason = rejectionReasonForBuildRailOrder(
    techUnlocked: player?.techUnlocked,
    roadLevel: roadLevel,
    terrain: terrain,
  );
  if (reason == null) {
    return s.copyWith(
      work: s.work.copyWith(
        tileState: s.work.tileState.setRoadLevel(cw.tileKey, 4),
      ),
    );
  }
  ordersApplicationLog.d(
    'build_rail completion skipped unit=${u.id} reason=$reason',
  );
  return s;
}

BuildWorkState completedWorkProspect(CompletedWorkContext ctx) {
  final s = ctx.state;
  final u = ctx.unit;
  final cw = ctx.cw;
  if (!isMineralEligibleTile(s.game, s.tileMapByRegion, cw.tileKey)) {
    return s;
  }
  final existing = s.game.worldState.prospectedTilesForPlayer(u.ownerId);
  if (existing.contains(cw.tileKey)) {
    return s;
  }
  final newProspected = Set<String>.from(existing)..add(cw.tileKey);
  final ws = s.game.worldState.copyWith(
    playerProspectedTiles: {
      ...s.game.worldState.playerProspectedTiles,
      u.ownerId: newProspected,
    },
  );
  return s.copyWith(game: s.game.withWorldState(ws));
}

BuildWorkState completedWorkPurchaseLand(CompletedWorkContext ctx) {
  final s = ctx.state;
  final u = ctx.unit;
  final cw = ctx.cw;
  final player = s.game.playerById(u.ownerId);
  if (player == null) {
    return s;
  }
  final land = applyPurchaseLandCompletion(
    state: s,
    player: player,
    unit: u,
    targetTileKey: cw.tileKey,
    treasury: player.treasury,
    purchasedTilesByTileKey: s.work.purchasedTilesByTileKey,
    provinceById: (id) =>
        s.game.worldState.allProvincesById[id] ??
        s.game.worldState.tryGetProvince(id),
  );
  final updatedPlayer = player.copyWith(treasury: land.treasury);
  final nextPlayers = s.game.players
      .map((p) => p.id == u.ownerId ? updatedPlayer : p)
      .toList();
  return s.copyWith(
    game: s.game.withPlayers(nextPlayers),
    work: s.work.copyWith(
      purchasedTilesByTileKey: land.purchasedTilesByTileKey,
      updatedPlayers: upsertPlayerSnapshot(
        s.work.updatedPlayers,
        u.ownerId,
        updatedPlayer,
      ),
    ),
  );
}
