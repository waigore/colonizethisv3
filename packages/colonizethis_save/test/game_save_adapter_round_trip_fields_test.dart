import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart';

import 'support/game_save_adapter_test_harness.dart';

void main() {
  final harness = GameSaveAdapterHiveHarness(
    hivePath: './.dart_tool/test_hive_save_fields',
    boxName: 'games_fields',
  );

  setUpAll(harness.open);
  tearDownAll(harness.close);
  setUp(harness.reset);

  group('GameSaveAdapter field round-trips', () {
    test('save/load round-trip includes tile state, ports, and capital', () {
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 1);
      final game = Game(
        id: 'withCapital',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
          portsByProvinceSeaboard: {'p1|sea1': 'oldWorld|p1|0|0'},
        ),
        players: [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'withCapital');
      expect(loaded, isNotNull);
      expect(
        loaded!.worldState.tileState.improvementLevel('oldWorld|p1|0|0'),
        2,
      );
      expect(loaded.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 1);
      expect(
        loaded.worldState.portsByProvinceSeaboard['p1|sea1'],
        'oldWorld|p1|0|0',
      );
      expect(loaded.players.single.capitalProvinceId, 'oldWorld|p1');
      expect(loaded.players.single.capitalTile?.regionId, 'oldWorld');
      expect(loaded.players.single.capitalTile?.x, 0);
      expect(loaded.players.single.capitalTile?.y, 0);
    });

    test(
      'save/load round-trip preserves civilian origin/assigned tile fields',
      () {
        final unit = Unit(
          id: 'civ1',
          type: kUnitTypeBuilder,
          ownerId: 'pl1',
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|1|0',
          originTileKey: 'oldWorld|p1|0|0',
          assignedTileKey: 'oldWorld|p1|1|0',
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildImprovement,
            tileKey: 'oldWorld|p1|1|0',
            totalTurns: 2,
            remainingTurns: 1,
          ),
        );
        final game = Game(
          id: 'withCivilianAssignment',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'pl1',
                ),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
          ],
        );
        harness.adapter.save(harness.box, game);
        final loaded = harness.adapter.load(
          harness.box,
          'withCivilianAssignment',
        );
        expect(loaded, isNotNull);
        final loadedUnit = loaded!.worldState.oldWorld.units.single;
        expect(loadedUnit.originTileKey, 'oldWorld|p1|0|0');
        expect(loadedUnit.assignedTileKey, 'oldWorld|p1|1|0');
        expect(loadedUnit.tileKey, 'oldWorld|p1|1|0');
      },
    );

    test('save/load round-trip includes Phase 3 combat state', () {
      final game = Game(
        id: 'phase3',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                fortLevel: 2,
                terrain: 'hardwoodForest',
              ),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'pl1',
                locationProvinceId: 'oldWorld|p1',
                medals: 3,
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            militaryLevel: 4,
          ),
        ],
        minorNations: [MinorNation(id: 'min1', effectiveMilitaryLevel: 4)],
        tribes: [Tribe(id: 'tribe1', effectiveMilitaryLevel: 1)],
      );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'phase3');
      expect(loaded, isNotNull);
      expect(loaded!.worldState.oldWorld.provinces.single.fortLevel, 2);
      expect(
        loaded.worldState.oldWorld.provinces.single.terrain,
        'hardwoodForest',
      );
      expect(loaded.worldState.oldWorld.units.single.medals, 3);
      expect(loaded.players.single.militaryLevel, 4);
      expect(loaded.minorNations.single.effectiveMilitaryLevel, 4);
      expect(loaded.tribes.single.effectiveMilitaryLevel, 1);
    });

    test('save/load round-trip includes greatPowerColorOverride', () {
      final game = Game(
        id: 'colorOverride',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
        greatPowerColorOverride: {
          'gp1': [255, 0, 0],
          'gp2': [0, 255, 0],
        },
      );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'colorOverride');
      expect(loaded, isNotNull);
      expect(loaded!.greatPowerColorOverride, isNotNull);
      expect(loaded.greatPowerColorOverride!['gp1'], [255, 0, 0]);
      expect(loaded.greatPowerColorOverride!['gp2'], [0, 255, 0]);
    });

    test('save/load round-trip includes turnTimeMapping', () {
      final game = Game(
        id: 'turnTime',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
        turnTimeMapping: const TurnTimeMapping(
          startYear: 1600,
          cutoffYear: 1750,
          yearsPerTurnBeforeCutoff: 3,
          yearsPerTurnAfterCutoff: 2,
        ),
      );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'turnTime');
      expect(loaded, isNotNull);
      expect(loaded!.turnTimeMapping, isNotNull);
      expect(loaded.turnTimeMapping!.startYear, 1600);
      expect(loaded.turnTimeMapping!.cutoffYear, 1750);
      expect(loaded.turnTimeMapping!.yearsPerTurnBeforeCutoff, 3);
      expect(loaded.turnTimeMapping!.yearsPerTurnAfterCutoff, 2);
    });

    test('save/load round-trip includes mapViewState and legacy default', () {
      final game = Game(
        id: 'mapViewStateSave',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
        mapViewState: const MapViewState(
          zoomMultiplier: 3.5,
          showProvinceOverlay: false,
          showProvinceOwnershipTint: true,
          showProvinceNamesLayer: false,
          showCapitalLinkDisconnectedHighlight: false,
          showPlayerTurnEventsFeed: true,
          showMapResources: false,
          showMapImprovements: true,
          showMapRoads: false,
        ),
      );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'mapViewStateSave');
      expect(loaded, isNotNull);
      expect(loaded!.mapViewState.zoomMultiplier, 3.5);
      expect(loaded.mapViewState.showProvinceOverlay, isFalse);
      expect(loaded.mapViewState.showProvinceOwnershipTint, isTrue);
      expect(loaded.mapViewState.showProvinceNamesLayer, isFalse);
      expect(loaded.mapViewState.showCapitalLinkDisconnectedHighlight, isFalse);
      expect(loaded.mapViewState.showPlayerTurnEventsFeed, isTrue);
      expect(loaded.mapViewState.showPlayersBar, isTrue);
      expect(loaded.mapViewState.showMapResources, isFalse);
      expect(loaded.mapViewState.showMapImprovements, isTrue);
      expect(loaded.mapViewState.showMapRoads, isFalse);

      final legacyGameJson = Map<String, dynamic>.from(game.toJson())
        ..remove('mapViewState');
      harness.box.put('legacyMapViewStateSave', {
        'saveFormatVersion': kSaveFormatVersion,
        'game': legacyGameJson,
      });
      final legacyLoaded = harness.adapter.load(
        harness.box,
        'legacyMapViewStateSave',
      );
      expect(legacyLoaded, isNotNull);
      expect(legacyLoaded!.mapViewState, MapViewState.defaults);
      expect(legacyLoaded.mapViewState.showPlayerTurnEventsFeed, isFalse);
      expect(legacyLoaded.mapViewState.showPlayersBar, isTrue);
      expect(
        legacyLoaded.mapViewState.showCapitalLinkDisconnectedHighlight,
        isTrue,
      );

      final rematerializeId = 'legacyMapViewStateRematerialize';
      harness.adapter.save(
        harness.box,
        legacyLoaded.copyWith(id: rematerializeId),
      );
      final rematerialized =
          harness.box.get(rematerializeId) as Map<dynamic, dynamic>;
      final rematerializedGame =
          rematerialized['game'] as Map<dynamic, dynamic>;
      expect(rematerializedGame.containsKey('mapViewState'), isTrue);
      expect(
        (rematerializedGame['mapViewState']
            as Map<dynamic, dynamic>)['showPlayersBar'],
        isTrue,
      );
    });

    test(
      'load succeeds when turnTimeMapping is Map<dynamic,dynamic> (Hive typing)',
      () {
        final turnMap = <dynamic, dynamic>{
          'startYear': 1600,
          'cutoffYear': 1750,
          'yearsPerTurnBeforeCutoff': 3,
          'yearsPerTurnAfterCutoff': 2,
        };
        final gameJson = <String, dynamic>{
          'id': 'hiveTurnMap',
          'worldState': {
            'turnState': {'phase': 'orders', 'turnNumber': 1},
            'oldWorld': {'provinces': []},
            'newWorld': {'provinces': []},
          },
          'players': [
            {'id': 'pl1', 'displayName': 'Spain', 'isHuman': true},
          ],
          'turnTimeMapping': turnMap,
        };
        harness.box.put('hiveTurnMap', {
          'saveFormatVersion': kSaveFormatVersion,
          'game': gameJson,
        });
        final loaded = harness.adapter.load(harness.box, 'hiveTurnMap');
        expect(loaded, isNotNull);
        expect(loaded!.turnTimeMapping, isNotNull);
        expect(loaded.turnTimeMapping!.startYear, 1600);
        expect(loaded.turnTimeMapping!.cutoffYear, 1750);
        expect(loaded.turnTimeMapping!.yearsPerTurnBeforeCutoff, 3);
        expect(loaded.turnTimeMapping!.yearsPerTurnAfterCutoff, 2);
      },
    );

    test(
      'load supports missing greatPowerColorOverride within current envelope',
      () {
        final gameJson = {
          'id': 'legacyGame',
          'worldState': {
            'turnState': {'phase': 'orders', 'turnNumber': 1},
            'oldWorld': {'provinces': []},
            'newWorld': {'provinces': []},
          },
          'players': [
            {'id': 'pl1', 'displayName': 'Spain', 'isHuman': true},
          ],
        };
        harness.box.put('legacyGame', {
          'saveFormatVersion': kSaveFormatVersion,
          'game': gameJson,
        });
        final loaded = harness.adapter.load(harness.box, 'legacyGame');
        expect(loaded, isNotNull);
        expect(loaded!.greatPowerColorOverride, isNull);
      },
    );

    test('load supports missing turnTimeMapping within current envelope', () {
      final gameJson = {
        'id': 'legacyGame2',
        'worldState': {
          'turnState': {'phase': 'orders', 'turnNumber': 1},
          'oldWorld': {'provinces': []},
          'newWorld': {'provinces': []},
        },
        'players': [
          {'id': 'pl1', 'displayName': 'Spain', 'isHuman': true},
        ],
      };
      harness.box.put('legacyGame2', {
        'saveFormatVersion': kSaveFormatVersion,
        'game': gameJson,
      });
      final loaded = harness.adapter.load(harness.box, 'legacyGame2');
      expect(loaded, isNotNull);
      expect(loaded!.turnTimeMapping, isNull);
    });
  });
}
