import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared corpus for `order_suggestion_shared_validator_*` tests
/// (Refs #2394, SPEC/program/order-suggestions.md § Throughput bounds).
///
/// Co-locates `buildGame` / `buildTopology` and the province ID constants so
/// the equivalence and negative-coverage suites stay below the 400-line
/// `repo.logic_test_file_size` ceiling without duplicating fixture bodies.
const String gp = 'gp1';
const String ow = 'oldWorld';
const String cap = '$ow|cap';
const String p1 = '$ow|p1';
const String p2 = '$ow|p2';

Game buildGame() {
  return Game(
    id: 'g_shared_validator',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: cap,
            regionId: ow,
            ownerId: gp,
            townTileKey: '$ow|cap|0|0',
          ),
          Province(id: p1, regionId: ow, ownerId: gp),
          Province(id: p2, regionId: ow, ownerId: 'gp2'),
        ],
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: gp,
            locationProvinceId: cap,
            tileKey: '$ow|cap|0|0',
          ),
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: gp,
            locationProvinceId: cap,
            tileKey: '$ow|cap|0|0',
          ),
          Unit(
            id: 'r1',
            type: 'musketeers',
            ownerId: gp,
            locationProvinceId: p1,
            tileKey: '$ow|p1|0|0',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: homeArmyIdFor(gp),
          ownerId: gp,
          regionId: ow,
          stationedProvinceId: cap,
          regimentUnitIds: const [],
          isHomeArmy: true,
        ),
        Army(
          id: 'field_a',
          ownerId: gp,
          regionId: ow,
          stationedProvinceId: p1,
          regimentUnitIds: const ['r1'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        ow: {
          cap: ['$ow|cap|0|0'],
          p1: ['$ow|p1|0|0'],
          p2: ['$ow|p2|0|0'],
        },
      },
      playerVisibilityByTile: const {
        gp: {
          '$ow|cap|0|0': 'fullyVisible',
          '$ow|p1|0|0': 'fullyVisible',
          '$ow|p2|0|0': 'fogged',
        },
      },
      resourceByTileKey: const {
        '$ow|p1|0|0': 'wood',
      },
    ),
    players: const [
      Player(
        id: gp,
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: cap,
        treasury: 999,
      ),
      Player(id: 'gp2', displayName: 'GP2', isHuman: true),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: gp,
        factionId2: 'gp2',
        state: RelationState.atWar,
      ),
    ],
  );
}

MapTopology buildTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(id: cap, regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: p1, regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: p2, regionId: ow, type: TopologyNodeType.province),
    ],
    edges: [
      TopologyEdge(id1: cap, id2: p1),
      TopologyEdge(id1: p1, id2: p2),
    ],
  );
}
