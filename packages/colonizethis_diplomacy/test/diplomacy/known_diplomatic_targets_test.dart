import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Coverage for `knownDiplomaticTargetFactionIds` in `known_diplomatic_targets.dart`
/// (Refs #3290 test migration — per-package coverage gate for
/// `colonizethis_diplomacy`).
const _ow = 'oldWorld';
const _topology = MapTopology(nodes: [], edges: []);

void main() {
  suppressLogsForTests();

  group('knownDiplomaticTargetFactionIds', () {
    test('positive: relations (player as factionId2), visibility, and own '
        'units anchor surface known targets', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$_ow|p1', regionId: _ow, ownerId: 'gp1'),
              Province(id: '$_ow|p2', regionId: _ow, ownerId: 'minor1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeBuilder,
                ownerId: 'gp1',
                locationProvinceId: '$_ow|p1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'$_ow|p2|0|0': 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: const {
            _ow: {
              '$_ow|p2': ['$_ow|p2|0|0'],
            },
          },
        ),
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        // Player appears as factionId2 here (exercises the reverse branch).
        diplomacyRelations: const [
          DiplomacyRelation(factionId1: 'minor1', factionId2: 'gp1'),
        ],
      );

      final view = buildPlayerView(game, _topology, 'gp1');
      final targets = knownDiplomaticTargetFactionIds(
        view: view,
        game: game,
        topology: _topology,
      );

      expect(targets, contains('minor1'));
      expect(targets, isNot(contains('gp1')));
    });

    test('negative: no relations and no visibility yields no targets', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [Province(id: '$_ow|p1', regionId: _ow, ownerId: 'gp1')],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
      );

      final view = buildPlayerView(game, _topology, 'gp1');
      final targets = knownDiplomaticTargetFactionIds(
        view: view,
        game: game,
        topology: _topology,
      );

      expect(targets, isEmpty);
    });

    test(
      'negative (#3620): sea-reachable tribe with zero NW tile visibility is '
      'not a diplomatic target',
      () {
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|home',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|owSea',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'newWorld|nwSea',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'newWorld|colony',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
            TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
            TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
          ],
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(
              provinces: [
                Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|colony',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
              ],
            ),
            playerVisibilityByTile: const {
              'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                'oldWorld|home': ['oldWorld|home|0|0'],
              },
              'newWorld': {
                'newWorld|colony': ['newWorld|colony|0|0'],
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
          tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
        );

        final view = buildPlayerView(game, topology, 'gp1');
        final targets = knownDiplomaticTargetFactionIds(
          view: view,
          game: game,
          topology: topology,
        );

        expect(targets, isNot(contains('tribe1')));
      },
    );
  });
}
