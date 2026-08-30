import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/army_ids.dart';
import 'package:colonizethis_world/src/world/army_migration.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';
import 'army_migration_reconcile_cases.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises army reconstruction, home-army backfill, regiment relocation and
/// reconciliation in `lib/src/world/army_migration.dart` (and its
/// `army_migration_relocation.dart` part). SPEC/game/military-armies.md.
const String _mil = 'grenadiers';

Unit _regiment(
  String id, {
  String ownerId = 'p1',
  String locationProvinceId = 'oldWorld|p1',
}) => Unit(
  id: id,
  type: _mil,
  ownerId: ownerId,
  locationProvinceId: locationProvinceId,
);

void main() {
  group('ensureMilitaryArmiesForGame — rebuild path', () {
    test('rebuilds home + field armies from military units', () {
      final game = gameWithArmies(
        oldWorldUnits: [
          _regiment('r1', locationProvinceId: 'oldWorld|cap'),
          _regiment('r2', locationProvinceId: 'oldWorld|front'),
        ],
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|cap',
          ),
        ],
      );
      final next = ensureMilitaryArmiesForGame(game);
      final armies = next.worldState.armies;
      final home = armies.firstWhere((a) => a.id == homeArmyIdFor('p1'));
      expect(home.isHomeArmy, isTrue);
      expect(home.regimentUnitIds, ['r1']);
      expect(home.stationedProvinceId, 'oldWorld|cap');

      final field = armies.firstWhere((a) => !a.isHomeArmy);
      expect(field.regimentUnitIds, ['r2']);
      expect(field.stationedProvinceId, 'oldWorld|front');
      expect(next.worldState.nextArmySeq, greaterThanOrEqualTo(2));
    });

    test('empty armies + no military units yields no field armies', () {
      final game = gameWithArmies();
      final next = ensureMilitaryArmiesForGame(game);
      expect(next.worldState.armies.where((a) => !a.isHomeArmy), isEmpty);
    });
  });

  group('ensureMilitaryArmiesForGame — armies already match', () {
    test('adds a missing home army without rebuilding field armies', () {
      final field = Army(
        id: fieldArmyIdFor('p1', 'oldWorld|front'),
        ownerId: 'p1',
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|front',
        regimentUnitIds: const ['r1'],
      );
      final game = gameWithArmies(
        oldWorldUnits: [_regiment('r1', locationProvinceId: 'oldWorld|front')],
        armies: [field],
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|cap',
          ),
        ],
      );
      final next = ensureMilitaryArmiesForGame(game);
      final home = next.worldState.armies.firstWhere(
        (a) => a.id == homeArmyIdFor('p1'),
      );
      expect(home.isHomeArmy, isTrue);
      expect(home.stationedProvinceId, 'oldWorld|cap');
      // Field army is preserved unchanged.
      expect(next.worldState.armies, contains(field));
    });

    test('returns same game when armies match and home army present', () {
      final home = Army(
        id: homeArmyIdFor('p1'),
        ownerId: 'p1',
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|cap',
        regimentUnitIds: const ['r1'],
        isHomeArmy: true,
      );
      final game = gameWithArmies(
        oldWorldUnits: [_regiment('r1', locationProvinceId: 'oldWorld|cap')],
        armies: [home],
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'oldWorld|cap',
          ),
        ],
      );
      final next = ensureMilitaryArmiesForGame(game);
      expect(next, same(game));
    });

    test('mismatched membership triggers a rebuild', () {
      // Army claims a regiment id that is not a real military unit.
      final stale = Army(
        id: 'army_stale',
        ownerId: 'p1',
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|front',
        regimentUnitIds: const ['ghost'],
      );
      final game = gameWithArmies(
        oldWorldUnits: [_regiment('r1', locationProvinceId: 'oldWorld|front')],
        armies: [stale],
      );
      final next = ensureMilitaryArmiesForGame(game);
      final ids = next.worldState.armies
          .expand((a) => a.regimentUnitIds)
          .toList();
      expect(ids, ['r1']);
      expect(next.worldState.armies.any((a) => a.id == 'army_stale'), isFalse);
    });
  });

  registerArmyMigrationReconcileCases();
}
