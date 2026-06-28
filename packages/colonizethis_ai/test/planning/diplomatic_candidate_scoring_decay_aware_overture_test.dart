import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  // Decay-aware improve-relations discount on `establishOverture` scoring
  // (Refs #3758 S8; #3753 R9.3/R9.4). Per-turn relation decay drifts a
  // below-neutral peace pair +relationDecayPerTurn (4.0) toward equilibrium 50
  // on its own unless a same-turn relation event blocks decay, so the AI
  // discounts the urgency of spending an overture decay would render moot.
  // SPEC/ai/phase-planner-architecture.md § Decay-aware overture.
  group('computeDiplomaticCandidateScores establishOverture decay-aware', () {
    // Minimal symmetric two-GP world: both own one Old World province so the
    // power basis (and therefore the war-desire base) is identical regardless
    // of the relation score under test, isolating the decay discount.
    Game gameWithRelation({
      required num score,
      RelationState state = RelationState.atPeace,
    }) => Game(
      id: 'g-decay-overture',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'A', isHuman: false),
        Player(id: 'gp2', displayName: 'B', isHuman: false),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: score,
          level: scoreToLevel(score),
          state: state,
        ),
      ],
    );

    const overtureCandidate = [
      DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'gp2',
        overtureStage: OvertureStage.tradeConsulate,
      ),
    ];

    // A prior diplomatic order from the target (gp2) directed back at the AI
    // (gp1) lands a same-turn relation event on the shared pair, which blocks
    // decay and therefore suppresses the discount.
    Orders priorEventFromTargetToSelf() => const Orders(
      diplomaticOrdersByPlayerId: {
        'gp2': [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp1',
          ),
        ],
      },
    );

    int overtureScore({
      required num score,
      RelationState state = RelationState.atPeace,
      Orders? sameTurnPriorDiplomaticOrders,
    }) {
      final game = gameWithRelation(score: score, state: state);
      const topology = MapTopology(nodes: [], edges: []);
      final snapshot = AIWorldSnapshot.fromPlayerView(
        buildPlayerView(game, topology, 'gp1'),
      );
      // `frederick` carries a neutral allianceTendency (50), so the
      // alliance-tendency term contributes 0 and the score difference between
      // cases is attributable to the decay discount alone.
      const config = AIConfig(
        leaderId: 'frederick',
        personalityId: 'frederick',
        hiddenAgendaId: 'merchant',
      );
      return computeDiplomaticCandidateScores(
        candidates: overtureCandidate,
        nationId: 'gp1',
        game: game,
        snapshot: snapshot,
        config: config,
        sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
      ).single;
    }

    test('below-neutral peace pair is discounted vs an event-blocked pair', () {
      // score 48 -> decay (+4 clamped to 50) reaches equilibrium next turn, so
      // the full kEstablishOvertureDecayCreditMax discount applies; the same
      // pair with a scheduled event keeps the undiscounted urgency.
      expect(
        overtureScore(score: 48),
        lessThan(
          overtureScore(
            score: 48,
            sameTurnPriorDiplomaticOrders: priorEventFromTargetToSelf(),
          ),
        ),
      );
    });

    test('full decay discount equals kEstablishOvertureDecayCreditMax', () {
      // gap = 50 - 48 = 2; decayCovered = min(4.0, 2.0) = 2.0; reduction =
      // round(2.0 / 2.0 * 20) = 20. The event-blocked score is the
      // undiscounted baseline, so the gap between them is exactly the max.
      final discounted = overtureScore(score: 48);
      final undiscounted = overtureScore(
        score: 48,
        sameTurnPriorDiplomaticOrders: priorEventFromTargetToSelf(),
      );
      expect(undiscounted - discounted, kEstablishOvertureDecayCreditMax);
    });

    test('discount scales down for a deeply hostile pair', () {
      // war-desire base is identical for scores 30 and 48 (both in the
      // (25, 50) band, no relation modifier), so the score difference is the
      // discount difference: 48 -> -20, 30 -> round(4/20*20) = -4. The smaller
      // discount leaves the deeply hostile pair with the higher overture score.
      expect(overtureScore(score: 30), greaterThan(overtureScore(score: 48)));
    });

    test('scheduled same-turn event suppresses the discount entirely', () {
      // With the event predictor firing, the discounted and event-blocked
      // scores coincide (no discount applied at all).
      expect(
        overtureScore(
          score: 30,
          sameTurnPriorDiplomaticOrders: priorEventFromTargetToSelf(),
        ),
        overtureScore(
          score: 48,
          sameTurnPriorDiplomaticOrders: priorEventFromTargetToSelf(),
        ),
      );
    });

    test('above-neutral pair is never decay-discounted', () {
      // score 60 is above equilibrium; decay drifts it down (not improving
      // relations), so the discount must not apply and a scheduled event makes
      // no difference to the score.
      expect(
        overtureScore(score: 60),
        overtureScore(
          score: 60,
          sameTurnPriorDiplomaticOrders: priorEventFromTargetToSelf(),
        ),
      );
    });
  });
}
