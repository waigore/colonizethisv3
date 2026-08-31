// Focused tests for the shared lightweight panel fixtures (Refs #3656).
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'panel_test_fixtures.dart';
void main() {
  group('buildPanelTestGame', () {
    test('defaults to a single human player and empty regions', () {
      final game = buildPanelTestGame();
      expect(game.players, hasLength(1));
      expect(game.players.first.id, kPanelTestHumanPlayerId);
      expect(game.players.first.isHuman, isTrue);
      expect(game.worldState.oldWorld.units, isEmpty);
      expect(game.worldState.newWorld.units, isEmpty);
      expect(game.worldState.fleets, isEmpty);
    });
    test('threads provided provinces and units into each region', () {
      final game = buildPanelTestGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', displayName: 'A'),
        ],
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: kUnitTypeBuilder,
            ownerId: kPanelTestHumanPlayerId,
            locationProvinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
          ),
        ],
      );
      expect(game.worldState.oldWorld.provinces, hasLength(1));
      expect(game.worldState.oldWorld.units.single.id, 'u1');
    });
    test('threads nextArmySeq, visibility, and empty diplomacyRelations', () {
      const tile = 'oldWorld|p1|0|0';
      final game = buildPanelTestGame(
        nextArmySeq: 7,
        diplomacyRelations: const [],
        playerVisibilityByTile: {
          kPanelTestHumanPlayerId: {tile: 'fullyVisible'},
        },
      );
      expect(game.worldState.nextArmySeq, 7);
      expect(
        game.worldState.playerVisibilityByTile[kPanelTestHumanPlayerId]![tile],
        'fullyVisible',
      );
      expect(game.diplomacyRelations, isEmpty);
    });
  });
  group('buildCivilianPanelTestGame', () {
    test('human owns idle civilians in both regions for panel coverage', () {
      final game = buildCivilianPanelTestGame();
      final human = game.players.first.id;
      final idleOld = game.worldState.oldWorld.units.where(
        (u) => u.ownerId == human && u.tileKey != null && u.currentWork == null,
      );
      final idleNew = game.worldState.newWorld.units.where(
        (u) => u.ownerId == human && u.tileKey != null && u.currentWork == null,
      );
      expect(idleOld, isNotEmpty);
      expect(idleNew, isNotEmpty);
    });
    test('includes one in-progress (working) civilian', () {
      final game = buildCivilianPanelTestGame();
      final working = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ].where((u) => u.currentWork != null);
      expect(working, hasLength(1));
      expect(working.single.status, UnitStatus.working);
    });
    test('a non-owning player id yields no civilian units (empty state)', () {
      final game = buildCivilianPanelTestGame();
      final owned = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ].where((u) => u.ownerId == 'no-such-player');
      expect(owned, isEmpty);
    });
  });
  group('buildMilitaryPanelTestGame', () {
    test('human owns military regiments and armies in both regions', () {
      final game = buildMilitaryPanelTestGame();
      final human = game.players.first.id;
      final oldRegiments = game.worldState.oldWorld.units.where(
        (u) => u.ownerId == human && u.type == kPanelTestRegimentType,
      );
      final newRegiments = game.worldState.newWorld.units.where(
        (u) => u.ownerId == human && u.type == kPanelTestRegimentType,
      );
      expect(oldRegiments, isNotEmpty);
      expect(newRegiments, isNotEmpty);
      final armies = game.worldState.armies.where((a) => a.ownerId == human);
      expect(armies.map((a) => a.regionId).toSet(), {'oldWorld', 'newWorld'});
      expect(
        armies.firstWhere((a) => a.regionId == 'oldWorld').regimentUnitIds,
        hasLength(2),
      );
    });
    test('stationed provinces carry display names and town tile keys', () {
      final game = buildMilitaryPanelTestGame();
      final provinces = [
        ...game.worldState.oldWorld.provinces,
        ...game.worldState.newWorld.provinces,
      ];
      for (final province in provinces) {
        expect(province.displayName, isNotNull);
        expect(province.townTileKey, isNotNull);
      }
    });
    test(
      'a non-owning player id yields no armies or regiments (empty state)',
      () {
        final game = buildMilitaryPanelTestGame();
        expect(
          game.worldState.armies.where((a) => a.ownerId == 'no-such-player'),
          isEmpty,
        );
        final owned = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ].where((u) => u.ownerId == 'no-such-player');
        expect(owned, isEmpty);
      },
    );
  });
  group('empty-human panel fixtures', () {
    test('technology / side-menu / game-screen share solo human + empty regions', () {
      final tech = buildTechnologyPanelTestGame();
      expect(tech.players, hasLength(1));
      expect(tech.players.first.id, kPanelTestHumanPlayerId);
      expect(tech.players.first.isHuman, isTrue);
      expect(tech.players.first.techUnlocked ?? const <String, bool>{}, isEmpty);
      expect(tech.players.first.researchSlots, isNull);
      expect(tech.worldState.oldWorld.units, isEmpty);
      final side = buildSideMenuTestGame();
      expect(side.players.first.id, kPanelTestHumanPlayerId);
      expect(side.infiniteMode, isFalse);
      expect(side.worldState.newWorld.units, isEmpty);
      final screen = buildGameScreenSpecsTestGame();
      expect(screen.players.first.isHuman, isTrue);
      expect(screen.victory, isNull);
      expect(screen.worldState.oldWorld.units, isEmpty);
    });
  });}
