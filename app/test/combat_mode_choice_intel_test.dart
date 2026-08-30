// Unit tests for CMPT10001 force/fort helper. SPEC/ui/components/combat-mode-choice-intel.md
// (Refs #4438).

import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_intel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_test/flutter_test.dart';

import 'combat_mode_choice_intel_test_support.dart';

void main() {
  suppressLogsForTests();

  CombatModeChoiceIntel? intelFor(Game game) {
    final view = buildPlayerView(game, const MapTopology(), kCmHumanId);
    return computeCombatModeChoiceIntel(
      game: game,
      humanPlayerId: kCmHumanId,
      provinceId: kCmBattleId,
      playerView: view,
    );
  }

  group('resolveCombatModeChoiceProvinceId', () {
    test('uses prefixed provinceId when the province exists', () {
      final game = buildCombatModeChoiceIntelGame();
      expect(
        resolveCombatModeChoiceProvinceId(
          game: game,
          provinceId: kCmBattleId,
          provinceName: 'Wrong',
        ),
        kCmBattleId,
      );
    });

    test('unique displayName fallback when provinceId is omitted', () {
      final game = buildCombatModeChoiceIntelGame();
      expect(
        resolveCombatModeChoiceProvinceId(game: game, provinceName: 'Lisbon'),
        kCmBattleId,
      );
    });

    test('fail-closed when two provinces share the displayName', () {
      final game = buildCombatModeChoiceIntelGame(
        extraProvinces: const [
          Province(
            id: 'oldWorld|p_dup',
            regionId: 'oldWorld',
            ownerId: kCmRivalId,
            displayName: 'Lisbon',
          ),
        ],
      );
      expect(
        resolveCombatModeChoiceProvinceId(game: game, provinceName: 'Lisbon'),
        isNull,
      );
    });
  });

  group('computeCombatModeChoiceIntel', () {
    test('attacker full intel counts owner defenders not co-attackers', () {
      final game = buildCombatModeChoiceIntelGame(
        units: [
          cmUnit(
            id: 'h1',
            ownerId: kCmHumanId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 'h2',
            ownerId: kCmHumanId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 'd1',
            ownerId: kCmRivalId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 'd2',
            ownerId: kCmRivalId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 'c1',
            ownerId: kCmThirdId,
            locationProvinceId: kCmBattleId,
          ),
        ],
      );
      final intel = intelFor(game)!;
      expect(intel.role, CombatModeChoiceRole.attacker);
      expect(intel.ownRegimentCount, 2);
      expect(intel.enemyRegimentCount, 2);
      expect(intel.fortLevel, 1);
      expect(intel.defendersUnknown, isFalse);
    });

    test('attacker unknown intel omits fort and enemy count', () {
      final game = buildCombatModeChoiceIntelGame(
        battleFullyVisible: false,
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
      final intel = intelFor(game)!;
      expect(intel.defendersUnknown, isTrue);
      expect(intel.enemyRegimentCount, isNull);
      expect(intel.fortLevel, isNull);
      expect(intel.ownRegimentCount, 1);
    });

    test('defender counts all non-human units including non-movers', () {
      final game = buildCombatModeChoiceIntelGame(
        battleOwnerId: kCmHumanId,
        fortLevel: 2,
        units: [
          cmUnit(
            id: 'g1',
            ownerId: kCmHumanId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 'r1',
            ownerId: kCmHumanId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 'a1',
            ownerId: kCmRivalId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 'c1',
            ownerId: kCmThirdId,
            locationProvinceId: kCmBattleId,
          ),
        ],
      );
      final intel = intelFor(game)!;
      expect(intel.role, CombatModeChoiceRole.defender);
      expect(intel.ownRegimentCount, 2);
      expect(intel.enemyRegimentCount, 2);
      expect(intel.fortLevel, 2);
    });

    test('attacker own count ignores leftover army still at home', () {
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
      expect(intelFor(game)!.ownRegimentCount, 1);
    });

    test('attacker omits enemy line when owner combat count is 0', () {
      final game = buildCombatModeChoiceIntelGame(
        units: [
          cmUnit(
            id: 'h1',
            ownerId: kCmHumanId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 't1',
            ownerId: kCmThirdId,
            locationProvinceId: kCmBattleId,
          ),
        ],
      );
      final intel = intelFor(game)!;
      expect(intel.role, CombatModeChoiceRole.attacker);
      expect(intel.ownRegimentCount, 1);
      expect(intel.enemyRegimentCount, isNull);
      expect(intel.fortLevel, 1);
    });

    test('leftover human garrison in foreign province stays attacker role', () {
      final game = buildCombatModeChoiceIntelGame(
        units: [
          cmUnit(
            id: 'h1',
            ownerId: kCmHumanId,
            locationProvinceId: kCmBattleId,
          ),
          cmUnit(
            id: 'g1',
            ownerId: kCmThirdId,
            locationProvinceId: kCmBattleId,
          ),
        ],
      );
      final intel = intelFor(game)!;
      expect(intel.role, CombatModeChoiceRole.attacker);
      expect(intel.ownRegimentCount, 1);
      expect(intel.enemyRegimentCount, isNull);
    });
  });

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
