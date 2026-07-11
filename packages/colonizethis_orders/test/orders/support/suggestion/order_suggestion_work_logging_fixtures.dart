// Shared suggestWorkOrders logging scenario fixtures (Refs #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const _playerId = 'gp1';
const _ow = 'oldWorld';

Player osgwPlayer({int treasury = 5000}) => Player(
  id: _playerId,
  displayName: 'Human',
  isHuman: true,
  treasury: treasury,
);

Unit _osgwUnit({
  required String id,
  required String type,
  required String provinceId,
  String tileKey = '$_ow|p1|0|0',
}) => Unit(
  id: id,
  type: type,
  ownerId: _playerId,
  locationProvinceId: provinceId,
  tileKey: tileKey,
  status: UnitStatus.idle,
);

({Game game, MapTopology topology, PlayerView view}) _osgwBundle({
  required Game game,
  required MapTopology topology,
}) => (
  game: game,
  topology: topology,
  view: buildPlayerView(game, topology, _playerId),
);

({Game game, MapTopology topology, PlayerView view})
osgwFourCivilianUnitsGame() {
  const p1 = '$_ow|p1';
  const p2 = '$_ow|p2';
  final game = ordersOwRegionGame(
    id: 'g1',
    turnNumber: 1,
    players: [osgwPlayer()],
    oldWorld: RegionData(
      provinces: [
        Province(id: p1, regionId: _ow, ownerId: _playerId),
        Province(id: p2, regionId: _ow, ownerId: _playerId),
      ],
      units: [
        _osgwUnit(id: 'u_explorer', type: kUnitTypeExplorer, provinceId: p1),
        _osgwUnit(id: 'u_builder', type: kUnitTypeBuilder, provinceId: p1),
        _osgwUnit(id: 'u_spy', type: kUnitTypeSpy, provinceId: p1),
        _osgwUnit(id: 'u_merchant', type: kUnitTypeMerchant, provinceId: p1),
      ],
    ),
    playerVisibilityByTile: {
      _playerId: {'$_ow|p1|0|0': 'fullyVisible', '$_ow|p2|0|0': 'fogged'},
    },
    tileKeysByRegionAndProvince: {
      _ow: {
        p1: ['$_ow|p1|0|0'],
        p2: ['$_ow|p2|0|0'],
      },
    },
    resourceByTileKey: const {'$_ow|p1|0|0': 'grain'},
  );
  return _osgwBundle(
    game: game,
    topology: ordersProvinceTopology(
      game.worldState.oldWorld.provinces,
      regionId: _ow,
      edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
    ),
  );
}

({Game game, MapTopology topology, PlayerView view}) osgwSingleExplorerGame() {
  const p1 = '$_ow|p1';
  final game = ordersOwRegionGame(
    id: 'g1',
    turnNumber: 1,
    players: [osgwPlayer()],
    oldWorld: RegionData(
      provinces: [Province(id: p1, regionId: _ow, ownerId: _playerId)],
      units: [
        _osgwUnit(id: 'u_explorer', type: kUnitTypeExplorer, provinceId: p1),
      ],
    ),
    playerVisibilityByTile: {
      _playerId: {'$_ow|p1|0|0': 'fullyVisible', '$_ow|p1|0|1': 'unknown'},
    },
    tileKeysByRegionAndProvince: {
      _ow: {
        p1: ['$_ow|p1|0|0', '$_ow|p1|0|1'],
      },
    },
    resourceByTileKey: const {'$_ow|p1|0|0': 'grain'},
  );
  return _osgwBundle(
    game: game,
    topology: ordersProvinceTopology(
      game.worldState.oldWorld.provinces,
      regionId: _ow,
    ),
  );
}

({Game game, MapTopology topology, PlayerView view})
osgwTwoIronTilesFoggedGame() {
  const provinceId = '$_ow|p1';
  const t0 = '$_ow|p1|0|0';
  const t1 = '$_ow|p1|1|0';
  final game = ordersOwRegionGame(
    id: 'g-prospect-log',
    turnNumber: 1,
    players: const [Player(id: _playerId, displayName: 'GP', isHuman: false)],
    oldWorld: RegionData(
      provinces: [Province(id: provinceId, regionId: _ow, ownerId: _playerId)],
      units: [
        _osgwUnit(
          id: 'u_explorer',
          type: kUnitTypeExplorer,
          provinceId: provinceId,
          tileKey: t0,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      _ow: {
        provinceId: [t0, t1],
      },
    },
    resourceByTileKey: const {t0: 'iron', t1: 'iron'},
    playerVisibilityByTile: const {
      _playerId: {t0: 'fogged', t1: 'fogged'},
    },
  );
  return _osgwBundle(
    game: game,
    topology: ordersProvinceTopology(
      game.worldState.oldWorld.provinces,
      regionId: _ow,
    ),
  );
}

({Game game, MapTopology topology, PlayerView view, Orders orders})
osgwExplorerPendingDuplicateGame() {
  const provinceId = '$_ow|p1';
  const tile = '$_ow|p1|0|0';
  final game = ordersOwRegionGame(
    id: 'g-order',
    turnNumber: 1,
    players: [osgwPlayer()],
    oldWorld: RegionData(
      provinces: [Province(id: provinceId, regionId: _ow, ownerId: _playerId)],
      units: [
        _osgwUnit(
          id: 'u_explorer',
          type: kUnitTypeExplorer,
          provinceId: provinceId,
          tileKey: tile,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      _ow: {
        provinceId: [tile],
      },
    },
    playerVisibilityByTile: {
      _playerId: {tile: 'fullyVisible'},
    },
  );
  final topology = ordersProvinceTopology(
    game.worldState.oldWorld.provinces,
    regionId: _ow,
  );
  final orders = Orders(
    workOrdersByPlayerId: {
      _playerId: const [
        WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetExplore,
          targetTileKey: tile,
        ),
        WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetProspect,
          targetTileKey: tile,
        ),
      ],
    },
  );
  return (
    game: game,
    topology: topology,
    view: buildPlayerView(game, topology, _playerId),
    orders: orders,
  );
}
