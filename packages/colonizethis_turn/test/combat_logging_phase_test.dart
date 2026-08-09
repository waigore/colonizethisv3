import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'combat_logging_phase_cases.dart';
import 'support/combat_logging_test_support.dart';
import 'support/turn_resolver_test_harness.dart';

void main() {
  group('land combat logging (resolveTurnForGame phase)', () {
    final getCapture = setupCombatLogCapture();

    test(
      'Combat phase logs conflict_detection and battle_start for moved-in attack',
      () {
        final capture = getCapture();
        resolveTurnComplete(
          game: combatLoggingTwoProvinceBattleGame(),
          topology: combatLoggingTwoProvinceTopology(),
          orders: combatLoggingAttackOrders(),
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        );

        final combat = capture.combat;
        expect(
          combat.any(
            (m) => m.contains('turn: combat conflict_detection start'),
          ),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('turn: combat conflict_detection end') &&
                m.contains('battleContexts=1'),
          ),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('turn: combat battle_start') &&
                m.contains('attackerSides=1') &&
                m.contains('attackerUnitsTotal=1') &&
                m.contains('mode=autoResolve'),
          ),
          isTrue,
        );
        expect(
          combat.any((m) => m.contains('combat: combat engagement')),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('combat: combat battle_apply') &&
                m.contains('mode=autoResolve'),
          ),
          isTrue,
        );
        expect(
          capture.events.any(
            (e) =>
                e.level == Level.info &&
                e.message.contains('turn: phase combat start'),
          ),
          isTrue,
        );
        expect(
          capture.events.any(
            (e) =>
                e.level == Level.info &&
                e.message.contains('turn: phase combat end'),
          ),
          isTrue,
        );
      },
    );

    test(
      'Quick Battle path logs battle_apply quickBattle not auto engagement',
      () {
        final capture = getCapture();
        resolveTurnComplete(
          game: combatLoggingTwoProvinceBattleGame(
            defaultCombatMode: CombatMode.quickBattle,
          ),
          topology: combatLoggingTwoProvinceTopology(),
          orders: combatLoggingAttackOrders(),
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        );

        final combat = capture.combat;
        expect(
          combat.any(
            (m) =>
                m.contains('turn: combat battle_start') &&
                m.contains('mode=quickBattle'),
          ),
          isTrue,
        );
        expect(
          combat.any(
            (m) =>
                m.contains('turn: combat battle_apply') &&
                m.contains('mode=quickBattle') &&
                m.contains('winner='),
          ),
          isTrue,
        );
        expect(
          combat.any((m) => m.contains('combat: combat engagement')),
          isFalse,
        );
      },
    );

    test(
      'no land battles still logs conflict_detection end with battleContexts=0',
      () {
        final capture = getCapture();
        resolveTurnComplete(
          game: combatLoggingSingleProvinceGame(),
          topology: turnTestOwSingleProvinceTopology(),
          orders: const Orders(),
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        );

        final combat = capture.combat;
        expect(
          combat.any(
            (m) =>
                m.contains('turn: combat conflict_detection end') &&
                m.contains('battleContexts=0'),
          ),
          isTrue,
        );
        expect(
          combat.any((m) => m.contains('turn: combat battle_start')),
          isFalse,
        );
      },
    );
  });
}
