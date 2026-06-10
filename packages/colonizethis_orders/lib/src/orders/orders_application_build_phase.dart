import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'build_spawn_province.dart';
import 'orders_application_context.dart';

/// Home-fleet ship spawn when capital has a seaboard port (naval build slice, #1618).
class _NavalBuildSession {
  _NavalBuildSession(this._game, this._topology)
    : _fleetById = fleetsByIdForWorld(_game.worldState);

  Game _game;
  final MapTopology _topology;

  /// Cached O(1) index of [WorldState.fleets] by fleet id. Rebuilt on
  /// [rebase] so home-fleet lookups during build orders avoid a per-order
  /// `indexWhere` over `WorldState.fleets`. Refs #2394.
  Map<String, Fleet> _fleetById;

  /// Rebases session state onto the latest build-phase game snapshot.
  void rebase(Game game) {
    _game = game;
    _fleetById = fleetsByIdForWorld(_game.worldState);
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

    final ws = _game.worldState;
    final homeFleetId = homeFleetIdFor(player.id);
    // O(1) home-fleet lookup via the rebased index (Refs #2394). When the map
    // entry exists but is owned by another faction, treat as "no home fleet"
    // for this player and create a fresh one — same semantics as the legacy
    // `indexWhere((f) => f.id == ... && f.ownerId == ...)` predicate.
    final mapped = _fleetById[homeFleetId];
    final Fleet? existingFleet = (mapped != null && mapped.ownerId == player.id)
        ? mapped
        : null;
    var nextSeq = ws.nextShipInstanceSeq;
    final inferred = inferNextShipInstanceSeqFromFleets(ws.fleets);
    if (nextSeq < inferred) nextSeq = inferred;
    final (seqAfter, minted) = mintShipInstances(
      nextShipInstanceSeq: nextSeq,
      typeIds: [order.unitType],
    );
    nextSeq = seqAfter;
    final List<Fleet> nextFleets;
    if (existingFleet != null) {
      final updated = existingFleet.copyWith(
        ships: [...existingFleet.ships, ...minted],
      );
      nextFleets = <Fleet>[
        for (final f in ws.fleets)
          if (f.id == homeFleetId && f.ownerId == player.id) updated else f,
      ];
      _fleetById[homeFleetId] = updated;
    } else {
      final newFleet = Fleet(
        id: homeFleetId,
        ownerId: player.id,
        seaZoneId: null,
        inPortAtProvinceId: capProvinceId,
        regionId: regionId,
        ships: minted,
      );
      nextFleets = [...ws.fleets, newFleet];
      _fleetById[homeFleetId] = newFleet;
    }
    _game = _game.updateWorldState(
      (ws) => ws.copyWith(fleets: nextFleets, nextShipInstanceSeq: nextSeq),
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
      ? _NavalBuildSession(state.game, state.topology!)
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
