import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const _owCapital = 'oldWorld|p_cap';
const _nwTiles = <String, List<String>>{
  'newWorld|p1': ['newWorld|p1|0|0', 'newWorld|p1|1|0'],
  'newWorld|p2': ['newWorld|p2|0|0'],
  'newWorld|p3': ['newWorld|p3|0|0'],
};

Game _worldKnowledgeFixtureGame() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: const RegionData(provinces: []),
      newWorld: RegionData(
        provinces: [
          Province(id: 'newWorld|p1', regionId: kRegionNewWorld, ownerId: 'tribe1'),
          Province(id: 'newWorld|p2', regionId: kRegionNewWorld, ownerId: 'tribe1'),
          Province(id: 'newWorld|p3', regionId: kRegionNewWorld, ownerId: 'tribe2'),
        ],
      ),
      playerVisibilityByTile: {
        'gp1': {
          'newWorld|p1|0|0': VisibilityLevel.unknown.name,
          'newWorld|p1|1|0': VisibilityLevel.unknown.name,
          'newWorld|p2|0|0': VisibilityLevel.unknown.name,
          'newWorld|p3|0|0': VisibilityLevel.unknown.name,
        },
      },
      playerProspectedTiles: const {'gp1': {}},
      tileKeysByRegionAndProvince: {kRegionNewWorld: _nwTiles},
      resourceByTileKey: {
        'newWorld|p1|0|0': 'iron',
        'newWorld|p1|1|0': 'grain',
        'newWorld|p2|0|0': 'gold',
        'newWorld|p3|0|0': 'copper',
      },
    ),
    players: const [
      Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: _owCapital,
      ),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
    tribes: const [
      Tribe(id: 'tribe1', displayName: 'Tribe 1'),
      Tribe(id: 'tribe2', displayName: 'Tribe 2'),
    ],
  );
}

MapTopology _owTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 'p_cap', regionId: kRegionOldWorld, type: TopologyNodeType.province),
    TopologyNode(id: 's1', regionId: kRegionOldWorld, type: TopologyNodeType.seaZone),
  ],
  edges: [TopologyEdge(id1: 'p_cap', id2: 's1')],
);

MapTopology _nwTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 's1', regionId: kRegionNewWorld, type: TopologyNodeType.seaZone),
    TopologyNode(id: 'p1', regionId: kRegionNewWorld, type: TopologyNodeType.province),
    TopologyNode(id: 'p2', regionId: kRegionNewWorld, type: TopologyNodeType.province),
    TopologyNode(id: 'p3', regionId: kRegionNewWorld, type: TopologyNodeType.province),
  ],
  edges: [
    TopologyEdge(id1: 's1', id2: 'p1'),
    TopologyEdge(id1: 'p1', id2: 'p2'),
    TopologyEdge(id1: 'p2', id2: 'p3'),
  ],
);

const _warpLinks = [
  WarpLink(
    regionId: kRegionOldWorld,
    seaZoneId: 's1',
    otherRegionId: kRegionNewWorld,
    otherSeaZoneId: 's1',
  ),
];

void main() {
  group('applyAdvancedStartWorldKnowledge', () {
    test('turns50 reveals contiguous NW provinces without prospecting', () {
      final result = applyAdvancedStartWorldKnowledge(
        game: _worldKnowledgeFixtureGame(),
        startType: AdvancedStartType.turns50,
        topologyOldWorld: _owTopology(),
        topologyNewWorld: _nwTopology(),
        warpLinks: _warpLinks,
      );

      final visibility =
          result.game.worldState.playerVisibilityByTile['gp1'] ?? const {};
      expect(
        visibility['newWorld|p1|0|0'],
        VisibilityLevel.fullyVisible.name,
      );
      expect(
        visibility['newWorld|p2|0|0'],
        VisibilityLevel.fullyVisible.name,
      );
      expect(result.encounteredTribeIds, contains('tribe1'));
      expect(result.encounteredTribeIds, isNot(contains('tribe2')));

      final prospected =
          result.game.worldState.playerProspectedTiles['gp1'] ?? const {};
      expect(prospected, isEmpty);
    });

    test('turns100 reveals all NW provinces', () {
      final result = applyAdvancedStartWorldKnowledge(
        game: _worldKnowledgeFixtureGame(),
        startType: AdvancedStartType.turns100,
        topologyOldWorld: _owTopology(),
        topologyNewWorld: _nwTopology(),
        warpLinks: _warpLinks,
      );

      final visibility =
          result.game.worldState.playerVisibilityByTile['gp1'] ?? const {};
      expect(
        visibility['newWorld|p3|0|0'],
        VisibilityLevel.fullyVisible.name,
      );
      expect(result.encounteredTribeIds, containsAll(['tribe1', 'tribe2']));
    });
  });

  group('applyAdvancedStartDiplomacy', () {
    test('turns50 adds consulates for minors and encountered tribes', () {
      final game = applyAdvancedStartDiplomacy(
        game: _worldKnowledgeFixtureGame(),
        startType: AdvancedStartType.turns50,
        encounteredTribeIds: const {'tribe1'},
      );

      expect(
        getOverture(game, 'gp1', 'minor1')!.stage,
        OvertureStage.tradeConsulate,
      );
      expect(
        getOverture(game, 'gp1', 'tribe1')!.stage,
        OvertureStage.tradeConsulate,
      );
      expect(getOverture(game, 'gp1', 'tribe2'), isNull);
    });

    test('turns100 adds embassies for minors and encountered tribes', () {
      final game = applyAdvancedStartDiplomacy(
        game: _worldKnowledgeFixtureGame(),
        startType: AdvancedStartType.turns100,
        encounteredTribeIds: const {'tribe1', 'tribe2'},
      );

      expect(getOverture(game, 'gp1', 'minor1')!.stage, OvertureStage.embassy);
      expect(getOverture(game, 'gp1', 'tribe2')!.hasEmbassy, isTrue);
    });
  });
}
