// Case bodies for `pendingDeclareWarFrom` pin (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerExpandPhasePlannerPendingDeclareWarCases() {
  group('pendingDeclareWarFrom', () {
    test('false when prior diplomatic orders is null', () {
      expect(
        pendingDeclareWarFrom(
          sameTurnPriorDiplomaticOrders: null,
          declarerFactionId: 'gp2',
          targetFactionId: 'gp4',
        ),
        isFalse,
        reason:
            'A null prior-orders bag means no earlier Full-AI player has '
            'committed orders this turn; the helper must short-circuit to '
            'false so callers do not need a separate null guard.',
      );
    });

    test('false when the declarer has no orders in the bag', () {
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp3': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp4',
            ),
          ],
        },
      );
      expect(
        pendingDeclareWarFrom(
          sameTurnPriorDiplomaticOrders: priorOrders,
          declarerFactionId: 'gp2',
          targetFactionId: 'gp4',
        ),
        isFalse,
        reason:
            'When the declarer entry is missing from the prior-orders bag '
            'the helper must report false; only the requested declarer '
            'matters.',
      );
    });

    test('false when the declarer order targets a different faction', () {
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp5',
            ),
          ],
        },
      );
      expect(
        pendingDeclareWarFrom(
          sameTurnPriorDiplomaticOrders: priorOrders,
          declarerFactionId: 'gp2',
          targetFactionId: 'gp4',
        ),
        isFalse,
        reason:
            'A declareWar against a different faction must not satisfy the '
            'predicate; pinning prevents accidental any-target matching.',
      );
    });

    test('false when the declarer order is not a declareWar', () {
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.offerPeace,
              targetFactionId: 'gp4',
            ),
          ],
        },
      );
      expect(
        pendingDeclareWarFrom(
          sameTurnPriorDiplomaticOrders: priorOrders,
          declarerFactionId: 'gp2',
          targetFactionId: 'gp4',
        ),
        isFalse,
        reason:
            'Only DiplomaticOrderType.declareWar orders trigger the '
            'predicate; other order types (e.g. offerPeace) must be '
            'ignored even when the target matches.',
      );
    });

    test('true when an earlier GP declared war on the target', () {
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp4',
            ),
          ],
        },
      );
      expect(
        pendingDeclareWarFrom(
          sameTurnPriorDiplomaticOrders: priorOrders,
          declarerFactionId: 'gp2',
          targetFactionId: 'gp4',
        ),
        isTrue,
        reason:
            'Canonical hit: declarer gp2 has a same-turn declareWar against '
            'target gp4 — the predicate must return true so the consumer '
            'suppresses a redundant declareWar back from the target.',
      );
    });

    test('true when the matching order is preceded by an unrelated order', () {
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.offerPeace,
              targetFactionId: 'gp9',
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp4',
            ),
          ],
        },
      );
      expect(
        pendingDeclareWarFrom(
          sameTurnPriorDiplomaticOrders: priorOrders,
          declarerFactionId: 'gp2',
          targetFactionId: 'gp4',
        ),
        isTrue,
        reason:
            'Predicate must walk the full per-declarer order list, not '
            'short-circuit on the first non-matching entry.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp4',
            ),
          ],
        },
      );
      final first = pendingDeclareWarFrom(
        sameTurnPriorDiplomaticOrders: priorOrders,
        declarerFactionId: 'gp2',
        targetFactionId: 'gp4',
      );
      final second = pendingDeclareWarFrom(
        sameTurnPriorDiplomaticOrders: priorOrders,
        declarerFactionId: 'gp2',
        targetFactionId: 'gp4',
      );
      final third = pendingDeclareWarFrom(
        sameTurnPriorDiplomaticOrders: priorOrders,
        declarerFactionId: 'gp2',
        targetFactionId: 'gp4',
      );
      expect(
        first,
        second,
        reason:
            'Pure helper must return identical results on repeated calls — '
            'required by issue #2509 Must-have #7 (phase planners are pure '
            'functions with deterministic inputs).',
      );
      expect(
        second,
        third,
        reason: 'Same as above across three consecutive calls.',
      );
    });
  });
}
