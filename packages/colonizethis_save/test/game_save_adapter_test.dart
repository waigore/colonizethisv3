import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart';

import 'support/game_save_adapter_test_harness.dart';

void main() {
  final harness = GameSaveAdapterHiveHarness(
    hivePath: './.dart_tool/test_hive_save_core',
    boxName: 'games_core',
  );

  setUpAll(harness.open);
  tearDownAll(harness.close);
  setUp(harness.reset);

  group('GameSaveAdapter core', () {
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
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'game1');
      expect(loaded, isNotNull);
      expect(loaded!.id, game.id);
      expect(loaded.worldState.turnState.turnNumber, 5);
      expect(loaded.worldState.oldWorld.provinces.length, 1);
      expect(loaded.players.length, 1);
      expect(loaded.players.first.displayName, 'Spain');
    });

    test('load returns null for missing id', () {
      expect(harness.adapter.load(harness.box, 'missing'), isNull);
    });

    test('load reconciles generals to persisted general cap (spawn-only)', () {
      final game = Game(
        id: 'capgame',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Spain', isHuman: true, generalCap: 3),
        ],
        generals: const [General(id: 'gp1_gen_0', ownerId: 'gp1', medals: 2)],
      );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'capgame');
      expect(loaded, isNotNull);
      final generals = loaded!.generals
          .where((g) => g.ownerId == 'gp1')
          .toList();
      expect(generals.length, 3);
      expect(generals.where((g) => g.id == 'gp1_gen_0').single.medals, 2);
      expect(generals.where((g) => g.medals == 0).length, 2);
      expect(loaded.players.single.generalCap, 3);
    });

    test('legacy save without generalCap derives cap from tech on load', () {
      final game = Game(
        id: 'legacycap',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'France',
            isHuman: false,
            techUnlocked: {kTechIdNationalism: true},
          ),
        ],
      );
      expect(
        (game.toJson()['players'] as List<Object?>).first,
        isNot(contains('generalCap')),
      );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'legacycap');
      expect(loaded, isNotNull);
      expect(loaded!.players.single.generalCap, 4);
      expect(loaded.generals.where((g) => g.ownerId == 'gp1').length, 4);
    });

    test('delete removes game', () {
      final game = minimalSaveGame(id: 'toDelete');
      harness.adapter.save(harness.box, game);
      expect(harness.adapter.load(harness.box, 'toDelete'), isNotNull);
      harness.adapter.delete(harness.box, 'toDelete');
      expect(harness.adapter.load(harness.box, 'toDelete'), isNull);
    });

    test(
      'loadStrict throws IncompatibleSaveFormatException for unsupported version',
      () {
        final game = minimalSaveGame(
          id: 'unsupportedVersion',
          turnNumber: 1,
          players: const [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
          ],
        );
        harness.box.put('badVer', {
          'saveFormatVersion': 999,
          'game': game.toJson(),
        });
        expect(
          () => harness.adapter.loadStrict(harness.box, 'badVer'),
          throwsA(isA<IncompatibleSaveFormatException>()),
        );
      },
    );

    test('load returns null for unsupported saveFormatVersion', () {
      final game = minimalSaveGame(
        id: 'unsupportedVersion',
        turnNumber: 1,
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      harness.box.put('unsupportedVersion', {
        'saveFormatVersion': 999,
        'game': game.toJson(),
      });
      expect(harness.adapter.load(harness.box, 'unsupportedVersion'), isNull);
    });

    test('load returns null when saveFormatVersion is missing', () {
      final game = minimalSaveGame(
        id: 'missingVersion',
        turnNumber: 1,
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      harness.box.put('missingVersion', {'game': game.toJson()});
      expect(harness.adapter.load(harness.box, 'missingVersion'), isNull);
    });

    test(
      'draft envelope round-trip preserves orders desired and displayName',
      () {
        final game = minimalSaveGame(
          id: 'draft_rt',
          turnNumber: 4,
          players: const [
            Player(id: 'pl1', displayName: 'Spain', isHuman: true),
          ],
        );
        const drafts = Orders(
          buildUnitOrdersByPlayerId: {
            'pl1': [
              BuildUnitOrder(
                unitType: 'peasant',
                isMilitary: false,
                spawnProvinceId: 'oldWorld|cap',
              ),
            ],
          },
        );
        const desired = {'recipe_grain': 3};
        harness.adapter.save(
          harness.box,
          game,
          draftOrders: drafts,
          productionDesiredOutputByRecipe: desired,
          displayName: 'Spain - Leader - 4',
        );
        final session = harness.adapter.loadSession(harness.box, 'draft_rt');
        expect(session, isNotNull);
        expect(session!.displayName, 'Spain - Leader - 4');
        expect(session.productionDesiredOutputByRecipe, desired);
        expect(
          session.draftOrders.buildUnitOrdersByPlayerId['pl1']!.single.unitType,
          'peasant',
        );
      },
    );

    test('legacy v1 envelope loads empty draft defaults', () {
      final game = minimalSaveGame(
        id: 'legacy_v1',
        turnNumber: 2,
        players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      harness.box.put('legacy_v1', {
        'saveFormatVersion': 1,
        'game': game.toJson(),
      });
      final session = harness.adapter.loadSession(harness.box, 'legacy_v1');
      expect(session, isNotNull);
      expect(session!.draftOrders, const Orders());
      expect(session.productionDesiredOutputByRecipe, isEmpty);
      expect(session.displayName, isNull);
    });
  });
}
