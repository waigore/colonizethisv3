import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart';

import 'support/game_save_adapter_test_harness.dart';

/// List-gate / capacity / sanitize coverage. Refs #3985 / #4664.
void main() {
  final harness = GameSaveAdapterHiveHarness(
    hivePath: './.dart_tool/test_hive_list_meta',
    boxName: 'games_list_meta',
  );

  setUpAll(harness.open);
  tearDownAll(harness.close);
  setUp(harness.reset);

  Game makeGame(String id, {int turnNumber = 1}) => minimalSaveGame(
    id: id,
    turnNumber: turnNumber,
    players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
  );

  group('GameSaveAdapter list metadata', () {
    test('listLoadableSaves includes manual and auto-save rows', () {
      final game = makeGame(
        'manual_a',
        turnNumber: 7,
      ).copyWith(turnTimeMapping: TurnTimeMapping.gdd01);
      harness.adapter.save(
        harness.box,
        game,
        displayName: 'My Spain',
        lastSavedAt: DateTime.utc(2026, 7, 1, 12),
      );
      final (tileMap, topo) = minimalSaveMap();
      harness.adapter.saveAutoSave(
        harness.box,
        game.copyWith(id: 'session_live'),
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
        lastSavedAt: DateTime.utc(2026, 7, 2, 12),
      );
      final entries = harness.adapter.listLoadableSaves(harness.box);
      expect(
        harness.adapter.listGameIds(harness.box),
        isNot(contains(kAutoSaveSlotId)),
      );
      expect(entries.first.kind, LoadableSaveKind.autoSave);
      expect(entries.first.storageId, kAutoSaveSlotId);
      expect(entries.first.label, kAutoSaveListLabel);
      expect(entries.any((e) => e.storageId == 'manual_a'), isTrue);
      final manual = entries.where((e) => e.storageId == 'manual_a').single;
      expect(manual.label, 'My Spain');
      expect(manual.turnNumber, 7);
      expect(manual.humanNation, 'Spain');
      expect(manual.calendarYear, isNotNull);
      expect(manual.lastSavedAt, DateTime.utc(2026, 7, 1, 12));
    });

    test('listLoadableSaves excludes v1 and v2 envelopes (list gate)', () {
      final game = makeGame('legacy');
      harness.box.put('legacy_v1', {
        'saveFormatVersion': 1,
        'game': game.toJson(),
      });
      harness.box.put('legacy_v2', {
        'saveFormatVersion': 2,
        'game': game.copyWith(id: 'legacy_v2').toJson(),
        'displayName': 'Old',
      });
      expect(harness.adapter.listLoadableSaves(harness.box), isEmpty);
      expect(harness.adapter.load(harness.box, 'legacy_v1'), isNotNull);
      expect(harness.adapter.load(harness.box, 'legacy_v2'), isNotNull);
    });

    test('listLoadableSaves orders manuals newest-first by lastSavedAt', () {
      harness.adapter.save(
        harness.box,
        makeGame('older'),
        displayName: 'Older',
        lastSavedAt: DateTime.utc(2026, 1, 1),
      );
      harness.adapter.save(
        harness.box,
        makeGame('newer'),
        displayName: 'Newer',
        lastSavedAt: DateTime.utc(2026, 6, 1),
      );
      final manuals = harness.adapter
          .listLoadableSaves(harness.box)
          .where((e) => e.kind == LoadableSaveKind.manual)
          .toList();
      expect(manuals.map((e) => e.storageId).toList(), ['newer', 'older']);
    });

    test('canCreateNewManualSave respects kMaxManualSaves', () {
      for (var i = 0; i < kMaxManualSaves; i++) {
        harness.adapter.save(
          harness.box,
          makeGame('slot_$i'),
          displayName: 'Slot $i',
        );
      }
      expect(harness.adapter.manualSaveCount(harness.box), kMaxManualSaves);
      expect(harness.adapter.canCreateNewManualSave(harness.box), isFalse);
      harness.adapter.delete(harness.box, 'slot_0');
      expect(harness.adapter.canCreateNewManualSave(harness.box), isTrue);
    });
  });

  group('sanitizeGameId', () {
    test('trims whitespace and replaces runs with underscore', () {
      expect(sanitizeGameId('  My Save  '), 'My_Save');
      expect(sanitizeGameId('a   b'), 'a_b');
    });

    test('strips map-data suffixes', () {
      expect(sanitizeGameId('slot_tileMapByRegion'), 'slot');
      expect(sanitizeGameId('x_topologyByRegion'), 'x');
      expect(sanitizeGameId('y_combinedTopology'), 'y');
      expect(sanitizeGameId('z_warpLinks'), 'z');
    });

    test('returns null for empty or whitespace-only', () {
      expect(sanitizeGameId(''), isNull);
      expect(sanitizeGameId('   '), isNull);
    });
  });
}
