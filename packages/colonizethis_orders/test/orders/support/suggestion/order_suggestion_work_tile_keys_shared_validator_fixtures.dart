// Shared work-tile-keys shared-validator fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const workTileKeysSharedValidatorPlayerId = 'gp1';
const workTileKeysSharedValidatorOw = 'oldWorld';
const workTileKeysSharedValidatorTileA = 'oldWorld|p1|0|0';
const workTileKeysSharedValidatorTileB = 'oldWorld|p1|1|0';
const workTileKeysSharedValidatorEmptyTopology =
    MapTopology(nodes: [], edges: []);

/// Builder-improvement corpus shared by
/// [orderSuggestionWorkTileKeysSharedValidatorScenarios].
class WorkTileKeysSharedValidatorFixture {
  const WorkTileKeysSharedValidatorFixture({
    required this.game,
    required this.topology,
    required this.view,
    required this.orders,
    required this.ownedIds,
    required this.unitsById,
  });

  final Game game;
  final MapTopology topology;
  final PlayerView view;
  final Orders orders;
  final Set<String> ownedIds;
  final Map<String, Unit> unitsById;
}

WorkTileKeysSharedValidatorFixture workTileKeysSharedValidatorFixture({
  String gameId = 'g_work_tile_keys_shared_validator',
}) {
  const playerId = workTileKeysSharedValidatorPlayerId;
  const ow = workTileKeysSharedValidatorOw;
  const tileA = workTileKeysSharedValidatorTileA;
  const tileB = workTileKeysSharedValidatorTileB;
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
  );
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final b1 = Unit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: tileA,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [b1]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': [tileA, tileB],
      },
    },
    resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
    tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
  );
  final game = Game(id: gameId, worldState: world, players: [player]);
  const topology = workTileKeysSharedValidatorEmptyTopology;
  final view = buildPlayerView(game, topology, playerId);
  const orders = Orders();
  final ownedIds = <String>{
    for (final e in view.provincesById.entries)
      if (e.value.ownerId == playerId) e.key,
  };
  final unitsById = unitsByIdFromWorld(game.worldState);

  return WorkTileKeysSharedValidatorFixture(
    game: game,
    topology: topology,
    view: view,
    orders: orders,
    ownedIds: ownedIds,
    unitsById: unitsById,
  );
}
