import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('isCapitalSiege', () {
    test('returns false when not a siege (no fort)', () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'capital',
          ),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'capital',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 0,
        terrain: 'plains',
      );
      expect(isCapitalSiege(game, ctx), isFalse);
    });

    test('returns false when siege but province is not a capital', () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'capital',
          ),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'other',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 1,
        terrain: 'plains',
      );
      expect(isCapitalSiege(game, ctx), isFalse);
    });

    test('returns true when siege of GP capital', () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'capital',
          ),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'capital',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 1,
        terrain: 'plains',
      );
      expect(isCapitalSiege(game, ctx), isTrue);
    });
  });

  group('resolveCombatModeForBattle', () {
    late Game game;
    late BattleContext ctxNonCapital;

    setUp(() {
      game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true, capitalProvinceId: 'capital'),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      ctxNonCapital = BattleContext(
        provinceId: 'prov',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 0,
        terrain: 'plains',
      );
    });

    test('capital siege always returns QuickBattle', () {
      final ctx = BattleContext(
        provinceId: 'capital',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 1,
        terrain: 'plains',
      );
      expect(
        resolveCombatModeForBattle(
          game,
          ctx,
          defaultMode: CombatMode.autoResolve,
        ),
        CombatMode.quickBattle,
      );
    });

    test('uses default when no per-battle override', () {
      expect(
        resolveCombatModeForBattle(
          game,
          ctxNonCapital,
          defaultMode: CombatMode.autoResolve,
        ),
        CombatMode.autoResolve,
      );
      expect(
        resolveCombatModeForBattle(
          game,
          ctxNonCapital,
          defaultMode: CombatMode.quickBattle,
        ),
        CombatMode.quickBattle,
      );
    });

    test('uses per-battle override when provided', () {
      expect(
        resolveCombatModeForBattle(
          game,
          ctxNonCapital,
          defaultMode: CombatMode.autoResolve,
          perBattleOverrides: {'prov': CombatMode.quickBattle},
        ),
        CombatMode.quickBattle,
      );
      expect(
        resolveCombatModeForBattle(
          game,
          ctxNonCapital,
          defaultMode: CombatMode.quickBattle,
          perBattleOverrides: {'prov': CombatMode.autoResolve},
        ),
        CombatMode.autoResolve,
      );
    });
  });
}
