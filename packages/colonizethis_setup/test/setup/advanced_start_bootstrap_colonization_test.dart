import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const _owCapital = 'oldWorld|p_cap';

Game _colonizationFixture({
  List<Province> nwProvinces = const [],
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 100),
      oldWorld: const RegionData(provinces: []),
      newWorld: RegionData(provinces: nwProvinces),
      tileKeysByRegionAndProvince: {
        kRegionNewWorld: {
          for (final p in nwProvinces)
            (ProvinceId.isPrefixed(p.id)
                    ? p.id
                    : ProvinceId.full(p.regionId, p.id)):
                [
              '${ProvinceId.isPrefixed(p.id) ? p.id : ProvinceId.full(p.regionId, p.id)}|0|0',
            ],
        },
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

MapTopology _nwTopology() {
  return MapTopology(
    nodes: [
      const TopologyNode(
        id: 's1',
        regionId: kRegionNewWorld,
        type: TopologyNodeType.seaZone,
      ),
      for (var i = 1; i <= 8; i++)
        TopologyNode(
          id: 'p$i',
          regionId: kRegionNewWorld,
          type: TopologyNodeType.province,
        ),
    ],
    edges: const [
      TopologyEdge(id1: 's1', id2: 'p1'),
      TopologyEdge(id1: 'p1', id2: 'p2'),
      TopologyEdge(id1: 'p2', id2: 'p3'),
      TopologyEdge(id1: 'p3', id2: 'p4'),
      TopologyEdge(id1: 'p4', id2: 'p5'),
      TopologyEdge(id1: 'p5', id2: 'p6'),
      TopologyEdge(id1: 'p6', id2: 'p7'),
      TopologyEdge(id1: 'p7', id2: 'p8'),
    ],
  );
}

List<Province> _nwColonizationProvinces() {
  return [
    for (var i = 1; i <= 7; i++)
      Province(
        id: 'newWorld|p$i',
        regionId: kRegionNewWorld,
        ownerId: 'tribe1',
      ),
    Province(
      id: 'newWorld|p8',
      regionId: kRegionNewWorld,
      ownerId: 'tribe2',
    ),
  ];
}

TileMapResult _nwTileMap() => TileMapResult(
  width: 3,
  height: 3,
  grid: const [
    ['p1', 'p2', 'p3'],
    ['p4', 'p5', 'p6'],
    ['p7', 'p8', 'p8'],
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
  group('applyAdvancedStartNwColonization', () {
    test('turns100 assigns six contiguous provinces to GP from warp entry', () {
      final game = applyAdvancedStartNwColonization(
        game: _colonizationFixture(nwProvinces: _nwColonizationProvinces()),
        startType: AdvancedStartType.turns100,
        topologyOldWorld: _owTopology(),
        topologyNewWorld: _nwTopology(),
        warpLinks: _warpLinks,
        tileMapByRegion: {kRegionNewWorld: _nwTileMap()},
        topologyByRegion: {kRegionNewWorld: _nwTopology()},
      );

      final gpOwned = game.worldState.newWorld.provinces
          .where((p) => p.ownerId == 'gp1')
          .length;
      expect(gpOwned, 6);
      expect(
        game.worldState.newWorld.provinces
            .where((p) => p.ownerId == 'tribe1')
            .length,
        greaterThanOrEqualTo(1),
      );
      expect(
        game.worldState.newWorld.provinces
            .where((p) => p.ownerId == 'tribe2')
            .length,
        greaterThanOrEqualTo(1),
      );
    });

    test('turns50 skips colonization', () {
      final nwProvinces = [
        Province(
          id: 'newWorld|p1',
          regionId: kRegionNewWorld,
          ownerId: 'tribe1',
        ),
      ];
      final game = applyAdvancedStartNwColonization(
        game: _colonizationFixture(nwProvinces: nwProvinces),
        startType: AdvancedStartType.turns50,
        topologyOldWorld: _owTopology(),
        topologyNewWorld: _nwTopology(),
        warpLinks: _warpLinks,
        tileMapByRegion: {kRegionNewWorld: _nwTileMap()},
        topologyByRegion: {kRegionNewWorld: _nwTopology()},
      );
      expect(
        game.worldState.newWorld.provinces.single.ownerId,
        'tribe1',
      );
    });
  });
}
