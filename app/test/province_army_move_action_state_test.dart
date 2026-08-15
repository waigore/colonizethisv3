// Pins MAP20001 Move/Invade action state + cache-only enablement (Refs #4350).

import 'dart:io';

import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_action_state.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_home_army.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'province_army_move_action_state_support.dart';

void main() {
  suppressLogsForTests();

  const human = kArmyMoveActionHumanId;
  const owned = kArmyMoveActionOwnedId;
  const foreign = kArmyMoveActionForeignId;
  const other = kArmyMoveActionOtherId;

  test('Home Army with regiments enables Move via detach', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'home',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: owned,
          regimentUnitIds: ['r1'],
          isHomeArmy: true,
        ),
      ],
    );
    final cache = PerPlayerArmyMovePickerCache();
    final state = computeProvinceArmyMoveActionState(
      game: game,
      humanPlayerId: human,
      provinceId: owned,
      topology: armyMoveActionTopology(),
      armyMovePickerCache: cache,
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
    );
    expect(state.showMove, isTrue);
    expect(state.moveEnabled, isTrue);
    expect(state.eligibleMoveArmyIds, isEmpty);
    expect(state.showInvade, isFalse);
    expect(
      usesHomeArmyDetachFlow(
        enabled: state.moveEnabled,
        eligibleArmyIds: state.eligibleMoveArmyIds,
      ),
      isTrue,
    );
  });

  test('empty Home Army still shows disabled Move with home reason', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'home',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: owned,
          regimentUnitIds: [],
          isHomeArmy: true,
        ),
      ],
    );
    final cache = PerPlayerArmyMovePickerCache();
    final state = computeProvinceArmyMoveActionState(
      game: game,
      humanPlayerId: human,
      provinceId: owned,
      topology: armyMoveActionTopology(),
      armyMovePickerCache: cache,
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
    );
    expect(state.showMove, isTrue);
    expect(state.moveEnabled, isFalse);
    expect(
      state.moveDisabledReason,
      ProvinceArmyMoveDisabledReason.homeArmyCannotLeave,
    );
  });

  test('Invade visible but disabled when not in cache reachability', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'field',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: owned,
          regimentUnitIds: ['r1'],
        ),
      ],
    );
    final cache = PerPlayerArmyMovePickerCache();
    final state = computeProvinceArmyMoveActionState(
      game: game,
      humanPlayerId: human,
      provinceId: foreign,
      topology: armyMoveActionTopology(),
      armyMovePickerCache: cache,
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
    );
    expect(state.showInvade, isTrue);
    expect(state.invadeEnabled, isFalse);
    expect(
      state.invadeDisabledReason,
      ProvinceArmyMoveDisabledReason.cannotReach,
    );
  });

  test('action state reads cache without calling armyMovePickerDestinations', () {
    const path =
        'lib/features/game/flame/map_state/province_army_move_action_state.dart';
    final source = File('${Directory.current.path}/$path').readAsStringSync();
    // Doc comments may mention the picker name; code must not call it.
    expect(source.contains('armyMovePickerDestinations('), isFalse);
    expect(source.contains('PerPlayerArmyMovePickerCache'), isTrue);
  });

  test('invadeConceivableCheap requires adjacency to stationed field army', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'field',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: owned,
          regimentUnitIds: ['r1'],
        ),
      ],
    );
    expect(
      invadeConceivableCheap(
        game: game,
        topology: armyMoveActionTopology(),
        humanPlayerId: human,
        targetFullProvinceId: foreign,
      ),
      isTrue,
    );
    expect(
      invadeConceivableCheap(
        game: game,
        topology: armyMoveActionTopology(),
        humanPlayerId: human,
        targetFullProvinceId: other,
      ),
      isFalse,
    );
  });

  test('sea zone and obfuscated military hide Move/Invade', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'field',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: owned,
          regimentUnitIds: ['r1'],
        ),
      ],
    );
    final cache = PerPlayerArmyMovePickerCache();
    expect(
      computeProvinceArmyMoveActionState(
        game: game,
        humanPlayerId: human,
        provinceId: owned,
        topology: armyMoveActionTopology(),
        armyMovePickerCache: cache,
        showsFullMilitaryIntel: false,
        isSeaZoneContext: false,
      ).showMove,
      isFalse,
    );
    expect(
      computeProvinceArmyMoveActionState(
        game: game,
        humanPlayerId: human,
        provinceId: foreign,
        topology: armyMoveActionTopology(),
        armyMovePickerCache: cache,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: true,
      ).showInvade,
      isFalse,
    );
  });

  test('Home-only adjacent foreign province enables Invade via detach', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'home',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: owned,
          regimentUnitIds: ['r1'],
          isHomeArmy: true,
        ),
      ],
    );
    final cache = PerPlayerArmyMovePickerCache();
    final state = computeProvinceArmyMoveActionState(
      game: game,
      humanPlayerId: human,
      provinceId: foreign,
      topology: armyMoveActionTopology(),
      armyMovePickerCache: cache,
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
    );
    expect(state.showInvade, isTrue);
    expect(state.invadeEnabled, isTrue);
    expect(state.eligibleInvadeArmyIds, isEmpty);
    expect(
      usesHomeArmyDetachFlow(
        enabled: state.invadeEnabled,
        eligibleArmyIds: state.eligibleInvadeArmyIds,
      ),
      isTrue,
    );
  });

  test('mixed unreachable field army still enables Invade via Home Army', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'home',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: owned,
          regimentUnitIds: ['r1'],
          isHomeArmy: true,
        ),
        const Army(
          id: 'field',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: other,
          regimentUnitIds: ['r2'],
        ),
      ],
    );
    final cache = PerPlayerArmyMovePickerCache();
    final state = computeProvinceArmyMoveActionState(
      game: game,
      humanPlayerId: human,
      provinceId: foreign,
      topology: armyMoveActionTopology(),
      armyMovePickerCache: cache,
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
    );
    expect(state.showInvade, isTrue);
    expect(state.invadeEnabled, isTrue);
    expect(state.eligibleInvadeArmyIds, isEmpty);
  });

  test('Home-Army Invade clause does not call armyMovePickerDestinations', () {
    const path =
        'lib/features/game/flame/map_state/province_army_move_home_army.dart';
    final source = File('${Directory.current.path}/$path').readAsStringSync();
    expect(source.contains('armyMovePickerDestinations('), isFalse);
    expect(source.contains('PerPlayerArmyMovePickerCache'), isFalse);
  });

  test('non-adjacent foreign province stays hidden with only Home Army', () {
    final game = armyMoveActionGameWithArmies(
      armies: [
        const Army(
          id: 'home',
          ownerId: human,
          regionId: 'oldWorld',
          stationedProvinceId: owned,
          regimentUnitIds: ['r1'],
          isHomeArmy: true,
        ),
      ],
    );
    expect(
      invadeConceivableCheap(
        game: game,
        topology: armyMoveActionTopology(),
        humanPlayerId: human,
        targetFullProvinceId: other,
      ),
      isFalse,
    );
  });

  test(
    'capital Move detach when stationed field armies have no destinations',
    () {
      final game = armyMoveActionGameWithArmies(
        armies: [
          const Army(
            id: 'home',
            ownerId: human,
            regionId: 'oldWorld',
            stationedProvinceId: owned,
            regimentUnitIds: ['r1'],
            isHomeArmy: true,
          ),
          const Army(
            id: 'field',
            ownerId: human,
            regionId: 'oldWorld',
            stationedProvinceId: owned,
            regimentUnitIds: ['r2'],
          ),
        ],
      );
      final cache = PerPlayerArmyMovePickerCache();
      final state = computeProvinceArmyMoveActionState(
        game: game,
        humanPlayerId: human,
        provinceId: owned,
        topology: armyMoveActionTopology(),
        armyMovePickerCache: cache,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: false,
      );
      expect(state.showMove, isTrue);
      expect(state.moveEnabled, isTrue);
      expect(state.eligibleMoveArmyIds, isEmpty);
    },
  );
}
