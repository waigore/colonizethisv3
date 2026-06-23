// Focused tests for the shared lightweight panel fixtures (Refs #3656).

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
}
