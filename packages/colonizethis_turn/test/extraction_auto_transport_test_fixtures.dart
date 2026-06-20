import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Matches [_runExtractionPhase] interception seed for the first player with
/// non-empty overseas allocation on turn [turnNumber].
int extractionAutoTransportInterceptionSeed({
  required int globalGameSeed,
  required int turnNumber,
  required String playerId,
}) {
  var extractionSeed =
      globalGameSeed ^ (turnNumber * kDeterministicHashMixPrime32);
  extractionSeed =
      (extractionSeed * kDeterministicLcgMultiplierGlibc +
          kDeterministicLcgIncrementGlibc) &
      kDeterministicLcg31Mask;
  return extractionSeed ^ playerId.hashCode;
}

MapTopology crossRegionSeaTopologyForExtractionTests() {
  return MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'n1',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'sea1',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'sea2',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [
      TopologyEdge(id1: 'p1', id2: 'sea1'),
      TopologyEdge(id1: 'n1', id2: 'sea2'),
      TopologyEdge(id1: 'sea1', id2: 'sea2'),
    ],
  );
}

final tileMapOldWorldGrain = TileMapResult(
  width: 1,
  height: 1,
  grid: [
    ['p1'],
  ],
  resourceGrid: [
    [Resource.grain],
  ],
);

TileMapState _tileStateForExtractionFixture(int nwImprovementLevel) {
  return TileMapState()
      .setImprovement('oldWorld|p1|0|0', 1)
      .setRoadLevel('oldWorld|p1|0|0', 4)
      .setImprovement('newWorld|n1|0|0', nwImprovementLevel)
      .setRoadLevel('newWorld|n1|0|0', 4)
      .setImprovement('newWorld|n1|1|0', nwImprovementLevel)
      .setRoadLevel('newWorld|n1|1|0', 4)
      .setImprovement('newWorld|n1|0|1', nwImprovementLevel)
      .setRoadLevel('newWorld|n1|0|1', 4)
      .setImprovement('newWorld|n1|1|1', nwImprovementLevel)
      .setRoadLevel('newWorld|n1|1|1', 4);
}

/// Cross-region extraction setup: OW capital grain tile + 2×2 NW grid.
({Game game, Map<String, TileMapResult> tileMapByRegion})
extractionAutoTransportFixture({
  required List<List<Resource?>> nwResourceGrid,
  required int nwImprovementLevel,
  List<Fleet> extraFleets = const [],
  int globalGameSeed = 0,
  RelationState relationWithP2 = RelationState.atPeace,
  Map<String, bool> techUnlocked = const {},
}) {
  const ow = 'oldWorld', nw = 'newWorld';
  final tileMapNw = TileMapResult(
    width: 2,
    height: 2,
    grid: const [
      ['n1', 'n1'],
      ['n1', 'n1'],
    ],
    resourceGrid: nwResourceGrid,
  );

  final tileState = _tileStateForExtractionFixture(nwImprovementLevel);

  final ports = {
    '$ow|p1|sea1': 'oldWorld|p1|0|0',
    '$nw|n1|sea2': 'newWorld|n1|0|0',
  };

  final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
  final homeFleet = Fleet(
    id: 'fleet_pl1',
    ownerId: 'pl1',
    inPortAtProvinceId: '$ow|p1',
    regionId: ow,
    shipTypeIds: const ['carrack'],
    mission: FleetMission.none,
  );

  final game = Game(
    id: 'g1',
    globalGameSeed: globalGameSeed,
    capitalTileGrainBonusPerTurn: 0,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: '$ow|p1',
            regionId: ow,
            ownerId: 'pl1',
            townDevelopmentLevel: 4,
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: '$nw|n1',
            regionId: nw,
            ownerId: 'pl1',
            townDevelopmentLevel: 4,
          ),
        ],
      ),
      tileState: tileState,
      portsByProvinceSeaboard: ports,
      fleets: [homeFleet, ...extraFleets],
    ),
    players: [
      Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|p1',
        capitalTile: cap,
        stockpile: const Stockpile().applyDelta(
          CommodityCatalog.grain.id,
          1000,
        ),
        techUnlocked: techUnlocked,
      ),
      const Player(id: 'p2', displayName: 'Rival', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'pl1',
        factionId2: 'p2',
        state: relationWithP2,
      ),
    ],
  );

  return (
    game: game,
    tileMapByRegion: {'oldWorld': tileMapOldWorldGrain, 'newWorld': tileMapNw},
  );
}
