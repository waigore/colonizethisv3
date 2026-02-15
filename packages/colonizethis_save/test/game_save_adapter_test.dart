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
  });
}
