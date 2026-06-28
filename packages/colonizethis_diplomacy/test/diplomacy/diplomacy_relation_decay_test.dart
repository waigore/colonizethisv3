import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Per-turn relation decay (Refs #3753 R9.3/R9.4): non-war pairs with no
/// relation-score delta event this turn drift ±4 toward equilibrium 50, clamped
/// so they never cross 50; event-modified pairs (and pairs created this turn) and
/// AT_WAR pairs are skipped. SPEC/game/diplomacy.md § Relation Model.
Game _gameWith(List<DiplomacyRelation> relations) => Game(
  id: 'decay-test',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: const [
    Player(id: 'gp1', displayName: 'GP1', isHuman: false),
    Player(id: 'gp2', displayName: 'GP2', isHuman: false),
  ],
  diplomacyRelations: relations,
);

DiplomacyRelation _rel(
  num score, {
  RelationState state = RelationState.atPeace,
}) => DiplomacyRelation(
  factionId1: 'gp1',
  factionId2: 'gp2',
  score: score,
  level: scoreToLevel(score),
  state: state,
);

num _decayedScore(DiplomacyRelation rel) {
  final game = _gameWith([rel]);
  final snapshot = snapshotRelationScores(game);
  final after = applyRelationDecay(game, 5, snapshot);
  return getRelation(after, 'gp1', 'gp2')!.score;
}

void main() {
  group('applyRelationDecay (Refs #3753 R9.3/R9.4)', () {
    test('positive: below 50 drifts +4 toward equilibrium', () {
      expect(_decayedScore(_rel(40)), 44.0);
    });

    test('positive: above 50 drifts -4 toward equilibrium', () {
      expect(_decayedScore(_rel(80)), 76.0);
    });

    test('positive: below-50 step clamps to 50 (does not cross)', () {
      expect(_decayedScore(_rel(48)), 50.0);
    });

    test('positive: above-50 step clamps to 50 (does not cross)', () {
      expect(_decayedScore(_rel(52)), 50.0);
    });

    test('negative: a pair already at 50 is unchanged', () {
      expect(_decayedScore(_rel(50)), 50);
    });

    test('negative: AT_WAR pairs keep frozen scores (no decay)', () {
      expect(_decayedScore(_rel(30, state: RelationState.atWar)), 30);
    });

    test('positive: fractional score drifts +4 (decimal preserved)', () {
      expect(_decayedScore(_rel(45.5)), 49.5);
    });

    test(
      'negative: skip-on-event — score changed vs phase-start snapshot is not decayed',
      () {
        // Snapshot captures score 40 at phase start; an event then moved it to
        // 35 this turn, so decay must skip the pair (stays 35, not 39).
        final start = _gameWith([_rel(40)]);
        final snapshot = snapshotRelationScores(start);
        final modified = _gameWith([_rel(35)]);
        final after = applyRelationDecay(modified, 5, snapshot);
        expect(getRelation(after, 'gp1', 'gp2')!.score, 35);
      },
    );

    test(
      'negative: a pair created this turn (absent from snapshot) is not decayed',
      () {
        final created = _gameWith([_rel(40)]);
        final after = applyRelationDecay(created, 5, const {});
        expect(getRelation(after, 'gp1', 'gp2')!.score, 40);
      },
    );
  });

  group('resolveDiplomacyPhase per-turn decay integration', () {
    test(
      'positive: a non-war pair with no event this turn decays -4 toward 50',
      () {
        final game = _gameWith([_rel(80)]);
        final after = resolveDiplomacyPhase(game, const Orders()).game;
        expect(getRelation(after, 'gp1', 'gp2')!.score, 76.0);
      },
    );

    test(
      'negative: a pair receiving a Grant Aid event this turn skips decay',
      () {
        // gp1 grants aid to gp2 (requires an embassy overture); the relation
        // pair is event-modified, so per-turn decay must not also apply.
        final game = _gameWith([_rel(80)]).copyWith(
          players: [
            const Player(
              id: 'gp1',
              displayName: 'GP1',
              isHuman: false,
              treasury: 5000,
            ),
            const Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'gp2',
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final orders = const Orders(
          diplomaticOrdersByPlayerId: {
            'gp1': [
              DiplomaticOrder(
                type: DiplomaticOrderType.grantAid,
                targetFactionId: 'gp2',
                amount: 1000,
              ),
            ],
          },
        );
        final after = resolveDiplomacyPhase(game, orders).game;
        // Grant Aid adds +5 (80 → 85); decay is skipped for the event-modified
        // pair, so the score is not pulled back toward 50.
        final score = getRelation(after, 'gp1', 'gp2')!.score;
        expect(score, greaterThan(80));
        expect(score, isNot(76.0));
      },
    );
  });
}
