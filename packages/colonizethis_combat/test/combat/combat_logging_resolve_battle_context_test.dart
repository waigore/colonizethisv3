// Ported from colonizethis_logic (Refs #4090 Slice D).
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/combat_logging_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

void main() {
  group('land combat logging (resolveBattleContext)', () {
    final getCapture = setupCombatLogCapture();

    test(
      'resolveBattleContext emits engagement (debug) and battle_apply (info)',
      () {
        final capture = getCapture();
        final attackerUnits = [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
            medals: 3,
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
            medals: 2,
          ),
        ];
        final defenderUnits = [
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
            medals: 0,
          ),
        ];
        final game = landResolverBattleGame(
          units: [...attackerUnits, ...defenderUnits],
          players: landResolverNapoleonFrederickPlayers,
        );
        const ctx = BattleContext(
          provinceId: 'p',
          regionId: 'oldWorld',
          defenderFactionId: 'def',
          defenderUnitIds: ['d1'],
          attackers: [
            AttackingSide(factionId: 'att', unitIds: ['a1', 'a2']),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );

        resolveBattleContext(game, ctx);

        final combat = capture.combat;
        expect(
          combat.where((m) => m.contains('combat: combat engagement')).length,
          1,
        );
        final engagement = combat.firstWhere(
          (m) => m.contains('combat: combat engagement'),
        );
        expect(engagement, contains('result='));
        expect(engagement, contains('attackerFactionId=att'));
        expect(engagement, contains('attCasualties='));
        expect(engagement, contains('defCasualties='));

        final apply = combat.firstWhere(
          (m) => m.contains('combat: combat battle_apply'),
        );
        expect(apply, contains('mode=autoResolve'));
        expect(apply, contains('provinceFlipped='));
        expect(apply, contains('casualtiesApplied='));
        expect(apply, contains('ownerAfter='));

        expect(
          capture.events.any(
            (e) =>
                e.level == Level.debug &&
                e.message.contains('combat: combat engagement'),
          ),
          isTrue,
        );
        expect(
          capture.events.any(
            (e) =>
                e.level == Level.info &&
                e.message.contains('combat: combat battle_apply'),
          ),
          isTrue,
        );
      },
    );

    test('two attacker sides emit one debug line per executed engagement', () {
      final capture = getCapture();
      // First attacker must lose (defender still holds); otherwise a decisive
      // first attacker victory skips remaining attackers (no second engagement).
      final game = landResolverBattleGame(
        turnNumber: 8,
        globalGameSeed: 1234,
        units: [
          Unit(
            id: 'a1',
            type: 'peasant_levies',
            ownerId: 'attA',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'a2',
            type: 'peasant_levies',
            ownerId: 'attB',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'd1',
            type: 'grenadiers',
            ownerId: 'def',
            locationProvinceId: 'p',
            medals: 2,
          ),
          Unit(
            id: 'd2',
            type: 'grenadiers',
            ownerId: 'def',
            locationProvinceId: 'p',
            medals: 2,
          ),
        ],
        players: const [
          Player(id: 'attA', displayName: 'A', isHuman: true),
          Player(id: 'attB', displayName: 'B', isHuman: true),
          Player(id: 'def', displayName: 'D', isHuman: true),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1', 'd2'],
        attackers: [
          AttackingSide(factionId: 'attA', unitIds: ['a1']),
          AttackingSide(factionId: 'attB', unitIds: ['a2']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      resolveBattleContext(game, ctx);

      final engagementLines = capture.combat
          .where((m) => m.contains('combat: combat engagement'))
          .toList();
      expect(engagementLines.length, 2);
      expect(
        engagementLines
            .where((m) => m.contains('attackerFactionId=attA'))
            .length,
        1,
      );
      expect(
        engagementLines
            .where((m) => m.contains('attackerFactionId=attB'))
            .length,
        1,
      );
    });
  });
}
