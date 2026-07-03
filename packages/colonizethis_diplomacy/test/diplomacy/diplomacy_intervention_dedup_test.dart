import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

/// Regression coverage for the O(1) intervention-choice lookup (Refs #3419 step
/// 6). When one aggressor declares war on two Minors in the same turn and an AI
/// GP is invested in both, that GP must record exactly one intervention choice
/// toward the aggressor for the turn — the second defender sees the already
/// recorded key and is skipped, identical to the prior history-scan behaviour.

int _interventionChoiceCount(Game game, String from, String to) {
  return game.diplomaticHistoryEvents.where((e) {
    final isChoice = e.type == DiplomaticEventType.interventionIntervene ||
        e.type == DiplomaticEventType.interventionDoNothing ||
        e.type == DiplomaticEventType.interventionProtest;
    return isChoice && e.fromFactionId == from && e.toFactionId == to;
  }).length;
}

void main() {
  group('intervention choice dedup (O(1) lookup)', () {
    test(
      'positive: AI GP invested in two attacked minors records one choice per turn',
      () {
        final orders = Orders(
          diplomaticOrdersByPlayerId: const {
            'gp_attacker': [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'minor1',
              ),
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'minor2',
              ),
            ],
          },
        );

        final result = resolveDiplomacyPhase(twoMinorWarGame(), orders);
        // No human is invested, so the phase fully resolves (no pending prompt).
        expect(result.isPending, isFalse);
        expect(
          _interventionChoiceCount(result.game, 'gp_ai', 'gp_attacker'),
          1,
        );
      },
    );

    test(
      'negative: a pre-recorded choice this turn suppresses re-processing',
      () {
        final base = twoMinorWarGame();
        // Seed a recorded choice for this turn so the resolver treats the AI
        // GP as already decided and emits no further intervention events.
        final seeded = base.copyWith(
          diplomaticHistoryEvents: const [
            DiplomaticEvent(
              turn: 4,
              intraTurnIndex: 0,
              type: DiplomaticEventType.interventionDoNothing,
              participants: {'gp_ai', 'gp_attacker'},
              fromFactionId: 'gp_ai',
              toFactionId: 'gp_attacker',
            ),
          ],
        );

        final orders = Orders(
          diplomaticOrdersByPlayerId: const {
            'gp_attacker': [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'minor1',
              ),
            ],
          },
        );

        final result = resolveDiplomacyPhase(seeded, orders);
        expect(result.isPending, isFalse);
        // Still exactly the one seeded choice; no new ones appended.
        expect(
          _interventionChoiceCount(result.game, 'gp_ai', 'gp_attacker'),
          1,
        );
      },
    );
  });
}
