import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/combat/military_attack_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'test_fixtures.dart';

void main() {
  group('landBattleAttackTreasuryCostForPlayer', () {
    test('base cost 100 without military tech discounts', () {
      const p = Player(id: 'p1', displayName: 'P1', isHuman: true);
      expect(landBattleAttackTreasuryCostForPlayer(p), 100);
    });

    test(
      'applies multiplicative discounts for machinery and modern funding',
      () {
        final p = Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
          techUnlocked: const {
            kTechIdIndustrialMachinery: true,
            kTechIdModernMilitaryFunding: true,
          },
        );
        expect(
          landBattleAttackTreasuryCostForPlayer(p),
          (100 * 0.75 * 0.85).ceil(),
        );
      },
    );
  });

  group('applyLandBattleAttackTreasuryCosts', () {
    test('deducts per attacker Great Power once per battle context', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'a1', displayName: 'A1', isHuman: true, treasury: 500),
          Player(id: 'd1', displayName: 'D1', isHuman: false, treasury: 0),
        ],
      );
      final ctx = BattleContext(
        regionId: kRegionOldWorld,
        provinceId: 'oldWorld|p1',
        defenderFactionId: 'd1',
        defenderUnitIds: const [],
        fortLevel: 0,
        terrain: 'field',
        attackers: [
          AttackingSide(
            factionId: 'a1',
            unitIds: const ['u1'],
            generalId: null,
          ),
        ],
        defenderGeneralId: null,
        defenderGeneralMedals: 0,
      );
      final after = applyLandBattleAttackTreasuryCosts(game, ctx);
      expect(after.playerById('a1')!.treasury, 500 - 100);
    });

    test(
      'deducts treasury when attacker is not first in players list order',
      () {
        final game = TestFixtures.minimalGame(
          players: const [
            Player(id: 'z1', displayName: 'Z', isHuman: false, treasury: 0),
            Player(id: 'a1', displayName: 'A1', isHuman: true, treasury: 500),
            Player(id: 'y1', displayName: 'Y', isHuman: false, treasury: 0),
          ],
        );
        final ctx = BattleContext(
          regionId: kRegionOldWorld,
          provinceId: 'oldWorld|p1',
          defenderFactionId: 'd1',
          defenderUnitIds: const [],
          fortLevel: 0,
          terrain: 'field',
          attackers: [
            AttackingSide(
              factionId: 'a1',
              unitIds: const ['u1'],
              generalId: null,
            ),
          ],
          defenderGeneralId: null,
          defenderGeneralMedals: 0,
        );
        final after = applyLandBattleAttackTreasuryCosts(game, ctx);
        expect(after.playerById('a1')!.treasury, 500 - 100);
      },
    );

    test('deducts treasury for each distinct Great Power attacker side', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'a1', displayName: 'A1', isHuman: true, treasury: 300),
          Player(id: 'a2', displayName: 'A2', isHuman: true, treasury: 400),
          Player(id: 'd1', displayName: 'D1', isHuman: false, treasury: 0),
        ],
      );
      final ctx = BattleContext(
        regionId: kRegionOldWorld,
        provinceId: 'oldWorld|p1',
        defenderFactionId: 'd1',
        defenderUnitIds: const [],
        fortLevel: 0,
        terrain: 'field',
        attackers: [
          const AttackingSide(
            factionId: 'a1',
            unitIds: ['u1'],
            generalId: null,
          ),
          const AttackingSide(
            factionId: 'a2',
            unitIds: ['u2'],
            generalId: null,
          ),
        ],
        defenderGeneralId: null,
        defenderGeneralMedals: 0,
      );
      final after = applyLandBattleAttackTreasuryCosts(game, ctx);
      expect(after.playerById('a1')!.treasury, 300 - 100);
      expect(after.playerById('a2')!.treasury, 400 - 100);
    });

    test('does not deduct treasury when attacker is not a Great Power', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'a1', displayName: 'A1', isHuman: true, treasury: 500),
          Player(id: 'd1', displayName: 'D1', isHuman: false, treasury: 0),
        ],
        minorNations: const [MinorNation(id: 'm1', displayName: 'Minor')],
      );
      final ctx = BattleContext(
        regionId: kRegionOldWorld,
        provinceId: 'oldWorld|p1',
        defenderFactionId: 'd1',
        defenderUnitIds: const [],
        fortLevel: 0,
        terrain: 'field',
        attackers: const [
          AttackingSide(factionId: 'm1', unitIds: ['u1'], generalId: null),
        ],
        defenderGeneralId: null,
        defenderGeneralMedals: 0,
      );
      final after = applyLandBattleAttackTreasuryCosts(game, ctx);
      expect(after.playerById('a1')!.treasury, 500);
    });
  });
}
