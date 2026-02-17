import 'dart:io';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() {
  late Box<dynamic> box;
  late GameSaveAdapter adapter;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_save_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    box = await Hive.openBox<dynamic>('games');
    adapter = GameSaveAdapter();
  });

  tearDown(() async {
    await box.close();
  });

  group('GameSaveAdapter', () {
    test('save then load returns same game', () {
      final game = Game(
        id: 'game1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 5),
          oldWorld: const RegionData(
            provinces: [Province(id: 'p1', regionId: 'oldWorld', ownerId: 'player1')],
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

    test('listGameIds returns saved ids', () {
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
      expect(adapter.listGameIds(box), containsAll(['g1', 'g2']));
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
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
          portsByProvinceSeaboard: {'p1|sea1': 'oldWorld|p1|0|0'},
        ),
        players: [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            capitalProvinceId: 'p1',
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'p1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      adapter.save(box, game);
      final loaded = adapter.load(box, 'withCapital');
      expect(loaded, isNotNull);
      expect(loaded!.worldState.tileState.improvementLevel('oldWorld|p1|0|0'), 2);
      expect(loaded.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 1);
      expect(loaded.worldState.portsByProvinceSeaboard['p1|sea1'], 'oldWorld|p1|0|0');
      expect(loaded.players.single.capitalProvinceId, 'p1');
      expect(loaded.players.single.capitalTile?.regionId, 'oldWorld');
      expect(loaded.players.single.capitalTile?.x, 0);
      expect(loaded.players.single.capitalTile?.y, 0);
    });

    test('save/load round-trip includes Phase 3 combat state', () {
      final game = Game(
        id: 'phase3',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'p1',
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
                provinceId: 'p1',
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
        minorNations: [
          MinorNation(id: 'min1', effectiveMilitaryLevel: 4),
        ],
        tribes: [
          Tribe(id: 'tribe1', effectiveMilitaryLevel: 4),
        ],
      );
      adapter.save(box, game);
      final loaded = adapter.load(box, 'phase3');
      expect(loaded, isNotNull);
      expect(loaded!.worldState.oldWorld.provinces.single.fortLevel, 2);
      expect(loaded.worldState.oldWorld.provinces.single.terrain, 'forest');
      expect(loaded.worldState.oldWorld.units.single.medals, 3);
      expect(loaded.players.single.militaryLevel, 4);
      expect(loaded.minorNations.single.effectiveMilitaryLevel, 4);
      expect(loaded.tribes.single.effectiveMilitaryLevel, 4);
    });
  });
}
