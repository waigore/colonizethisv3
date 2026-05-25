// Pins the canonical `greatPowerWarCountOnTarget` and `pendingDeclareWarFrom`
// declare-war coordination helpers in `expand_phase_planner.dart`
// (Refs #2509 S1).
//
// Both helpers were relocated from `colonial_pressure.dart` so they survive
// the now-completed S1 deletion of that file. The canonical implementations live
// in `expand_phase_planner.dart`; `colonial_pressure.dart` retains thin
// delegating stubs for legacy callers until the planned deletion.
//
// Live consumers (post-relocation):
//   * `greatPowerWarCountOnTarget` is consumed by
//     `diplomatic_candidate_scoring_declare_war.dart` § war concentration
//     scoring to suppress dogpile declarations when the prospective target
//     is already engaged in multiple GP-vs-GP wars (resolved relations
//     plus same-turn declare-war orders from earlier Full-AI players).
//   * `pendingDeclareWarFrom` is consumed by
//     `diplomatic_candidate_scoring_declare_war.dart` § same-turn
//     declare-war suppression so the active player does not re-issue a
//     declaration that the prospective target has already committed
//     earlier in the same turn (mutual declarations are not re-issued).
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. `greatPowerWarCountOnTarget` counts every Great Power currently at
//      war with the target via [Game.diplomacyRelations]; minor and tribe
//      relations are ignored ([Game.playerById] filter).
//   2. The count folds same-turn declare-war orders from
//      [Orders.diplomaticOrdersByPlayerId] into the same set so a GP that
//      both has an at-war relation AND a same-turn declare-war is counted
//      exactly once (set semantics; no double counting).
//   3. The same-turn fold ignores minor / tribe declarers
//      ([Game.playerById] filter) and ignores orders that are not
//      `DiplomaticOrderType.declareWar` against the target.
//   4. `pendingDeclareWarFrom` returns `false` when
//      [sameTurnPriorDiplomaticOrders] is `null` (no earlier Full-AI
//      player has committed orders yet this turn).
//   5. `pendingDeclareWarFrom` returns `true` exactly when
//      [Orders.diplomaticOrdersByPlayerId] under [declarerFactionId]
//      contains a `DiplomaticOrderType.declareWar` order whose
//      [DiplomaticOrder.targetFactionId] equals [targetFactionId].
//   6. Both helpers are deterministic across repeated calls — required by
//      issue #2509 Must-have #7 (phase planners are pure functions with
//      deterministic inputs).
//   7. The delegating stubs in `colonial_pressure.dart` return the same
//      value as the canonical helpers for every relevant input — required
//      so the legacy `diplomatic_candidate_scoring_declare_war.dart`
//      consumers and the EXPAND planner agree on the war-concentration
//      and same-turn-declare-war gates.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as colonial_pressure;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('greatPowerWarCountOnTarget', () {
    test('counts only Great Powers via diplomacy relations', () {
      final game = Game(
        id: 'g-gp-war-count-basic',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 12),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 10,
          ),
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 20,
          ),
          // Minor war against gp3 must NOT be counted.
          DiplomacyRelation(
            factionId1: 'minor1',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 5,
          ),
          // Non-war relations against gp3 must NOT be counted.
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atPeace,
            score: 0,
          ),
        ],
      );
      expect(
        greatPowerWarCountOnTarget(game: game, targetGpId: 'gp3'),
        2,
        reason:
            'Only Great Power vs Great Power at-war relations against the '
            'target must contribute to the dogpile signal; minor wars and '
            'non-war states are ignored.',
      );
    });

    test('returns zero when no GP is at war with the target', () {
      final game = Game(
        id: 'g-gp-war-count-zero',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
        ],
      );
      expect(
        greatPowerWarCountOnTarget(game: game, targetGpId: 'gp3'),
        0,
        reason:
            'Targets without any active GP-vs-GP at-war relation must '
            'produce a zero count so the war-concentration gate does not '
            'suppress an otherwise valid declare-war candidate.',
      );
    });

    test('folds same-turn declare-war orders into the count', () {
      final game = Game(
        id: 'g-gp-war-count-same-turn',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
      );
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp3',
            ),
          ],
          // Minor declarer must be ignored.
          'minor1': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp3',
            ),
          ],
          // Non-declareWar order from a GP must be ignored.
          'gp1': [
            DiplomaticOrder(
              type: DiplomaticOrderType.offerPeace,
              targetFactionId: 'gp3',
            ),
          ],
        },
      );
      expect(
        greatPowerWarCountOnTarget(
          game: game,
          targetGpId: 'gp3',
          sameTurnPriorDiplomaticOrders: priorOrders,
        ),
        1,
        reason:
            'Same-turn declarer set must include only Great Powers that '
            'committed a declareWar against the target; minor declarers '
            'and non-declareWar orders are filtered out.',
      );
    });

    test(
      'does not double-count a GP that both relates atWar and declares this turn',
      () {
        final game = Game(
          id: 'g-gp-war-count-dedupe',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: false),
            Player(id: 'gp2', displayName: 'P2', isHuman: false),
            Player(id: 'gp3', displayName: 'P3', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              state: RelationState.atWar,
              score: 10,
            ),
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
              state: RelationState.atWar,
              score: 20,
            ),
          ],
        );
        const priorOrders = Orders(
          diplomaticOrdersByPlayerId: {
            // gp2 is already at war with gp3 AND declared this turn —
            // must be counted exactly once.
            'gp2': [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp3',
              ),
            ],
          },
        );
        expect(
          greatPowerWarCountOnTarget(
            game: game,
            targetGpId: 'gp3',
            sameTurnPriorDiplomaticOrders: priorOrders,
          ),
          2,
          reason:
              'Resolved at-war partners and same-turn declarers must be '
              'merged into a single set so a GP appearing in both sources '
              'still contributes 1 to the dogpile count (not 2). Pins the '
              'set semantics required by the war-concentration suppression '
              'in diplomatic_candidate_scoring_declare_war.dart.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = Game(
        id: 'g-gp-war-count-determinism',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      );
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp3',
            ),
          ],
        },
      );
      final first = greatPowerWarCountOnTarget(
        game: game,
        targetGpId: 'gp3',
        sameTurnPriorDiplomaticOrders: priorOrders,
      );
      final second = greatPowerWarCountOnTarget(
        game: game,
        targetGpId: 'gp3',
        sameTurnPriorDiplomaticOrders: priorOrders,
      );
      final third = greatPowerWarCountOnTarget(
        game: game,
        targetGpId: 'gp3',
        sameTurnPriorDiplomaticOrders: priorOrders,
      );
      expect(
        first,
        second,
        reason:
            'Pure helper must return identical counts on repeated calls — '
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

  group('colonial_pressure delegation contract (Refs #2509 S1)', () {
    test(
      'colonial_pressure.greatPowerWarCountOnTarget mirrors the canonical helper',
      () {
        // Pins the S1 delegation contract: the legacy public symbol exported
        // from `colonial_pressure.dart` must mirror the canonical helper for
        // every relevant fixture so removing the stub in a future slice
        // cannot silently shift the war-concentration suppression boundary
        // in `diplomatic_candidate_scoring_declare_war.dart`.
        final game = Game(
          id: 'g-delegation-gp-war-count',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: false),
            Player(id: 'gp2', displayName: 'P2', isHuman: false),
            Player(id: 'gp3', displayName: 'P3', isHuman: false),
            Player(id: 'gp4', displayName: 'P4', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              state: RelationState.atWar,
              score: 10,
            ),
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
              state: RelationState.atWar,
              score: 20,
            ),
          ],
        );
        const priorOrders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp4': [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp3',
              ),
            ],
          },
        );
        // Fixture coverage: zero-count target (gp4, no relations),
        // count-only-from-relations, count-from-relations-plus-same-turn.
        final fixtures = <(String, Orders?, int, String)>[
          ('gp4', null, 0, 'target with no GP at war'),
          ('gp3', null, 2, 'target with two at-war GP partners only'),
          (
            'gp3',
            priorOrders,
            3,
            'target with two at-war partners plus a same-turn declarer',
          ),
        ];
        for (final (targetGpId, sameTurn, expectedCount, label) in fixtures) {
          final canonical = greatPowerWarCountOnTarget(
            game: game,
            targetGpId: targetGpId,
            sameTurnPriorDiplomaticOrders: sameTurn,
          );
          final delegated = colonial_pressure.greatPowerWarCountOnTarget(
            game: game,
            targetGpId: targetGpId,
            sameTurnPriorDiplomaticOrders: sameTurn,
          );
          expect(
            delegated,
            canonical,
            reason:
                '`colonial_pressure.greatPowerWarCountOnTarget` is a thin '
                'delegating stub for legacy callers; it must mirror the '
                'canonical helper exactly so the '
                'diplomatic_candidate_scoring_declare_war.dart war-'
                'concentration gate stays consistent (fixture: $label).',
          );
          expect(
            canonical,
            expectedCount,
            reason: 'Canonical helper count check (fixture: $label).',
          );
        }
      },
    );

    test(
      'colonial_pressure.pendingDeclareWarFrom mirrors the canonical helper',
      () {
        // Pins the S1 delegation contract: the legacy public symbol exported
        // from `colonial_pressure.dart` must mirror the canonical helper for
        // every relevant fixture so removing the stub in a future slice
        // cannot silently shift the same-turn declare-war suppression
        // boundary in `diplomatic_candidate_scoring_declare_war.dart`.
        const priorOrders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp2': [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp4',
              ),
            ],
            'gp3': [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp4',
              ),
            ],
          },
        );
        final fixtures = <(Orders?, String, String, bool, String)>[
          (null, 'gp2', 'gp4', false, 'null bag short-circuits to false'),
          (priorOrders, 'gp2', 'gp4', true, 'declareWar matches target'),
          (
            priorOrders,
            'gp2',
            'gp5',
            false,
            'declareWar targets a different faction',
          ),
          (
            priorOrders,
            'gp3',
            'gp4',
            false,
            'order type is offerPeace, not declareWar',
          ),
          (
            priorOrders,
            'gp1',
            'gp4',
            false,
            'declarer has no orders in the bag',
          ),
        ];
        for (final (sameTurn, declarer, target, expected, label) in fixtures) {
          final canonical = pendingDeclareWarFrom(
            sameTurnPriorDiplomaticOrders: sameTurn,
            declarerFactionId: declarer,
            targetFactionId: target,
          );
          final delegated = colonial_pressure.pendingDeclareWarFrom(
            sameTurnPriorDiplomaticOrders: sameTurn,
            declarerFactionId: declarer,
            targetFactionId: target,
          );
          expect(
            delegated,
            canonical,
            reason:
                '`colonial_pressure.pendingDeclareWarFrom` is a thin '
                'delegating stub for legacy callers; it must mirror the '
                'canonical helper exactly so the '
                'diplomatic_candidate_scoring_declare_war.dart same-turn '
                'suppression gate stays consistent (fixture: $label).',
          );
          expect(
            canonical,
            expected,
            reason: 'Canonical helper truth check (fixture: $label).',
          );
        }
      },
    );
  });
}
