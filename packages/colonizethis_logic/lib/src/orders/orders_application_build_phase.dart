import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../economy/projected_cost_engine.dart';
import '../world/naval.dart';
import '../world/ship_instance_allocate.dart';
import 'build_spawn_province.dart';
import 'orders_application_context.dart';

/// Home-fleet ship spawn when capital has a seaboard port (naval build slice, #1618).
class _NavalBuildSession {
  _NavalBuildSession(this._game, this._topology);

  Game _game;
  final MapTopology _topology;

  /// Rebases session state onto the latest build-phase game snapshot.
  void rebase(Game game) {
    _game = game;
  }

  /// Spawns into home fleet when affordable build was already deducted; no-op if blocked.
  void spawnHomeFleetShipIfEligible(Player player, BuildUnitOrder order) {
    final capProvinceId = player.capitalProvinceId;
    if (capProvinceId == null) return;
    final regionId = ProvinceId.regionIdFrom(capProvinceId);
    // Only add ship when capital is sea-bound (has a port). SPEC/game/ships-and-naval.md.
    final seaZoneAtCap = seaZoneIdForProvince(
      _topology,
      ProvinceId.localIdFrom(capProvinceId),
      regionId: regionId,
    );
    if (seaZoneAtCap == null) return;

    var ws = _game.worldState;
    var fleets = List<Fleet>.from(ws.fleets);
    final homeFleetId = homeFleetIdFor(player.id);
    final existing = fleets.indexWhere(
      (f) => f.id == homeFleetId && f.ownerId == player.id,
    );
    var nextSeq = ws.nextShipInstanceSeq;
    final inferred = inferNextShipInstanceSeqFromFleets(fleets);
    if (nextSeq < inferred) nextSeq = inferred;
    final (seqAfter, minted) = mintShipInstances(
      nextShipInstanceSeq: nextSeq,
      typeIds: [order.unitType],
    );
    nextSeq = seqAfter;
    if (existing >= 0) {
      final f = fleets[existing];
      fleets = List<Fleet>.from(fleets)
        ..[existing] = f.copyWith(ships: [...f.ships, ...minted]);
    } else {
      fleets = [
        ...fleets,
        Fleet(
          id: homeFleetId,
          ownerId: player.id,
          seaZoneId: null,
          inPortAtProvinceId: capProvinceId,
          regionId: regionId,
          ships: minted,
        ),
      ];
    }
    _game = _game.copyWith(
      worldState: ws.copyWith(fleets: fleets, nextShipInstanceSeq: nextSeq),
    );
  }

  Game get game => _game;
}

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
    String newUnitId,
  ) {
    return appendMilitaryRegimentToArmy(game, player, spawnProvinceId, newUnitId);
  }
}

/// One land/civilian/military build order after affordability check; keeps [runBuildPhase]
/// nesting shallow for CI (`repo.control_flow_nesting_depth`).
BuildWorkState _applyAffordableBuildUnitOrder({
  required BuildWorkState current,
  required Player player,
  required BuildUnitOrder order,
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
    throw StateError(
      '$kCivilianCapitalTileMissingReason: player=${player.id}',
    );
  }

  final newUnit = Unit(
    id: _buildUnitId(player.id, order, spawnProvinceId),
    type: order.unitType,
    ownerId: player.id,
    locationProvinceId: spawnProvinceId,
    tileKey: category == BuildUnitCategory.civilian ? civilianTileKey : null,
  );

  var work = current.work;
  if (regionId == kRegionNewWorld) {
    work = work.copyWith(
      newUnitsById: Map<String, Unit>.from(work.newUnitsById)
        ..[newUnit.id] = newUnit,
    );
  } else {
    work = work.copyWith(
      oldUnitsById: Map<String, Unit>.from(work.oldUnitsById)
        ..[newUnit.id] = newUnit,
    );
  }

  var nextGame = current.game;
  if (category == BuildUnitCategory.military) {
    nextGame = _MilitaryBuildState.appendRegimentToArmy(
      nextGame,
      player,
      spawnProvinceId,
      newUnit.id,
    );
  }

  return current.copyWith(game: nextGame, work: work);
}

/// Applies build orders for all players. Returns state with updated [game] and unit maps.
BuildWorkState runBuildPhase(BuildWorkState state) {
  final naval = state.topology != null
      ? _NavalBuildSession(state.game, state.topology!)
      : null;
  var current = naval != null ? state.copyWith(game: naval.game) : state;

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
        current = naval != null
            ? current.copyWith(game: naval.game)
            : current;
        continue;
      }

      current = _applyAffordableBuildUnitOrder(
        current: current,
        player: player,
        order: order,
      );
    }

    current = current.copyWith(
      game: current.game.copyWith(
        players: current.game.players
            .map(
              (p) => p.id == player.id
                  ? p.copyWith(
                      stockpile: stockpile,
                      workerPool: workers,
                      treasury: treasury,
                    )
                  : p,
            )
            .toList(),
      ),
    );
  }

  return current;
}
