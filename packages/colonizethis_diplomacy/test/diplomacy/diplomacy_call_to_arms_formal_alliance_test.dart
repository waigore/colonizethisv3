import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/call_to_arms_fixtures.dart';

void main() {
  group('call to arms (formal alliance gating)', () {
    // AC1 (negative): informal Allied relation band (score >= 76) with NO formal
    // alliance must not trigger call to arms.
    test(
      'informal Allied level without formal alliance: no pending call to arms',
      () {
        final game = threePowerCallToArmsGame(
          gp1Human: true,
          gp2Human: true,
          gp1gp2Score: 80,
          gp1gp2FormalAlliance: false,
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp3': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp2',
              ),
            ],
          },
        );
        final result = resolveDiplomacyPhase(game, orders);
        expect(result.isPending, isFalse);
        expect(result.pendingCallToArms, isNull);
        expect(factionsAtWar(result.game, 'gp1', 'gp3'), isFalse);
      },
    );

    // AC1 (negative, AI): AI ally with informal Allied band but no formal
    // alliance does not join the defender's war.
    test('informal Allied AI ally without formal alliance: stays at peace', () {
      final game = threePowerCallToArmsGame(
        gp1Human: false,
        gp2Human: true,
        gp1gp2Score: 80,
        gp1gp2FormalAlliance: false,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp3': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isFalse);
      expect(factionsAtWar(result.game, 'gp1', 'gp3'), isFalse);
    });

    // Edge case: an alliance formed the SAME turn as the war declaration must
    // not trigger call to arms (eligibility uses the end-of-preceding-turn
    // snapshot taken before this turn's Alliance orders resolve).
    test(
      'alliance formed same turn as war declaration: no call to arms',
      () {
        final game = threePowerCallToArmsGame(
          gp1Human: false,
          gp2Human: true,
          gp1gp2Score: 50,
          gp1gp2Level: RelationLevel.neutral,
          gp1gp2FormalAlliance: false,
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp1': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.alliance,
                targetFactionId: 'gp2',
              ),
            ],
            'gp3': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp2',
              ),
            ],
          },
        );
        final result = resolveDiplomacyPhase(game, orders);
        expect(result.isPending, isFalse);
        // Alliance still forms this turn...
        final rel = getRelation(result.game, 'gp1', 'gp2');
        expect(rel!.formalAlliance, isTrue);
        // ...but mutual defence does not apply for the same-turn war.
        expect(factionsAtWar(result.game, 'gp1', 'gp3'), isFalse);
      },
    );

    // Positive AC2 (AI): formal alliance present at phase start -> AI ally with
    // sufficient score joins the war.
    test('formal alliance + score >= 50: AI ally joins war with aggressor', () {
      final game = threePowerCallToArmsGame(
        gp1Human: false,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp3': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isFalse);
      expect(factionsAtWar(result.game, 'gp1', 'gp3'), isTrue);
    });
  });
}
