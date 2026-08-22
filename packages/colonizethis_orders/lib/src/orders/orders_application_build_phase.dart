import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'build_spawn_province.dart';
import 'orders_application_build_phase_naval.dart';
import 'orders_application_context.dart';

String _buildUnitId(
  String playerId,
  BuildUnitOrder order,
  String spawnProvinceId,
) {
  return '${playerId}_${order.unitType}_$spawnProvinceId';
}

/// Civilian unit spawn tile resolution (civilian build slice, #1618).
class _CivilianBuildState {
  _CivilianBuildState._();

  static String? spawnTileKeyForCategory({
    required BuildUnitCategory category,
    required Player player,
    required Game game,
  }) {
    if (category != BuildUnitCategory.civilian) return null;
    return resolveCivilianSpawnTileKey(
      player: player,
      worldState: game.worldState,
    );
  }
}

/// Military regiment placement after land unit creation (military build slice, #1618).
class _MilitaryBuildState {
  _MilitaryBuildState._();

  static Game appendRegimentToArmy(
    Game game,
    Player player,
    String spawnProvinceId,
    String newUnitId, {
    Map<String, Army>? armiesById,
  }) {
    return appendMilitaryRegimentToArmy(
      game,
      player,
      spawnProvinceId,
      newUnitId,
      armiesById: armiesById,
    );
  }
}

/// One land/civilian/military build order after affordability check; keeps [runBuildPhase]
/// nesting shallow for CI (`repo.control_flow_nesting_depth`).
///
/// When [armiesById] is supplied, military recruits skip the per-order
/// `indexWhere` over `worldState.armies` via the shared O(1) snapshot. Refs
/// #2394, SPEC/program/order-suggestions.md § Throughput bounds.
BuildWorkState _applyAffordableBuildUnitOrder({
  required BuildWorkState current,
  required Player player,
  required BuildUnitOrder order,
  Map<String, Army>? armiesById,
}) {
  final category = buildUnitCategoryForUnitType(order.unitType);
  if (category == BuildUnitCategory.unknown) return current;

  final spawnProvinceId = resolveBuildSpawnProvinceId(
    player: player,
    worldState: current.game.worldState,
    order: order,
  );
  if (spawnProvinceId == null) return current;

  final regionId = ProvinceId.regionIdFrom(spawnProvinceId);
  final civilianTileKey = _CivilianBuildState.spawnTileKeyForCategory(
    category: category,
    player: player,
    game: current.game,
  );
  if (category == BuildUnitCategory.civilian && civilianTileKey == null) {
    throw StateError('$kCivilianCapitalTileMissingReason: player=${player.id}');
  }

  final newUnit = Unit(
    id: _buildUnitId(player.id, order, spawnProvinceId),
    type: order.unitType,
    ownerId: player.id,
    locationProvinceId: spawnProvinceId,
    tileKey: category == BuildUnitCategory.civilian ? civilianTileKey : null,
  );

  final oldWorld = regionId != kRegionNewWorld;
  final work = current.work.withUnitsByIdForRegion(
    oldWorld,
    copyUnitsById(current.work.unitsByIdForRegion(oldWorld))
      ..[newUnit.id] = newUnit,
  );

  var nextGame = current.game;
  if (category == BuildUnitCategory.military) {
    nextGame = _MilitaryBuildState.appendRegimentToArmy(
      nextGame,
      player,
      spawnProvinceId,
      newUnit.id,
      armiesById: armiesById,
    );
  }

  return current.copyWith(game: nextGame, work: work);
}

/// Applies build orders for all players. Returns state with updated [game] and unit maps.
///
/// Maintains an O(1) `Map<String, Army>` snapshot across all military recruits
/// in the phase so [_applyAffordableBuildUnitOrder] avoids a per-order
/// `indexWhere` over `WorldState.armies`. Refs #2394,
/// SPEC/program/order-suggestions.md § Throughput bounds.
BuildWorkState runBuildPhase(BuildWorkState state) {
  final naval = state.topology != null
      ? NavalBuildSession(state.game, state.topology!)
      : null;
  var current = naval != null ? state.copyWith(game: naval.game) : state;
  // Mutable O(1) army index reused across every recruit in this phase; the
  // helper mutates it in place when armies are added or updated. Refs #2394.
  final armiesById = armiesByIdForWorld(current.game.worldState);

  for (final player in current.game.players) {
    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;

    for (final order in current.buildOrders[player.id] ?? const []) {
      final category = buildUnitCategoryForUnitType(order.unitType);
      if (category == BuildUnitCategory.unknown) continue;

      final check = ProjectedCostEngine.canAffordBuildOrder(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!check.canAfford) continue;

      final after = ProjectedCostEngine.applyBuildOrderCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;

      if (category == BuildUnitCategory.naval) {
        naval?.rebase(current.game);
        naval?.spawnHomeFleetShipIfEligible(player, order);
        current = naval != null ? current.copyWith(game: naval.game) : current;
        continue;
      }

      current = _applyAffordableBuildUnitOrder(
        current: current,
        player: player,
        order: order,
        armiesById: armiesById,
      );
    }

    current = writebackPlayerEconomyFields(
      current,
      player,
      workers: workers,
      stockpile: stockpile,
      treasury: treasury,
    );
  }

  return current;
}
