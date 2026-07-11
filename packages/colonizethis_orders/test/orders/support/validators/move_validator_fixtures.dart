// Shared move/army validator game fixtures (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';
import 'move_validator_test_support.dart';

const mvOw = 'oldWorld';
const mvNw = 'newWorld';
const mvDestTile = '$mvOw|P2|0|0';

// dart format off
Map<String, Map<String, String>> mvP1FogPairVisibility({required String destRegion, required String destLocal}) =>
    {'p1': {'$mvOw|P1|0|0': 'fullyVisible', '$destRegion|$destLocal|0|0': 'fogged'}};

MapTopology get mvOwTopology => moveValidatorTestTwoProvinceTopology(mvOw);

const _mvP1 = Player(id: 'p1', displayName: 'P1', isHuman: true);
const _mvP2 = Player(id: 'p2', displayName: 'P2', isHuman: true);

List<Player> _mvPlayers({required bool includeP2Player}) => [_mvP1, if (includeP2Player) _mvP2];

Province _mvProv(String region, String local, String ownerId) => Province(id: '$region|$local', regionId: region, ownerId: ownerId);

Unit _mvUnit({required String id, required String type, required String region, required String local, String? tileKey}) =>
    Unit(id: id, type: type, ownerId: 'p1', locationProvinceId: '$region|$local', tileKey: tileKey);

Game mvTwoProvinceUnitGame({
  required String unitType,
  required String unitId,
  required String destOwnerId,
  bool includeP2Player = false,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  String? unitTileKey,
}) => ordersOwRegionGame(
  players: _mvPlayers(includeP2Player: includeP2Player),
  oldWorld: RegionData(
    provinces: [_mvProv(mvOw, 'P1', 'p1'), _mvProv(mvOw, 'P2', destOwnerId)],
    units: [_mvUnit(id: unitId, type: unitType, region: mvOw, local: 'P1', tileKey: unitTileKey)],
  ),
  playerVisibilityByTile: mvP1FogPairVisibility(destRegion: mvOw, destLocal: 'P2'),
  minorNations: minorNations,
  tribes: tribes,
);

Game mvTwoProvinceArmyGame({
  required String destOwnerId,
  bool includeP2Player = false,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
}) => ordersOwRegionGame(
  players: _mvPlayers(includeP2Player: includeP2Player),
  oldWorld: RegionData(
    provinces: [_mvProv(mvOw, 'P1', 'p1'), _mvProv(mvOw, 'P2', destOwnerId)],
    units: [_mvUnit(id: 'u1', type: 'pikemen', region: mvOw, local: 'P1')],
  ),
  armies: [moveValidatorTestFieldArmy(mvOw, 'p1', 'P1', 'u1')],
  playerVisibilityByTile: mvP1FogPairVisibility(destRegion: mvOw, destLocal: 'P2'),
  minorNations: minorNations,
  tribes: tribes,
);

Game mvCrossRegionTribeGame({required String unitType}) => ordersOwRegionGame(
  players: const [_mvP1],
  oldWorld: RegionData(
    provinces: [_mvProv(mvOw, 'P1', 'p1')],
    units: [_mvUnit(id: 'u1', type: unitType, region: mvOw, local: 'P1', tileKey: '$mvOw|P1|0|0')],
  ),
  newWorld: RegionData(provinces: [_mvProv(mvNw, 'P2', 'tribe1')]),
  playerVisibilityByTile: mvP1FogPairVisibility(destRegion: mvNw, destLocal: 'P2'),
  tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe1')],
);

/// NW two-province army game: p1 owns P1, tribe1 owns P2 (declare-war scenarios).
Game mvNwTribeArmyGame() => ordersOwRegionGame(
  players: const [_mvP1],
  oldWorld: const RegionData(),
  newWorld: RegionData(
    provinces: [_mvProv(mvNw, 'P1', 'p1'), _mvProv(mvNw, 'P2', 'tribe1')],
    units: [_mvUnit(id: 'u1', type: 'pikemen', region: mvNw, local: 'P1')],
  ),
  armies: [moveValidatorTestFieldArmy(mvNw, 'p1', 'P1', 'u1')],
  playerVisibilityByTile: const {'p1': {'$mvNw|P1|0|0': 'fullyVisible', '$mvNw|P2|0|0': 'fogged'}},
  tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe1', capitalProvinceId: '$mvNw|P2')],
);

MapTopology mvNwTwoProvinceTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 'P1', regionId: mvNw, type: TopologyNodeType.province),
    TopologyNode(id: 'P2', regionId: mvNw, type: TopologyNodeType.province),
  ],
  edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
);
// dart format on
