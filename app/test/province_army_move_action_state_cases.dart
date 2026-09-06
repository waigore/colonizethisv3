// Scenario table for province army move action state pins (Refs #4734 Slice E, #4350).

import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_action_state.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_home_army.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_army_move_action_state_support.dart';

typedef ProvinceArmyMoveActionCase = ({
  String name,
  List<Army> armies,
  String provinceId,
  bool showsFullMilitaryIntel,
  bool isSeaZoneContext,
  void Function(ProvinceArmyMoveActionState state) assertState,
});

List<ProvinceArmyMoveActionCase> provinceArmyMoveActionCases() => [
      (
        name: 'Home Army with regiments enables Move via detach',
        armies: [
          const Army(
            id: 'home',
            ownerId: kArmyMoveActionHumanId,
            regionId: 'oldWorld',
            stationedProvinceId: kArmyMoveActionOwnedId,
            regimentUnitIds: ['r1'],
            isHomeArmy: true,
          ),
        ],
        provinceId: kArmyMoveActionOwnedId,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: false,
        assertState: (state) {
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
        },
      ),
      (
        name: 'empty Home Army still shows disabled Move with home reason',
        armies: [
          const Army(
            id: 'home',
            ownerId: kArmyMoveActionHumanId,
            regionId: 'oldWorld',
            stationedProvinceId: kArmyMoveActionOwnedId,
            regimentUnitIds: [],
            isHomeArmy: true,
          ),
        ],
        provinceId: kArmyMoveActionOwnedId,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: false,
        assertState: (state) {
          expect(state.showMove, isTrue);
          expect(state.moveEnabled, isFalse);
          expect(
            state.moveDisabledReason,
            ProvinceArmyMoveDisabledReason.homeArmyCannotLeave,
          );
        },
      ),
      (
        name: 'Invade visible but disabled when not in cache reachability',
        armies: [
          const Army(
            id: 'field',
            ownerId: kArmyMoveActionHumanId,
            regionId: 'oldWorld',
            stationedProvinceId: kArmyMoveActionOwnedId,
            regimentUnitIds: ['r1'],
          ),
        ],
        provinceId: kArmyMoveActionForeignId,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: false,
        assertState: (state) {
          expect(state.showInvade, isTrue);
          expect(state.invadeEnabled, isFalse);
          expect(
            state.invadeDisabledReason,
            ProvinceArmyMoveDisabledReason.cannotReach,
          );
        },
      ),
      (
        name: 'Home-only adjacent foreign province enables Invade via detach',
        armies: [
          const Army(
            id: 'home',
            ownerId: kArmyMoveActionHumanId,
            regionId: 'oldWorld',
            stationedProvinceId: kArmyMoveActionOwnedId,
            regimentUnitIds: ['r1'],
            isHomeArmy: true,
          ),
        ],
        provinceId: kArmyMoveActionForeignId,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: false,
        assertState: (state) {
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
        },
      ),
      (
        name: 'mixed unreachable field army still enables Invade via Home Army',
        armies: [
          const Army(
            id: 'home',
            ownerId: kArmyMoveActionHumanId,
            regionId: 'oldWorld',
            stationedProvinceId: kArmyMoveActionOwnedId,
            regimentUnitIds: ['r1'],
            isHomeArmy: true,
          ),
          const Army(
            id: 'field',
            ownerId: kArmyMoveActionHumanId,
            regionId: 'oldWorld',
            stationedProvinceId: kArmyMoveActionOtherId,
            regimentUnitIds: ['r2'],
          ),
        ],
        provinceId: kArmyMoveActionForeignId,
        showsFullMilitaryIntel: true,
        isSeaZoneContext: false,
        assertState: (state) {
          expect(state.showInvade, isTrue);
          expect(state.invadeEnabled, isTrue);
          expect(state.eligibleInvadeArmyIds, isEmpty);
        },
      ),
    ];

ProvinceArmyMoveActionState computeProvinceArmyMoveActionForCase(
  ProvinceArmyMoveActionCase case_,
) {
  final game = armyMoveActionGameWithArmies(armies: case_.armies);
  return computeProvinceArmyMoveActionState(
    game: game,
    humanPlayerId: kArmyMoveActionHumanId,
    provinceId: case_.provinceId,
    topology: armyMoveActionTopology(),
    armyMovePickerCache: PerPlayerArmyMovePickerCache(),
    showsFullMilitaryIntel: case_.showsFullMilitaryIntel,
    isSeaZoneContext: case_.isSeaZoneContext,
  );
}
