import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomacy_game_fixtures.dart';

/// Additive trade-deal relation boost (Refs #3753 R10): a faction pair that
/// completed a Great-Power world-market trade deal the previous turn (recorded
/// on `WorldMarketState.completedTradePairKeys`) gains +2.0 (plus +0.4 with an
/// Embassy) in the next Diplomacy phase, before decay, so the pair skips that
/// turn's decay. SPEC/game/diplomacy.md § Relation Model — Trade-deal relation
/// boost.
Game _tradeBoostGame({
  required num score,
  RelationState state = RelationState.atPeace,
  Set<String> completedTradePairKeys = const <String>{},
  List<OvertureState> overtureStates = const <OvertureState>[],
}) =>
    diplomacyGame(
      id: 'trade-boost-test',
      turnNumber: 7,
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: score,
          level: scoreToLevel(score),
          state: state,
        ),
      ],
      overtureStates: overtureStates,
      worldMarketState: WorldMarketState(
        completedTradePairKeys: completedTradePairKeys,
      ),
    );

void main() {
  group('applyTradeDealRelationBoosts (Refs #3753 R10)', () {
    test('positive: traded pair without embassy gains +2.0', () {
      final game = _tradeBoostGame(
        score: 50,
        completedTradePairKeys: const {'gp1|gp2'},
      );
      final after = applyTradeDealRelationBoosts(game, 7);
      expect(getRelation(after, 'gp1', 'gp2')!.score, 52.0);
    });

    test('positive: traded pair with embassy gains +2.4', () {
      final game = _tradeBoostGame(
        score: 50,
        completedTradePairKeys: const {'gp1|gp2'},
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.embassy,
          ),
        ],
      );
      final after = applyTradeDealRelationBoosts(game, 7);
      expect(getRelation(after, 'gp1', 'gp2')!.score, 52.4);
    });

    test('positive: boosted score clamps to 100', () {
      final game = _tradeBoostGame(
        score: 99,
        completedTradePairKeys: const {'gp1|gp2'},
      );
      final after = applyTradeDealRelationBoosts(game, 7);
      expect(getRelation(after, 'gp1', 'gp2')!.score, 100.0);
    });

    test('negative: pair with no completed trade deal is unchanged', () {
      final game = _tradeBoostGame(score: 50);
      final after = applyTradeDealRelationBoosts(game, 7);
      expect(getRelation(after, 'gp1', 'gp2')!.score, 50);
    });

    test('negative: AT_WAR pair is not boosted (war scores frozen)', () {
      final game = _tradeBoostGame(
        score: 30,
        state: RelationState.atWar,
        completedTradePairKeys: const {'gp1|gp2'},
      );
      final after = applyTradeDealRelationBoosts(game, 7);
      expect(getRelation(after, 'gp1', 'gp2')!.score, 30);
    });
  });

  group('resolveDiplomacyPhase trade-deal boost integration', () {
    test(
      'positive: a pair that traded last turn is boosted and skips decay',
      () {
        // Score 80 would decay to 76 if untouched; instead the pair traded so
        // decay is skipped and +2.0 applied -> 82.0.
        final game = _tradeBoostGame(
          score: 80,
          completedTradePairKeys: const {'gp1|gp2'},
        );
        final after = resolveDiplomacyPhase(game, const Orders()).game;
        expect(getRelation(after, 'gp1', 'gp2')!.score, 82.0);
      },
    );

    test(
      'negative: a pair with no trade deal still decays toward 50',
      () {
        final game = _tradeBoostGame(score: 80);
        final after = resolveDiplomacyPhase(game, const Orders()).game;
        expect(getRelation(after, 'gp1', 'gp2')!.score, 76.0);
      },
    );
  });
}
