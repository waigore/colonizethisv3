import 'package:colonizethis_logic/src/diplomacy/diplomacy_subsidies_relations_resolver.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

void main() {
  group('terminateAgreementsOnWar', () {
    test('removes overtures for factions at war and logs agreements cleared', () {
      final game = TestFixtures.minimalGame(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'm1',
            state: RelationState.atWar,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'm1',
            stage: OvertureStage.embassy,
          ),
          OvertureState(
            gpId: 'gp1',
            targetId: 'm2',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );

      final after = terminateAgreementsOnWar(game);

      expect(after.overtureStates, const [
        OvertureState(
          gpId: 'gp1',
          targetId: 'm2',
          stage: OvertureStage.tradeConsulate,
        ),
      ]);
      expect(after.diplomaticHistoryEvents, isNotEmpty);
      final last = after.diplomaticHistoryEvents.last;
      expect(last.type, DiplomaticEventType.agreementsClearedOnWar);
      expect(last.participants, {'gp1', 'm1'});
      expect(last.reason, 'war');
    });

    test('leaves overtures unchanged when no relation is at war', () {
      final overtures = const [
        OvertureState(
          gpId: 'gp1',
          targetId: 'm1',
          stage: OvertureStage.embassy,
        ),
      ];
      final game = TestFixtures.minimalGame(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'm1',
            state: RelationState.atPeace,
          ),
        ],
        overtureStates: overtures,
      );

      final after = terminateAgreementsOnWar(game);

      expect(after.overtureStates, overtures);
      expect(after.diplomaticHistoryEvents, isEmpty);
    });
  });
}
