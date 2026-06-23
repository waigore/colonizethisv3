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
  });

  group('buildCivilianPanelTestGame', () {
    test('human owns idle civilians in both regions for panel coverage', () {
      final game = buildCivilianPanelTestGame();
      final human = game.players.first.id;
      final idleOld = game.worldState.oldWorld.units.where(
        (u) =>
            u.ownerId == human &&
            u.tileKey != null &&
            u.currentWork == null,
      );
      final idleNew = game.worldState.newWorld.units.where(
        (u) =>
            u.ownerId == human &&
            u.tileKey != null &&
            u.currentWork == null,
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
      // Old-world army has >=2 regiments so the Split action renders.
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

    test('a non-owning player id yields no armies or regiments (empty state)',
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
    });
  });

  group('buildNavalPanelTestGame', () {
    test('human owns a home fleet and a non-home fleet, both with ships', () {
      final game = buildNavalPanelTestGame();
      final human = game.players.first.id;
      final ownedWithShips = game.worldState.fleets
          .where((f) => f.ownerId == human && f.shipTypeIds.isNotEmpty)
          .toList();
      expect(ownedWithShips, hasLength(2));

      final homeId = homeFleetIdFor(human);
      final homeFleet = ownedWithShips.firstWhere((f) => f.id == homeId);
      expect(homeFleet.inPortAtProvinceId, isNotNull);
      expect(homeFleet.shipTypeIds, hasLength(2));

      final nonHome = ownedWithShips.where((f) => f.id != homeId);
      expect(nonHome, isNotEmpty);
      expect(nonHome.first.seaZoneId, isNotNull);
    });

    test('player has a capital tile and provinces exist in both regions', () {
      final game = buildNavalPanelTestGame();
      expect(game.players.first.capitalTile, isNotNull);
      expect(game.worldState.oldWorld.provinces, isNotEmpty);
      expect(game.worldState.newWorld.provinces, isNotEmpty);
    });

    test('exposes port/sea-zone tile data for locate resolution', () {
      final game = buildNavalPanelTestGame();
      final ports = game.worldState.portsByProvinceSeaboard;
      expect(ports, isNotEmpty);
      // A `region|province|seazone` key (>= 2 segments) so the sea-zone locate
      // assertions can resolve a port tile key.
      expect(
        ports.keys.any((k) => k.split('|').length >= 2),
        isTrue,
      );
      expect(game.worldState.tileKeysByRegionAndProvince, isNotEmpty);
    });

    test('a non-owning player id yields no fleets (empty state)', () {
      final game = buildNavalPanelTestGame();
      expect(
        game.worldState.fleets.where((f) => f.ownerId == 'no-such-player'),
        isEmpty,
      );
    });
  });
}
