import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/army_ids.dart';
import 'package:colonizethis_world/src/world/army_migration.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';

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

void registerArmyMigrationReconcileCases() {
  group('updateArmyStation', () {
    test('retargets the army and relocates regiments same-region', () {
      final game = ensureMilitaryArmiesForGame(
        gameWithArmies(
          oldWorldUnits: [
            _regiment('r1', locationProvinceId: 'oldWorld|front'),
          ],
        ),
      );
      final fieldId = game.worldState.armies
          .firstWhere((a) => !a.isHomeArmy)
          .id;
      final next = updateArmyStation(game.worldState, fieldId, 'oldWorld|rear');
      final army = next.armies.firstWhere((a) => a.id == fieldId);
      expect(army.stationedProvinceId, 'oldWorld|rear');
      expect(army.regionId, 'oldWorld');
      expect(
        next.oldWorld.units.firstWhere((u) => u.id == 'r1').locationProvinceId,
        'oldWorld|rear',
      );
    });

    test('relocates regiments across regions', () {
      final game = ensureMilitaryArmiesForGame(
        gameWithArmies(
          oldWorldUnits: [
            _regiment('r1', locationProvinceId: 'oldWorld|front'),
          ],
        ),
      );
      final fieldId = game.worldState.armies
          .firstWhere((a) => !a.isHomeArmy)
          .id;
      final next = updateArmyStation(
        game.worldState,
        fieldId,
        'newWorld|beach',
      );
      final army = next.armies.firstWhere((a) => a.id == fieldId);
      expect(army.regionId, 'newWorld');
      expect(next.oldWorld.units.any((u) => u.id == 'r1'), isFalse);
      expect(
        next.newWorld.units.firstWhere((u) => u.id == 'r1').locationProvinceId,
        'newWorld|beach',
      );
    });

    test('returns world unchanged when army id is unknown', () {
      final world = gameWithArmies().worldState;
      final next = updateArmyStation(world, 'missing', 'oldWorld|p1');
      expect(next, same(world));
    });

    test('relocates multiple regiments across regions in one call', () {
      // Two regiments in the same field army crossing regions exercises the
      // `_relocateArmyRegiments` accumulation loop, where each pass threads the
      // shared `RegionUnitLists` (ow, nw) pair into the next (Refs #3403
      // Phase 3 — shared region-unit-list type).
      final game = ensureMilitaryArmiesForGame(
        gameWithArmies(
          oldWorldUnits: [
            _regiment('r1', locationProvinceId: 'oldWorld|front'),
            _regiment('r2', locationProvinceId: 'oldWorld|front'),
          ],
        ),
      );
      final fieldId = game.worldState.armies
          .firstWhere((a) => !a.isHomeArmy)
          .id;
      final next = updateArmyStation(
        game.worldState,
        fieldId,
        'newWorld|beach',
      );
      final army = next.armies.firstWhere((a) => a.id == fieldId);
      expect(army.regionId, 'newWorld');
      // Both regiments moved out of the old world and into the new world.
      expect(next.oldWorld.units.any((u) => u.id == 'r1'), isFalse);
      expect(next.oldWorld.units.any((u) => u.id == 'r2'), isFalse);
      final movedIds = next.newWorld.units
          .where((u) => u.locationProvinceId == 'newWorld|beach')
          .map((u) => u.id)
          .toSet();
      expect(movedIds, containsAll(<String>['r1', 'r2']));
    });
  });

  group('reconcileArmiesAfterUnitsChanged', () {
    test('drops dead regiment ids and removes empty non-home armies', () {
      final field = Army(
        id: 'army_field_p1_oldWorld_front',
        ownerId: 'p1',
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|front',
        regimentUnitIds: const ['dead'],
      );
      final game = gameWithArmies(armies: [field]);
      final next = reconcileArmiesAfterUnitsChanged(game.worldState, game);
      expect(next.armies, isEmpty);
    });

    test('assigns an orphan regiment to a new field army', () {
      final game = gameWithArmies(
        oldWorldUnits: [_regiment('r1', locationProvinceId: 'oldWorld|front')],
      );
      final next = reconcileArmiesAfterUnitsChanged(game.worldState, game);
      final army = next.armies.single;
      expect(army.regimentUnitIds, ['r1']);
      expect(army.isHomeArmy, isFalse);
      expect(army.stationedProvinceId, 'oldWorld|front');
    });

    test('keeps an empty home army', () {
      final home = Army(
        id: homeArmyIdFor('p1'),
        ownerId: 'p1',
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|cap',
        regimentUnitIds: const [],
        isHomeArmy: true,
      );
      final game = gameWithArmies(armies: [home]);
      final next = reconcileArmiesAfterUnitsChanged(game.worldState, game);
      expect(next.armies.single.id, homeArmyIdFor('p1'));
    });
  });
}
