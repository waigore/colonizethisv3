// Pins MAP20001 Move/Invade action state + cache-only enablement (Refs #4350).

import 'dart:io';

import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_action_state.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_home_army.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  const human = 'gp1';
  const rival = 'gp2';
  const owned = 'oldWorld|p_owned';
  const foreign = 'oldWorld|p_foreign';
  const other = 'oldWorld|p_other';

  MapTopology topology() => const MapTopology(
    nodes: [
      TopologyNode(
        id: owned,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: foreign,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: other,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: owned, id2: foreign),
      TopologyEdge(id1: foreign, id2: other),
    ],
  );

  Game gameWithArmies({
    required List<Army> armies,
    String foreignOwner = rival,
  }) {
    return Game(
      id: 'g_army_move_action',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            const Province(
              id: owned,
              regionId: 'oldWorld',
              ownerId: human,
              displayName: 'Owned',
            ),
            Province(
              id: foreign,
              regionId: 'oldWorld',
              ownerId: foreignOwner,
              displayName: 'Foreign',
            ),
            const Province(
              id: other,
              regionId: 'oldWorld',
              ownerId: human,
              displayName: 'Other',
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: armies,
      ),
      players: const [
        Player(id: human, displayName: 'Human', isHuman: true),
        Player(id: rival, displayName: 'Rival', isHuman: false),
      ],
    );
  }

  test('Home Army with regiments enables Move via detach', () {
    final game = gameWithArmies(
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
      topology: topology(),
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
    final game = gameWithArmies(
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
      topology: topology(),
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
    final game = gameWithArmies(
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
      topology: topology(),
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
    final game = gameWithArmies(
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
        topology: topology(),
        humanPlayerId: human,
        targetFullProvinceId: foreign,
      ),
      isTrue,
    );
    expect(
      invadeConceivableCheap(
        game: game,
        topology: topology(),
        humanPlayerId: human,
        targetFullProvinceId: other,
      ),
      isFalse,
    );
  });

  test('sea zone and obfuscated military hide Move/Invade', () {
    final game = gameWithArmies(
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
        topology: topology(),
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
        topology: topology(),
        armyMovePickerCache: cache,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: true,
      ).showInvade,
      isFalse,
    );
  });

  test('Home-only adjacent foreign province enables Invade via detach', () {
    final game = gameWithArmies(
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
      topology: topology(),
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
    final game = gameWithArmies(
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
      topology: topology(),
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
    final game = gameWithArmies(
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
        topology: topology(),
        humanPlayerId: human,
        targetFullProvinceId: other,
      ),
      isFalse,
    );
  });

  test(
    'capital Move detach when stationed field armies have no destinations',
    () {
      final game = gameWithArmies(
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
        topology: topology(),
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
