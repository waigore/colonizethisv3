import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('buildQuickBattleInput', () {
    test('produces QuickBattleInput with defender and attacker groups', () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'att',
            locationProvinceId: 'P1',
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'P1',
          ),
        ],
      );
      final ctx = quickBattleInputBuilderContext();
      final input = buildQuickBattleInput(game, ctx);
      expect(input.provinceId, 'P1');
      expect(input.regionId, 'oldWorld');
      expect(input.attackerFactionId, 'att');
      expect(input.defenderFactionId, 'def');
      expect(input.attackerDeployment.groups.length, 1);
      expect(input.attackerDeployment.groups.first.unitIds, ['u1']);
      expect(input.defenderDeployment.groups.length, 1);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(input.attackerDeployment.groups.first.lane, QuickBattleLane.center);
      expect(input.attackerDeployment.groups.first.line, QuickBattleLine.front);
    });

    test('filters out unit ids not present in region', () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: [
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'P1',
          ),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2', 'missing'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['ghost']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final input = buildQuickBattleInput(game, ctx);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(input.attackerDeployment.groups.first.unitIds, isEmpty);
    });

    test('supplies leader multipliers from Game players (napoleon 1.25, frederick 1.15)', () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: [
          Unit(id: 'u1', type: 'musketeers', ownerId: 'att', locationProvinceId: 'P1'),
          Unit(id: 'u2', type: 'pikemen', ownerId: 'def', locationProvinceId: 'P1'),
        ],
        players: landResolverNapoleonFrederickPlayers,
      );
      final ctx = quickBattleInputBuilderContext();
      final input = buildQuickBattleInput(game, ctx);
      expect(input.attackerLeaderMultiplier, 1.25);
      expect(input.defenderLeaderMultiplier, 1.15);
    });

    test('leader multipliers default to 1.0 when players have no leaderKey', () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: [
          Unit(id: 'u1', type: 'musketeers', ownerId: 'att', locationProvinceId: 'P1'),
          Unit(id: 'u2', type: 'pikemen', ownerId: 'def', locationProvinceId: 'P1'),
        ],
      );
      final ctx = quickBattleInputBuilderContext();
      final input = buildQuickBattleInput(game, ctx);
      expect(input.attackerLeaderMultiplier, 1.0);
      expect(input.defenderLeaderMultiplier, 1.0);
    });

    test('builds input from newWorld BattleContext', () {
      const nw = 'newWorld';
      const provinceId = 'newWorld|N1';
      final game = quickBattleInputBuilderNewWorldGame(
        provinceId: provinceId,
        units: [
          Unit(id: 'u1', type: 'musketeers', ownerId: 'att', locationProvinceId: provinceId),
          Unit(id: 'u2', type: 'pikemen', ownerId: 'def', locationProvinceId: provinceId),
        ],
      );
      final ctx = quickBattleInputBuilderContext(
        provinceId: provinceId,
        regionId: nw,
      );
      final input = buildQuickBattleInput(game, ctx);
      expect(input.regionId, nw);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(input.attackerDeployment.groups.first.unitIds, ['u1']);
    });

    test('passes attacker and defender medals from battle assignment', () {
      final game = quickBattleInputBuilderGame(
        turnNumber: 3,
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'att',
            locationProvinceId: 'P1',
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'P1',
          ),
        ],
        generals: const [
          General(id: 'ga', ownerId: 'att', medals: 3),
          General(id: 'gd', ownerId: 'def', medals: 2),
        ],
      );
      final ctx = quickBattleInputBuilderContext();
      final assignment = assignGeneralsForBattleContext(
        game: game,
        ctx: ctx,
        rng: battleAssignmentRng(game, ctx),
        ledger: CombatPhaseGeneralLedger(),
      );
      final input = buildQuickBattleInput(
        game,
        ctx,
        battleAssignment: assignment,
      );
      expect(input.attackerGeneralMedals, 3);
      expect(input.defenderGeneralMedals, 2);
    });
  });
}
