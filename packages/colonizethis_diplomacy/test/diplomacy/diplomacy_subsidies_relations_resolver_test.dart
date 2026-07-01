import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomacy_game_fixtures.dart';

void main() {
  group('applyRelationModifiersAndUpdateScores', () {
    test('GrantAid deducts payer treasury using stable player row index', () {
      const startTreasury = 5000;
      final game = gpMinorEmbassySubsidyGame(
        turnNumber: 1,
        gp1Treasury: startTreasury,
        includeSubsidy: false,
        includeDiplomaticExpertiseTech: true,
      );
      final after = applyRelationModifiersAndUpdateScores(
        game,
        {
          'gp1': [
            const DiplomaticOrder(
              type: DiplomaticOrderType.grantAid,
              targetFactionId: 'minor1',
              amount: 1000,
            ),
          ],
        },
        1,
      );
      expect(after.playerById('gp1')!.treasury, startTreasury - 1000);
    });
  });

  group('processOngoingSubsidies (percent model, Refs #3753 R3)', () {
    const embassy = OvertureState(
      gpId: 'gp1',
      targetId: 'minor1',
      stage: OvertureStage.embassy,
      sinceTurn: 0,
    );

    test('subsidy is retained at peace with an Embassy and charges no treasury',
        () {
      final game = gpMinorEmbassySubsidyGame(
        relationState: RelationState.atPeace,
        overtureStates: const [embassy],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final after = processOngoingSubsidies(game, 2,
          factionMembership: membership);
      expect(after.subsidyStates.length, 1);
      expect(after.subsidyStates.single.percent, 10);
      expect(after.playerById('gp1')!.treasury, 10_000);
    });

    test('subsidy is cleared when the payer loses the Embassy (R3.5)', () {
      final game = gpMinorEmbassySubsidyGame(
        relationState: RelationState.atPeace,
        overtureStates: const [],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final after = processOngoingSubsidies(game, 2,
          factionMembership: membership);
      expect(after.subsidyStates, isEmpty);
    });

    test('subsidy is cleared when the pair is at war', () {
      final game = gpMinorEmbassySubsidyGame(
        relationState: RelationState.atWar,
        overtureStates: const [embassy],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final after = processOngoingSubsidies(game, 2,
          factionMembership: membership);
      expect(after.subsidyStates, isEmpty);
    });
  });
}
