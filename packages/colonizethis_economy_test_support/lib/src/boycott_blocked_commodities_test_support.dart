// Shared fixtures for `boycottedColonySellableCommodityIds` tests (Refs #3758
// S7/R12; #3831 Phase 4 hoisting from near-cap economy test files).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'non_gp_extraction_test_support.dart';

/// New-World region id used by boycott colony-tribe fixtures.
const boycottColonyTribeNwRegionId = 'newWorld';

/// Prefixed province id for the single-tile colony Tribe in boycott fixtures.
const boycottColonyTribeProvinceId = 'newWorld|t1';

/// Builds a minimal game with a one-tile New-World tribe `t1` whose developed
/// tile produces furs so `computeNonGreatPowerAutoOffers` emits a furs offer.
Game gameWithColonyTribeBoycottTest({
  List<ColonyState> colonyStates = const [],
  List<BoycottState> boycottStates = const [],
}) {
  final tileState = TileMapState()
      .setImprovement('newWorld|t1|0|0', 1)
      .setRoadLevel('newWorld|t1|0|0', 1);
  return Game(
    id: 'g_boycott_test',
    worldState: WorldState(
      turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(
            id: boycottColonyTribeProvinceId,
            regionId: boycottColonyTribeNwRegionId,
            ownerId: 't1',
            townDevelopmentLevel: 1,
          ),
        ],
      ),
      tileState: tileState,
    ),
    players: [
      Player(id: 'gpA', displayName: 'Aragon', isHuman: false),
      Player(id: 'gpC', displayName: 'Castile', isHuman: false),
    ],
    tribes: [testTribe()],
    colonyStates: colonyStates,
    boycottStates: boycottStates,
  );
}

/// Tile maps for [gameWithColonyTribeBoycottTest] (single furs tile in `t1`).
Map<String, TileMapResult> tileMapsForBoycottColonyTribeTest() => {
  boycottColonyTribeNwRegionId: tileMapAllInProvinceForNonGpExtractionTest(
    provinceId: boycottColonyTribeProvinceId,
    width: 1,
    height: 1,
    resources: const [
      [Resource.furs],
    ],
  ),
};

/// Minimal topology for boycott colony-tribe fixtures.
MapTopology topologyForBoycottColonyTribeTest() => const MapTopology(
  nodes: [
    TopologyNode(
      id: 't1',
      regionId: boycottColonyTribeNwRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);
