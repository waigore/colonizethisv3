// Pins MAP20001 Military Combine visibility/enablement (Refs #4610).

import 'package:colonizethis_app/features/game/flame/map_state/province_army_combine_action_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'province_army_move_action_state_support.dart';

void main() {
  suppressLogsForTests();

  const human = kArmyMoveActionHumanId;
  const owned = kArmyMoveActionOwnedId;

  Army field(String id) => Army(
    id: id,
    ownerId: human,
    regionId: 'oldWorld',
    stationedProvinceId: owned,
    regimentUnitIds: const ['r1'],
    isHomeArmy: false,
  );

  test('two field armies show enabled Combine', () {
    final game = armyMoveActionGameWithArmies(
      armies: [field('a2'), field('a1')],
    );
    final state = computeProvinceArmyCombineActionState(
      game: game,
      humanPlayerId: human,
      provinceId: owned,
      draftOrders: const Orders(),
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
      canMutateViaUi: true,
    );
    expect(state.show, isTrue);
    expect(state.enabled, isTrue);
    expect(state.armyIds, ['a1', 'a2']);
  });

  test('one army hides Combine', () {
    final game = armyMoveActionGameWithArmies(armies: [field('a1')]);
    final state = computeProvinceArmyCombineActionState(
      game: game,
      humanPlayerId: human,
      provinceId: owned,
      draftOrders: const Orders(),
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
      canMutateViaUi: true,
    );
    expect(state.show, isFalse);
  });

  test('pending ArmyMoveOrder disables Combine', () {
    final game = armyMoveActionGameWithArmies(
      armies: [field('a1'), field('a2')],
    );
    final state = computeProvinceArmyCombineActionState(
      game: game,
      humanPlayerId: human,
      provinceId: owned,
      draftOrders: Orders(
        armyMoveOrdersByPlayerId: {
          human: [
            const ArmyMoveOrder(
              armyId: 'a1',
              destinationProvinceId: kArmyMoveActionOtherId,
            ),
          ],
        },
      ),
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
      canMutateViaUi: true,
    );
    expect(state.show, isTrue);
    expect(state.enabled, isFalse);
    expect(state.hasPendingMarch, isTrue);
  });

  test('Home Army is combine survivor', () {
    final armies = [
      field('z9'),
      const Army(
        id: 'home',
        ownerId: human,
        regionId: 'oldWorld',
        stationedProvinceId: owned,
        regimentUnitIds: ['h1'],
        isHomeArmy: true,
      ),
    ];
    expect(overlayCombineSurvivor(armies).isHomeArmy, isTrue);
  });

  test('sea zone or observe hides Combine', () {
    final game = armyMoveActionGameWithArmies(
      armies: [field('a1'), field('a2')],
    );
    expect(
      computeProvinceArmyCombineActionState(
        game: game,
        humanPlayerId: human,
        provinceId: owned,
        draftOrders: const Orders(),
        showsFullMilitaryIntel: true,
        isSeaZoneContext: true,
        canMutateViaUi: true,
      ).show,
      isFalse,
    );
    expect(
      computeProvinceArmyCombineActionState(
        game: game,
        humanPlayerId: human,
        provinceId: owned,
        draftOrders: const Orders(),
        showsFullMilitaryIntel: true,
        isSeaZoneContext: false,
        canMutateViaUi: false,
      ).show,
      isFalse,
    );
  });
}
