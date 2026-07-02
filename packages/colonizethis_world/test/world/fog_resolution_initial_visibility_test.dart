import 'package:colonizethis_world/src/world/fog_resolution.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/world/province_owner_cache.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_turn/src/turn/end_of_turn_resolver.dart';

void main() {
group('applyInitialVisibility coastal sea zone', () {
    test(
      'sets sea zone tiles adjacent to owned province to fullyVisible at game setup',
      () {
        // SPEC/program/fog-and-exploration-resolution.md: coastal sea zone visibility
        // is applied during game setup after initial visibility assignment.
        const ow = 'oldWorld';
        const tileKeySea = 'oldWorld|s1|1|0';
        const tileKeyLand = 'oldWorld|p1|0|0';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {
                tileKeyLand: 'fullyVisible',
                tileKeySea: 'fogged', // Initial state before coastal visibility
              },
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                'p1': [tileKeyLand],
                '$ow|s1': [tileKeySea],
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        // Apply coastal sea zone visibility as done during game setup
        final inputVis = game.worldState.playerVisibilityByTile;
        final out = applyCoastalSeaZoneFullVisibility(
          game,
          inputVis,
          topology,
          topologyByRegion: {ow: topology},
        );

        // Sea zone adjacent to owned province should be fullyVisible
        expect(out['gp1']![tileKeySea], VisibilityLevel.fullyVisible.name);
        // Land tile should remain fullyVisible
        expect(out['gp1']![tileKeyLand], VisibilityLevel.fullyVisible.name);
      },
    );

    test('coastal sea zone visibility at game setup: multiple GPs', () {
      // Verify that each GP only sees sea zones adjacent to their own provinces
      const ow = 'oldWorld';
      const tileKeyS1 = 'oldWorld|s1|1|0';
      const tileKeyS2 = 'oldWorld|s2|3|0';
      const tileKeyP1 = 'oldWorld|p1|0|0';
      const tileKeyP2 = 'oldWorld|p2|2|0';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 's1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: 's2', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 's1'),
          TopologyEdge(id1: 'p2', id2: 's2'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              tileKeyP1: 'fullyVisible',
              tileKeyP2: 'fogged',
              tileKeyS1: 'fogged',
              tileKeyS2: 'fogged',
            },
            'gp2': {
              tileKeyP1: 'fogged',
              tileKeyP2: 'fullyVisible',
              tileKeyS1: 'fogged',
              tileKeyS2: 'fogged',
            },
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              'p1': [tileKeyP1],
              'p2': [tileKeyP2],
              '$ow|s1': [tileKeyS1],
              '$ow|s2': [tileKeyS2],
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
      );

      final inputVis = game.worldState.playerVisibilityByTile;
      final out = applyCoastalSeaZoneFullVisibility(
        game,
        inputVis,
        topology,
        topologyByRegion: {ow: topology},
      );

      // GP1: sees s1 (adjacent to p1), not s2
      expect(out['gp1']![tileKeyS1], VisibilityLevel.fullyVisible.name);
      expect(out['gp1']![tileKeyS2], 'fogged');
      // GP2: sees s2 (adjacent to p2), not s1
      expect(out['gp2']![tileKeyS1], 'fogged');
      expect(out['gp2']![tileKeyS2], VisibilityLevel.fullyVisible.name);
    });
  });

}
