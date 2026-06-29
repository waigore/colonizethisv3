import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/diplomacy_resolver_phase_test_support.dart';

void main() {
  group('resolveDiplomacyPhase part2', () {
    test('returns game when there are no diplomatic orders', () {
      final game = diplomacyResolverPhaseTestBaseGame();
      final result = resolveDiplomacyPhase(game, const Orders());
      expect(result.game.id, game.id);
    });

    test('setSubsidy at resolution with invalid percent is skipped, not thrown '
        '(Refs #3753 R3)', () {
      var game = diplomacyResolverPhaseTestBaseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      game = game.copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            // 7 is not a multiple of 5; the resolver silently skips it.
            DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 7,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.subsidyStates, isEmpty);
    });

    test('setSubsidy at resolution with valid percent records SubsidyState '
        '(Refs #3753 R3)', () {
      var game = diplomacyResolverPhaseTestBaseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      game = game.copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 10,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.subsidyStates, hasLength(1));
      expect(after.subsidyStates.single.percent, 10);
      expect(after.subsidyStates.single.targetId, 'minor1');
    });
  });
}
