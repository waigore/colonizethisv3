import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/logic_validation_exception.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up):
/// buildPlayerView / hasRevealedResourceForPlayer / panel intel gate. See
/// SPEC/program/player-view.md, SPEC/program/fog-and-exploration-resolution.md.
const _topology = MapTopology();

Unit _spy({required String id, required String ownerId, required String loc}) =>
    Unit(id: id, type: kUnitTypeSpy, ownerId: ownerId, locationProvinceId: loc);

void main() {
  group('buildPlayerView', () {
    test('throws when the player is not present in the game', () {
      final game = TestFixtures.minimalGame();
      expect(
        () => buildPlayerView(game, _topology, 'ghost'),
        throwsA(isA<LogicValidationException>()),
      );
    });

    test('indexes own units, provinces, and diplomacy by other faction id', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
        oldWorld: RegionData(
          provinces: const [
            Province(id: 'oldWorld|a', regionId: 'oldWorld', ownerId: 'p1'),
            Province(id: 'oldWorld|b', regionId: 'oldWorld', ownerId: 'p2'),
          ],
          units: [
            Unit(
              id: 'mine',
              type: kUnitTypeExplorer,
              ownerId: 'p1',
              locationProvinceId: 'oldWorld|a',
            ),
            Unit(
              id: 'theirs',
              type: kUnitTypeExplorer,
              ownerId: 'p2',
              locationProvinceId: 'oldWorld|b',
            ),
          ],
        ),
        diplomacyRelations: const [
          DiplomacyRelation(factionId1: 'p2', factionId2: 'p1'),
        ],
      );

      final view = buildPlayerView(game, _topology, 'p1');

      expect(view.playerId, 'p1');
      expect(view.ownUnitsById.keys, ['mine']);
      expect(view.provincesById.keys, containsAll(['oldWorld|a', 'oldWorld|b']));
      // Relation indexed by the OTHER faction id even when p1 is factionId2.
      expect(view.relationWith('p2'), isNotNull);
    });

    test('maps tile visibility names and defaults unknown for bad names', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        playerVisibilityByTile: const {
          'p1': {
            't_full': 'fullyVisible',
            't_fog': 'fogged',
            't_bad': 'not-a-level',
          },
        },
      );

      final view = buildPlayerView(game, _topology, 'p1');

      expect(view.visibilityForTile('t_full'), VisibilityLevel.fullyVisible);
      expect(view.visibilityForTile('t_fog'), VisibilityLevel.fogged);
      expect(view.visibilityForTile('t_bad'), VisibilityLevel.unknown);
    });

    test('own spy in a foreign province reveals that province tiles', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
        oldWorld: RegionData(
          provinces: const [
            Province(id: 'oldWorld|enemy', regionId: 'oldWorld', ownerId: 'p2'),
          ],
          units: [
            _spy(id: 's1', ownerId: 'p1', loc: 'oldWorld|enemy'),
          ],
        ),
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|enemy': ['enemyTile'],
          },
        },
      );

      final view = buildPlayerView(game, _topology, 'p1');
      expect(view.visibilityForTile('enemyTile'), VisibilityLevel.fullyVisible);
    });

    test('at-war Old World enemy province is at least fogged for borders', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|enemy', regionId: 'oldWorld', ownerId: 'p2'),
          ],
        ),
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'enemy': ['borderTile'],
          },
        },
        playerVisibilityByTile: const {
          'p1': {'borderTile': 'unknown'},
        },
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
        ],
      );

      final view = buildPlayerView(game, _topology, 'p1');
      expect(view.visibilityForTile('borderTile'), VisibilityLevel.fogged);
    });

    test('peace with the Old World owner leaves tiles unknown', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|enemy', regionId: 'oldWorld', ownerId: 'p2'),
          ],
        ),
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'enemy': ['borderTile'],
          },
        },
        playerVisibilityByTile: const {
          'p1': {'borderTile': 'unknown'},
        },
        diplomacyRelations: const [
          DiplomacyRelation(factionId1: 'p1', factionId2: 'p2'),
        ],
      );

      final view = buildPlayerView(game, _topology, 'p1');
      expect(view.visibilityForTile('borderTile'), VisibilityLevel.unknown);
    });

    test('prospected tiles are taken from the per-player set', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        playerProspectedTiles: const {
          'p1': {'tA', 'tB'},
        },
      );
      final view = buildPlayerView(game, _topology, 'p1');
      expect(view.tileIsProspected('tA'), isTrue);
      expect(view.tileIsProspected('tC'), isFalse);
    });
  });

  group('hasRevealedResourceForPlayer', () {
    test('true for a surface resource on a non-unknown tile', () {
      final game = TestFixtures.minimalGame(
        resourceByTileKey: const {'t1': 'food'},
        playerVisibilityByTile: const {
          'p1': {'t1': 'fogged'},
        },
      );
      expect(hasRevealedResourceForPlayer(game, 'p1', 'food'), isTrue);
    });

    test('false for an unknown tile', () {
      final game = TestFixtures.minimalGame(
        resourceByTileKey: const {'t1': 'food'},
        playerVisibilityByTile: const {
          'p1': {'t1': 'unknown'},
        },
      );
      expect(hasRevealedResourceForPlayer(game, 'p1', 'food'), isFalse);
    });

    test('prospect-required resource needs the tile prospected', () {
      final base = TestFixtures.minimalGame(
        resourceByTileKey: const {'t1': 'gold'},
        playerVisibilityByTile: const {
          'p1': {'t1': 'fullyVisible'},
        },
      );
      expect(hasRevealedResourceForPlayer(base, 'p1', 'gold'), isFalse);

      final prospected = TestFixtures.minimalGame(
        resourceByTileKey: const {'t1': 'gold'},
        playerVisibilityByTile: const {
          'p1': {'t1': 'fullyVisible'},
        },
        playerProspectedTiles: const {
          'p1': {'t1'},
        },
      );
      expect(hasRevealedResourceForPlayer(prospected, 'p1', 'gold'), isTrue);
    });
  });

  group('provincePanelShowsFullTileDerivedIntel', () {
    PlayerView viewWith({
      Map<String, Province> provincesById = const {},
      List<Unit> ownUnits = const [],
      Map<String, VisibilityLevel> visibilityByTile = const {},
    }) {
      return PlayerView(
        playerId: 'p1',
        player: const Player(id: 'p1', displayName: 'P1', isHuman: true),
        ownUnitsById: {for (final u in ownUnits) u.id: u},
        provincesById: provincesById,
        visibilityByTile: visibilityByTile,
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
    }

    test('own province always shows full intel', () {
      final game = TestFixtures.minimalGame();
      final view = viewWith(
        provincesById: const {
          'oldWorld|a': Province(
            id: 'oldWorld|a',
            regionId: 'oldWorld',
            ownerId: 'p1',
          ),
        },
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: view,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|a',
          provinceTileKeys: const ['t1'],
        ),
        isTrue,
      );
    });

    test('foreign province with own spy present shows full intel', () {
      final game = TestFixtures.minimalGame();
      final view = viewWith(
        provincesById: const {
          'oldWorld|e': Province(
            id: 'oldWorld|e',
            regionId: 'oldWorld',
            ownerId: 'p2',
          ),
        },
        ownUnits: [
          _spy(id: 's1', ownerId: 'p1', loc: 'oldWorld|e'),
        ],
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: view,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|e',
          provinceTileKeys: const ['t1'],
        ),
        isTrue,
      );
    });

    test('foreign province with an active spy-reveal timer shows full intel', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          spyRevealTurnsByPlayer: const {
            'p1': {'oldWorld|e': 2},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final view = viewWith(
        provincesById: const {
          'oldWorld|e': Province(
            id: 'oldWorld|e',
            regionId: 'oldWorld',
            ownerId: 'p2',
          ),
        },
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: view,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|e',
          provinceTileKeys: const ['t1'],
        ),
        isTrue,
      );
    });

    test('foreign province is full only when every tile is fully visible', () {
      final game = TestFixtures.minimalGame();
      final province = const Province(
        id: 'oldWorld|e',
        regionId: 'oldWorld',
        ownerId: 'p2',
      );
      final fullView = viewWith(
        provincesById: {'oldWorld|e': province},
        visibilityByTile: const {
          't1': VisibilityLevel.fullyVisible,
          't2': VisibilityLevel.fullyVisible,
        },
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: fullView,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|e',
          provinceTileKeys: const ['t1', 't2'],
        ),
        isTrue,
      );

      final partialView = viewWith(
        provincesById: {'oldWorld|e': province},
        visibilityByTile: const {
          't1': VisibilityLevel.fullyVisible,
          't2': VisibilityLevel.fogged,
        },
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: partialView,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|e',
          provinceTileKeys: const ['t1', 't2'],
        ),
        isFalse,
      );
    });

    test('foreign province with no known tiles is not full intel', () {
      final game = TestFixtures.minimalGame();
      final view = viewWith(
        provincesById: const {
          'oldWorld|e': Province(
            id: 'oldWorld|e',
            regionId: 'oldWorld',
            ownerId: 'p2',
          ),
        },
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: view,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|e',
          provinceTileKeys: const [],
        ),
        isFalse,
      );
    });
  });
}
