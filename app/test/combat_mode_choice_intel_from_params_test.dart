// From-params mapping for CMPT10001 intel helper.
// SPEC/ui/components/combat-mode-choice-intel.md (Refs #4438 / #4720 Slice G).

import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_intel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'combat_mode_choice_intel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('combatModeChoiceIntelFromParams', () {
    test('builds playerView when params omit it', () {
      final game = buildCombatModeChoiceIntelGame(
        units: [
          cmUnit(
            id: 'h1',
            ownerId: kCmHumanId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 'd1',
            ownerId: kCmRivalId,
            locationProvinceId: kCmBattleId,
          ),
        ],
      );
      final intel = combatModeChoiceIntelFromParams({
        'game': game,
        'humanPlayerId': kCmHumanId,
        'topology': const MapTopology(),
        'provinceId': kCmBattleId,
        'provinceName': 'Lisbon',
      });
      expect(intel?.ownRegimentCount, 1);
      expect(intel?.enemyRegimentCount, 1);
    });

    test('returns null when game snapshot is omitted', () {
      expect(
        combatModeChoiceIntelFromParams({
          'humanPlayerId': kCmHumanId,
          'topology': const MapTopology(),
          'provinceName': 'Lisbon',
        }),
        isNull,
      );
    });

    test('ignored ArmyMoveOrder does not inflate own count', () {
      final game = buildCombatModeChoiceIntelGame(
        units: [
          cmUnit(
            id: 'h1',
            ownerId: kCmHumanId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(id: 'i1', ownerId: kCmHumanId, locationProvinceId: kCmHomeId),
          cmUnit(
            id: 'd1',
            ownerId: kCmRivalId,
            locationProvinceId: kCmBattleId,
          ),
        ],
        armies: const [
          Army(
            id: 'a_locked',
            ownerId: kCmHumanId,
            regionId: 'oldWorld',
            stationedProvinceId: kCmHomeId,
            regimentUnitIds: ['i1'],
            isHomeArmy: true,
          ),
        ],
      );
      final intel = combatModeChoiceIntelFromParams({
        'game': game,
        'humanPlayerId': kCmHumanId,
        'topology': const MapTopology(),
        'provinceId': kCmBattleId,
        'draftOrders': Orders(
          armyMoveOrdersByPlayerId: const {
            kCmHumanId: [
              ArmyMoveOrder(
                armyId: 'a_locked',
                destinationProvinceId: kCmBattleId,
              ),
            ],
          },
        ),
      });
      expect(intel?.ownRegimentCount, 1);
    });
  });
}
