import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

void main() {
  late Box<dynamic> box;
  late GameSaveAdapter adapter;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive');
    box = await Hive.openBox<dynamic>('games');
  });

  tearDownAll(() async {
    await box.close();
  });

  setUp(() async {
    await box.clear();
    adapter = GameSaveAdapter();
  });

  group('GameSaveAdapter', () {
    test('save then load returns same game', () {
      final game = Game(
        id: 'game1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 5),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'player1',
              ),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'player1', displayName: 'Spain', isHuman: true),
        ],
      );
      adapter.save(box, game);
      final loaded = adapter.load(box, 'game1');
      expect(loaded, isNotNull);
      expect(loaded!.id, game.id);
      expect(loaded.worldState.turnState.turnNumber, 5);
      expect(loaded.worldState.oldWorld.provinces.length, 1);
      expect(loaded.players.length, 1);
      expect(loaded.players.first.displayName, 'Spain');
    });

    test('load returns null for missing id', () {
      expect(adapter.load(box, 'missing'), isNull);
    });

    test('listGameIds returns saved ids and excludes map-data keys', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      adapter.save(box, game);
      adapter.save(box, game.copyWith(id: 'g2'));
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 'p1'],
          ['p2', 's1'],
        ],
      );
      final topo = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [],
      );
      adapter.saveMapData(
        box,
        'g1',
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      expect(adapter.listGameIds(box), containsAll(['g1', 'g2']));
      expect(adapter.listGameIds(box).length, 2);
    });

    test(
      'listGameIds returns game id that ends with suffix when no matching map-data exists',
      () {
        final game = Game(
          id: 'mygame_tileMapByRegion',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [],
        );
        adapter.save(box, game);
        adapter.save(box, game.copyWith(id: 'normalGame'));

        final ids = adapter.listGameIds(box);
        expect(ids, containsAll(['mygame_tileMapByRegion', 'normalGame']));
        expect(ids.length, 2);
      },
    );

    test(
      'listGameIds excludes map-data keys when corresponding game exists',
      () {
        final game = Game(
          id: 'gameWithMapData',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [],
        );
        adapter.save(box, game);

        final tileMap = TileMapResult(
          width: 2,
          height: 2,
          grid: [
            ['p1', 'p1'],
            ['p2', 's1'],
          ],
        );
        final topo = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        adapter.saveMapData(
          box,
          'gameWithMapData',
          tileMapByRegion: {'oldWorld': tileMap},
          topologyByRegion: {'oldWorld': topo},
          combinedTopology: topo,
        );

        final ids = adapter.listGameIds(box);
        expect(ids, contains('gameWithMapData'));
        expect(ids.length, 1);
        expect(ids, isNot(contains('gameWithMapData_tileMapByRegion')));
        expect(ids, isNot(contains('gameWithMapData_topologyByRegion')));
        expect(ids, isNot(contains('gameWithMapData_combinedTopology')));
      },
    );

    test('saveMapData then loadMapData returns same data', () {
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 'p2'],
          ['s1', 's1'],
        ],
        terrainGrid: [
          [TerrainType.plains, TerrainType.forest],
          [null, null],
        ],
        resourceGrid: [
          [Resource.grain, null],
          [null, null],
        ],
      );
      final topo = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      adapter.saveMapData(
        box,
        'mapGame',
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      final loaded = adapter.loadMapData(box, 'mapGame');
      expect(loaded, isNotNull);
      expect(loaded.tileMapByRegion['oldWorld']!.width, 2);
      expect(loaded.tileMapByRegion['oldWorld']!.height, 2);
      expect(loaded.tileMapByRegion['oldWorld']!.cell(0, 0), 'p1');
      expect(
        loaded.tileMapByRegion['oldWorld']!.terrainAt(0, 0),
        TerrainType.plains,
      );
      expect(
        loaded.tileMapByRegion['oldWorld']!.resourceAt(0, 0),
        Resource.grain,
      );
      expect(loaded.combinedTopology.nodes.length, 3);
      expect(loaded.combinedTopology.edges.length, 1);
    });

    test('loadMapData throws when required map data is missing', () {
      expect(
        () => adapter.loadMapData(box, 'noMapData'),
        throwsA(isA<StateError>()),
      );
    });

    test('delete removes game', () {
      final game = Game(
        id: 'toDelete',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      adapter.save(box, game);
      expect(adapter.load(box, 'toDelete'), isNotNull);
      adapter.delete(box, 'toDelete');
      expect(adapter.load(box, 'toDelete'), isNull);
    });

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
      adapter.save(box, game);
      final loaded = adapter.load(box, 'withCapital');
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
        adapter.save(box, game);
        final loaded = adapter.load(box, 'withCivilianAssignment');
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
                terrain: 'forest',
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
      adapter.save(box, game);
      final loaded = adapter.load(box, 'phase3');
      expect(loaded, isNotNull);
      expect(loaded!.worldState.oldWorld.provinces.single.fortLevel, 2);
      expect(loaded.worldState.oldWorld.provinces.single.terrain, 'forest');
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
      adapter.save(box, game);
      final loaded = adapter.load(box, 'colorOverride');
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
      adapter.save(box, game);
      final loaded = adapter.load(box, 'turnTime');
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
          showPlayerTurnEventsFeed: true,
        ),
      );
      adapter.save(box, game);
      final loaded = adapter.load(box, 'mapViewStateSave');
      expect(loaded, isNotNull);
      expect(loaded!.mapViewState.zoomMultiplier, 3.5);
      expect(loaded.mapViewState.showProvinceOverlay, isFalse);
      expect(loaded.mapViewState.showProvinceOwnershipTint, isTrue);
      expect(loaded.mapViewState.showProvinceNamesLayer, isFalse);
      expect(loaded.mapViewState.showPlayerTurnEventsFeed, isTrue);

      final legacyGameJson = Map<String, dynamic>.from(game.toJson())
        ..remove('mapViewState');
      box.put('legacyMapViewStateSave', {
        'saveFormatVersion': kSaveFormatVersion,
        'game': legacyGameJson,
      });
      final legacyLoaded = adapter.load(box, 'legacyMapViewStateSave');
      expect(legacyLoaded, isNotNull);
      expect(legacyLoaded!.mapViewState, MapViewState.defaults);
      expect(legacyLoaded.mapViewState.showPlayerTurnEventsFeed, isFalse);
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
        box.put('hiveTurnMap', {
          'saveFormatVersion': kSaveFormatVersion,
          'game': gameJson,
        });
        final loaded = adapter.load(box, 'hiveTurnMap');
        expect(loaded, isNotNull);
        expect(loaded!.turnTimeMapping, isNotNull);
        expect(loaded.turnTimeMapping!.startYear, 1600);
        expect(loaded.turnTimeMapping!.cutoffYear, 1750);
        expect(loaded.turnTimeMapping!.yearsPerTurnBeforeCutoff, 3);
        expect(loaded.turnTimeMapping!.yearsPerTurnAfterCutoff, 2);
      },
    );

    test('loadMapData throws for invalid map data JSON', () {
      // Manually insert invalid map data to simulate corrupted save
      box.put('invalidMap_tileMapByRegion', {'invalid': 'data'});
      box.put('invalidMap_topologyByRegion', {'nodes': 'not-a-list'});
      box.put('invalidMap_combinedTopology', 'also invalid');
      expect(
        () => adapter.loadMapData(box, 'invalidMap'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'load supports missing greatPowerColorOverride within current envelope',
      () {
        // Simulate a current-version payload where this optional field is absent.
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
          // Note: greatPowerColorOverride is intentionally missing
        };
        box.put('legacyGame', {
          'saveFormatVersion': kSaveFormatVersion,
          'game': gameJson,
        });
        final loaded = adapter.load(box, 'legacyGame');
        expect(loaded, isNotNull);
        expect(loaded!.greatPowerColorOverride, isNull);
      },
    );

    group('Auto-save slot (kAutoSaveSlotId)', () {
      Game minimalGame(String logicalId) {
        return Game(
          id: logicalId,
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'player1', displayName: 'Spain', isHuman: true),
          ],
        );
      }

      (TileMapResult, MapTopology) minimalMap() {
        final tileMap = TileMapResult(
          width: 2,
          height: 2,
          grid: [
            ['p1', 'p1'],
            ['p2', 's1'],
          ],
        );
        final topo = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 's1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [],
        );
        return (tileMap, topo);
      }

      test('saveAutoSave then load round-trip preserves logical game id', () {
        final game = minimalGame('session_abc');
        final (tileMap, topo) = minimalMap();
        adapter.saveAutoSave(
          box,
          game,
          tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
          topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
          combinedTopology: topo,
        );
        expect(adapter.hasValidAutoSave(box), isTrue);
        final loaded = adapter.load(box, kAutoSaveSlotId);
        expect(loaded, isNotNull);
        expect(loaded!.id, 'session_abc');
        expect(loaded.worldState.turnState.turnNumber, 3);
        final md = adapter.loadMapData(box, kAutoSaveSlotId);
        expect(md.tileMapByRegion['oldWorld']!.width, 2);
      });

      test(
        'hasValidAutoSave true when turnTimeMapping is Map<dynamic,dynamic>',
        () {
          final game = minimalGame('session_abc').copyWith(
            turnTimeMapping: const TurnTimeMapping(
              startYear: 1600,
              cutoffYear: 1750,
              yearsPerTurnBeforeCutoff: 3,
              yearsPerTurnAfterCutoff: 2,
            ),
          );
          final (tileMap, topo) = minimalMap();
          final slotGameJson = Map<String, dynamic>.from(game.toJson());
          slotGameJson['turnTimeMapping'] = <dynamic, dynamic>{
            'startYear': 1600,
            'cutoffYear': 1750,
            'yearsPerTurnBeforeCutoff': 3,
            'yearsPerTurnAfterCutoff': 2,
          };
          box.put(kAutoSaveSlotId, {
            'saveFormatVersion': kSaveFormatVersion,
            'game': slotGameJson,
          });
          adapter.saveMapData(
            box,
            kAutoSaveSlotId,
            tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
            topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
            combinedTopology: topo,
          );
          expect(adapter.hasValidAutoSave(box), isTrue);
          final loaded = adapter.load(box, kAutoSaveSlotId);
          expect(loaded, isNotNull);
          expect(loaded!.turnTimeMapping!.startYear, 1600);
        },
      );

      test(
        'listGameIds excludes auto-save stem even when slot is populated',
        () {
          final game = minimalGame('only_logical');
          final (tileMap, topo) = minimalMap();
          adapter.saveAutoSave(
            box,
            game,
            tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
            topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
            combinedTopology: topo,
          );
          expect(adapter.listGameIds(box), isEmpty);
        },
      );

      test('listGameIds excludes stem when user game also exists', () {
        final userGame = minimalGame('user_slot');
        adapter.save(box, userGame);
        final (tileMap, topo) = minimalMap();
        adapter.saveMapData(
          box,
          'user_slot',
          tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
          topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
          combinedTopology: topo,
        );
        adapter.saveAutoSave(
          box,
          userGame,
          tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
          topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
          combinedTopology: topo,
        );
        expect(adapter.listGameIds(box), ['user_slot']);
      });

      test('hasValidAutoSave is false when slot empty', () {
        expect(adapter.hasValidAutoSave(box), isFalse);
      });

      test('hasValidAutoSave clears slot when game JSON is corrupt', () {
        box.put(kAutoSaveSlotId, 'not-json');
        expect(adapter.hasValidAutoSave(box), isFalse);
        expect(box.containsKey(kAutoSaveSlotId), isFalse);
      });

      test('hasValidAutoSave clears slot when map data missing', () {
        final game = minimalGame('g');
        box.put(kAutoSaveSlotId, {
          'saveFormatVersion': kSaveFormatVersion,
          'game': game.toJson(),
        });
        expect(adapter.hasValidAutoSave(box), isFalse);
        expect(box.containsKey(kAutoSaveSlotId), isFalse);
      });

      test('hasValidAutoSave clears slot when map data invalid', () {
        final game = minimalGame('g');
        box.put(kAutoSaveSlotId, {
          'saveFormatVersion': kSaveFormatVersion,
          'game': game.toJson(),
        });
        box.put('${kAutoSaveSlotId}_tileMapByRegion', {'bad': 'data'});
        box.put('${kAutoSaveSlotId}_topologyByRegion', {'bad': 'data'});
        box.put('${kAutoSaveSlotId}_combinedTopology', 'x');
        expect(adapter.hasValidAutoSave(box), isFalse);
        expect(box.containsKey(kAutoSaveSlotId), isFalse);
      });

      test('clears orphan auto-save map keys when game key missing', () {
        final (tileMap, topo) = minimalMap();
        adapter.saveMapData(
          box,
          kAutoSaveSlotId,
          tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
          topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
          combinedTopology: topo,
        );
        expect(box.containsKey('${kAutoSaveSlotId}_tileMapByRegion'), isTrue);
        expect(adapter.hasValidAutoSave(box), isFalse);
        expect(box.containsKey('${kAutoSaveSlotId}_tileMapByRegion'), isFalse);
      });
    });

    test('load supports missing turnTimeMapping within current envelope', () {
      // Simulate a current-version payload where this optional field is absent.
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
        // Note: turnTimeMapping is intentionally missing
      };
      box.put('legacyGame2', {
        'saveFormatVersion': kSaveFormatVersion,
        'game': gameJson,
      });
      final loaded = adapter.load(box, 'legacyGame2');
      expect(loaded, isNotNull);
      expect(loaded!.turnTimeMapping, isNull);
    });

    test(
      'loadStrict throws IncompatibleSaveFormatException for unsupported version',
      () {
        final game = Game(
          id: 'unsupportedVersion',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
          ],
        );
        box.put('badVer', {'saveFormatVersion': 999, 'game': game.toJson()});
        expect(
          () => adapter.loadStrict(box, 'badVer'),
          throwsA(isA<IncompatibleSaveFormatException>()),
        );
      },
    );

    test('load returns null for unsupported saveFormatVersion', () {
      final game = Game(
        id: 'unsupportedVersion',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      box.put('unsupportedVersion', {
        'saveFormatVersion': 999,
        'game': game.toJson(),
      });
      final loaded = adapter.load(box, 'unsupportedVersion');
      expect(loaded, isNull);
    });

    test('load returns null when saveFormatVersion is missing', () {
      final game = Game(
        id: 'missingVersion',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      box.put('missingVersion', {'game': game.toJson()});
      final loaded = adapter.load(box, 'missingVersion');
      expect(loaded, isNull);
    });
  });
}
