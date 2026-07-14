import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart';
import 'package:hive/hive.dart';

/// List-gate / capacity / sanitize coverage split from game_save_adapter_test
/// so each file stays within the 1000 non-comment-line cap
/// (SPEC/program/dart-file-non-comment-line-size.md). Refs #3985.
void main() {
  late Box<dynamic> box;
  late GameSaveAdapter adapter;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_list_meta');
    box = await Hive.openBox<dynamic>('games_list_meta');
  });

  tearDownAll(() async {
    await box.close();
  });

  setUp(() async {
    await box.clear();
    adapter = GameSaveAdapter();
  });

  group('GameSaveAdapter list metadata', () {
    test('listLoadableSaves includes manual and auto-save rows', () {
      final game = Game(
        id: 'manual_a',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
        turnTimeMapping: TurnTimeMapping.gdd01,
      );
      adapter.save(
        box,
        game,
        displayName: 'My Spain',
        lastSavedAt: DateTime.utc(2026, 7, 1, 12),
      );
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
      adapter.saveAutoSave(
        box,
        game.copyWith(id: 'session_live'),
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
        lastSavedAt: DateTime.utc(2026, 7, 2, 12),
      );
      final entries = adapter.listLoadableSaves(box);
      expect(adapter.listGameIds(box), isNot(contains(kAutoSaveSlotId)));
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
      final game = Game(
        id: 'legacy',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      box.put('legacy_v1', {
        'saveFormatVersion': 1,
        'game': game.toJson(),
      });
      box.put('legacy_v2', {
        'saveFormatVersion': 2,
        'game': game.copyWith(id: 'legacy_v2').toJson(),
        'displayName': 'Old',
      });
      expect(adapter.listLoadableSaves(box), isEmpty);
      expect(adapter.load(box, 'legacy_v1'), isNotNull);
      expect(adapter.load(box, 'legacy_v2'), isNotNull);
    });

    test('listLoadableSaves orders manuals newest-first by lastSavedAt', () {
      Game make(String id) => Game(
        id: id,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      adapter.save(
        box,
        make('older'),
        displayName: 'Older',
        lastSavedAt: DateTime.utc(2026, 1, 1),
      );
      adapter.save(
        box,
        make('newer'),
        displayName: 'Newer',
        lastSavedAt: DateTime.utc(2026, 6, 1),
      );
      final manuals = adapter
          .listLoadableSaves(box)
          .where((e) => e.kind == LoadableSaveKind.manual)
          .toList();
      expect(manuals.map((e) => e.storageId).toList(), ['newer', 'older']);
    });

    test('canCreateNewManualSave respects kMaxManualSaves', () {
      Game make(String id) => Game(
        id: id,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      for (var i = 0; i < kMaxManualSaves; i++) {
        adapter.save(box, make('slot_$i'), displayName: 'Slot $i');
      }
      expect(adapter.manualSaveCount(box), kMaxManualSaves);
      expect(adapter.canCreateNewManualSave(box), isFalse);
      adapter.delete(box, 'slot_0');
      expect(adapter.canCreateNewManualSave(box), isTrue);
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
