import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart';

import 'support/game_save_adapter_test_harness.dart';

void main() {
  final harness = GameSaveAdapterHiveHarness(
    hivePath: './.dart_tool/test_hive_save_autosave',
    boxName: 'games_autosave',
  );

  setUpAll(harness.open);
  tearDownAll(harness.close);
  setUp(harness.reset);

  group('Auto-save slot (kAutoSaveSlotId)', () {
    Game minimalGame(String logicalId) => minimalSaveGame(
      id: logicalId,
      turnNumber: 3,
      players: const [
        Player(id: 'player1', displayName: 'Spain', isHuman: true),
      ],
    );

    test('saveAutoSave then load round-trip preserves logical game id', () {
      final game = minimalGame('session_abc');
      final (tileMap, topo) = minimalSaveMap();
      harness.adapter.saveAutoSave(
        harness.box,
        game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      expect(harness.adapter.hasValidAutoSave(harness.box), isTrue);
      final loaded = harness.adapter.load(harness.box, kAutoSaveSlotId);
      expect(loaded, isNotNull);
      expect(loaded!.id, 'session_abc');
      expect(loaded.worldState.turnState.turnNumber, 3);
      final md = harness.adapter.loadMapData(harness.box, kAutoSaveSlotId);
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
        final (tileMap, topo) = minimalSaveMap();
        final slotGameJson = Map<String, dynamic>.from(game.toJson());
        slotGameJson['turnTimeMapping'] = <dynamic, dynamic>{
          'startYear': 1600,
          'cutoffYear': 1750,
          'yearsPerTurnBeforeCutoff': 3,
          'yearsPerTurnAfterCutoff': 2,
        };
        harness.box.put(kAutoSaveSlotId, {
          'saveFormatVersion': kSaveFormatVersion,
          'game': slotGameJson,
        });
        harness.adapter.saveMapData(
          harness.box,
          kAutoSaveSlotId,
          tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
          topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
          combinedTopology: topo,
        );
        expect(harness.adapter.hasValidAutoSave(harness.box), isTrue);
        final loaded = harness.adapter.load(harness.box, kAutoSaveSlotId);
        expect(loaded, isNotNull);
        expect(loaded!.turnTimeMapping!.startYear, 1600);
      },
    );

    test('listGameIds excludes auto-save stem even when slot is populated', () {
      final game = minimalGame('only_logical');
      final (tileMap, topo) = minimalSaveMap();
      harness.adapter.saveAutoSave(
        harness.box,
        game,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      expect(harness.adapter.listGameIds(harness.box), isEmpty);
    });

    test('listGameIds excludes stem when user game also exists', () {
      final userGame = minimalGame('user_slot');
      harness.adapter.save(harness.box, userGame);
      final (tileMap, topo) = minimalSaveMap();
      harness.adapter.saveMapData(
        harness.box,
        'user_slot',
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      harness.adapter.saveAutoSave(
        harness.box,
        userGame,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      expect(harness.adapter.listGameIds(harness.box), ['user_slot']);
    });

    test('hasValidAutoSave is false when slot empty', () {
      expect(harness.adapter.hasValidAutoSave(harness.box), isFalse);
    });

    test('hasValidAutoSave clears slot when game JSON is corrupt', () {
      harness.box.put(kAutoSaveSlotId, 'not-json');
      expect(harness.adapter.hasValidAutoSave(harness.box), isFalse);
      expect(harness.box.containsKey(kAutoSaveSlotId), isFalse);
    });

    test('hasValidAutoSave clears slot when map data missing', () {
      final game = minimalGame('g');
      harness.box.put(kAutoSaveSlotId, {
        'saveFormatVersion': kSaveFormatVersion,
        'game': game.toJson(),
      });
      expect(harness.adapter.hasValidAutoSave(harness.box), isFalse);
      expect(harness.box.containsKey(kAutoSaveSlotId), isFalse);
    });

    test('hasValidAutoSave clears slot when map data invalid', () {
      final game = minimalGame('g');
      harness.box.put(kAutoSaveSlotId, {
        'saveFormatVersion': kSaveFormatVersion,
        'game': game.toJson(),
      });
      harness.box.put('${kAutoSaveSlotId}_tileMapByRegion', {'bad': 'data'});
      harness.box.put('${kAutoSaveSlotId}_topologyByRegion', {'bad': 'data'});
      harness.box.put('${kAutoSaveSlotId}_combinedTopology', 'x');
      expect(harness.adapter.hasValidAutoSave(harness.box), isFalse);
      expect(harness.box.containsKey(kAutoSaveSlotId), isFalse);
    });

    test('clears orphan auto-save map keys when game key missing', () {
      final (tileMap, topo) = minimalSaveMap();
      harness.adapter.saveMapData(
        harness.box,
        kAutoSaveSlotId,
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      expect(
        harness.box.containsKey('${kAutoSaveSlotId}_tileMapByRegion'),
        isTrue,
      );
      expect(harness.adapter.hasValidAutoSave(harness.box), isFalse);
      expect(
        harness.box.containsKey('${kAutoSaveSlotId}_tileMapByRegion'),
        isFalse,
      );
    });
  });
}
