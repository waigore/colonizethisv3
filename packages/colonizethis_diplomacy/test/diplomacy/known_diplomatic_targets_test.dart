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
  });
}
