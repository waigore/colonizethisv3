import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Composed end-to-end Diplomacy-phase integration (Refs #3753 S17): verifies
/// the interaction between the unified alliance-break ripple (R11) and the
/// final per-turn relation decay step (R9.3/R9.4 skip-on-event) when both run
/// inside a single `resolveDiplomacyPhase`.
///
/// The isolated `break_alliance_resolver_test.dart` exercises
/// `processBreakAlliances` directly and the isolated decay test exercises
/// `applyRelationDecay`; neither proves that every pair the break penalty
/// touched is treated as event-modified (and therefore skipped) by the decay
/// step that runs later in the same phase, while an uninvolved pair still
/// decays toward equilibrium 50. SPEC/game/diplomacy.md § Alliances /
/// § Relation Model; SPEC/program/diplomacy-resolution.md.
Game _fourGpGame({
  required num gp1gp2Score,
  required num gp1gp3Score,
  required num gp1gp4Score,
  required num gp2gp3Score,
}) {
  DiplomacyRelation rel(
    String a,
    String b,
    num score, {
    bool formalAlliance = false,
  }) {
    final ids = canonicalPairIds(a, b);
    return DiplomacyRelation(
      factionId1: ids.id1,
      factionId2: ids.id2,
      score: score,
      level: scoreToLevel(score),
      state: RelationState.atPeace,
      sinceTurn: 0,
      lastInteractionTurn: 0,
      formalAlliance: formalAlliance,
    );
  }

  return Game(
    id: 'g-break-decay',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
      Player(id: 'gp3', displayName: 'GP3', isHuman: false),
      Player(id: 'gp4', displayName: 'GP4', isHuman: false),
    ],
    diplomacyRelations: [
      rel('gp1', 'gp2', gp1gp2Score, formalAlliance: true),
      rel('gp1', 'gp3', gp1gp3Score),
      rel('gp1', 'gp4', gp1gp4Score),
      // Control pair: does not involve the breaker (gp1), so it receives no
      // alliance-break event and must still decay toward 50.
      rel('gp2', 'gp3', gp2gp3Score),
    ],
  );
}

Orders _breakOrders(String gpId, String targetId) => Orders(
  diplomaticOrdersByPlayerId: {
    gpId: [
      DiplomaticOrder(
        type: DiplomaticOrderType.breakAlliance,
        targetFactionId: targetId,
      ),
    ],
  },
);

void main() {
  group(
    'resolveDiplomacyPhase: alliance break ripple x decay skip-on-event '
    '(Refs #3753 S17)',
    () {
      test(
        'positive: a pair uninvolved in the break still decays toward 50',
        () {
          // gp2-gp3 (80) is untouched by gp1 breaking with gp2, so the final
          // decay step pulls it -4 toward equilibrium 50.
          final game = _fourGpGame(
            gp1gp2Score: 80,
            gp1gp3Score: 80,
            gp1gp4Score: 80,
            gp2gp3Score: 80,
          );
          final after = resolveDiplomacyPhase(game, _breakOrders('gp1', 'gp2'))
              .game;
          expect(getRelation(after, 'gp2', 'gp3')!.score, 76.0);
        },
      );

      test(
        'negative: every pair the break penalty modified is skipped by decay',
        () {
          final game = _fourGpGame(
            gp1gp2Score: 80,
            gp1gp3Score: 80,
            gp1gp4Score: 80,
            gp2gp3Score: 80,
          );
          final after = resolveDiplomacyPhase(game, _breakOrders('gp1', 'gp2'))
              .game;

          // Broken-with ally: 80 - 50 = 30, flag cleared. Decay would move an
          // unmodified 30 to 34; skip-on-event must leave it at exactly 30.
          final ally = getRelation(after, 'gp1', 'gp2')!;
          expect(ally.formalAlliance, isFalse);
          expect(ally.score, 30.0);

          // Every other related GP: 80 - 10 = 70. Decay would move an
          // unmodified 70 to 66; skip-on-event must leave each at exactly 70.
          expect(getRelation(after, 'gp1', 'gp3')!.score, 70.0);
          expect(getRelation(after, 'gp1', 'gp4')!.score, 70.0);
        },
      );

      test('positive: exactly one allianceBroken event is recorded', () {
        final game = _fourGpGame(
          gp1gp2Score: 80,
          gp1gp3Score: 80,
          gp1gp4Score: 80,
          gp2gp3Score: 80,
        );
        final after = resolveDiplomacyPhase(game, _breakOrders('gp1', 'gp2'))
            .game;
        final broken = after.diplomaticHistoryEvents.where(
          (e) =>
              e.type == DiplomaticEventType.allianceBroken &&
              e.participants.contains('gp1') &&
              e.participants.contains('gp2'),
        );
        expect(broken.length, 1);
      });

      test(
        'negative: no break order leaves the formal alliance and decays all '
        'non-equilibrium pairs',
        () {
          // Without a breakAlliance order the alliance survives and, with no
          // events at all, every non-war pair off equilibrium decays -4.
          final game = _fourGpGame(
            gp1gp2Score: 80,
            gp1gp3Score: 80,
            gp1gp4Score: 80,
            gp2gp3Score: 80,
          );
          final after = resolveDiplomacyPhase(game, const Orders()).game;
          expect(getRelation(after, 'gp1', 'gp2')!.formalAlliance, isTrue);
          expect(getRelation(after, 'gp1', 'gp2')!.score, 76.0);
          expect(getRelation(after, 'gp1', 'gp3')!.score, 76.0);
          expect(getRelation(after, 'gp2', 'gp3')!.score, 76.0);
        },
      );
    },
  );
}
