import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/combat/military_attack_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
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
  });
}
