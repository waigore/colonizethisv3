import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import '../support/diplomacy_game_fixtures.dart';

void main() {
  group('applyGpGpWarOvertureRules (Refs #3753 S3)', () {
    test('preserves embassy-tier overtures between warring GPs', () {
      final game = twoGpGpWarOvertureGame(
        relationState: RelationState.atWar,
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
          OvertureState(
            gpId: 'gp2',
            targetId: 'gp1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );

      final result = applyGpGpWarOvertureRules(game, 'gp1', 'gp2');

      expect(result.changed, isEmpty);
      expect(getOverture(result.game, 'gp1', 'gp2')!.stage, OvertureStage.embassy);
      expect(getOverture(result.game, 'gp2', 'gp1')!.stage, OvertureStage.embassy);
    });

    test('downgrades NAP to embassy and records change', () {
      final game = twoGpGpWarOvertureGame(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.nap,
            sinceTurn: 3,
          ),
          OvertureState(
            gpId: 'gp2',
            targetId: 'gp1',
            stage: OvertureStage.nap,
            sinceTurn: 3,
          ),
        ],
        relationState: RelationState.atWar,
      );

      final result = applyGpGpWarOvertureRules(game, 'gp1', 'gp2');

      expect(result.changed, hasLength(2));
      expect(getOverture(result.game, 'gp1', 'gp2')!.stage, OvertureStage.embassy);
      expect(getOverture(result.game, 'gp2', 'gp1')!.stage, OvertureStage.embassy);
    });

    test('removes consulate-tier GP–GP overtures on war', () {
      final game = twoGpGpWarOvertureGame(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
        relationState: RelationState.atWar,
      );

      final result = applyGpGpWarOvertureRules(game, 'gp1', 'gp2');

      expect(result.changed, hasLength(1));
      expect(getOverture(result.game, 'gp1', 'gp2'), isNull);
    });
  });

  group('terminateAgreementsOnWar GP–GP (Refs #3753 S3)', () {
    test('embassy survives war; NAP cleared via downgrade', () {
      final game = twoGpGpWarOvertureGame(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.nap,
            sinceTurn: 5,
          ),
          OvertureState(
            gpId: 'gp2',
            targetId: 'gp1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
        relationState: RelationState.atWar,
      );

      final after = terminateAgreementsOnWar(game);

      expect(getOverture(after, 'gp1', 'gp2')!.stage, OvertureStage.embassy);
      expect(getOverture(after, 'gp2', 'gp1')!.stage, OvertureStage.embassy);
      expect(
        after.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.agreementsClearedOnWar)
            .length,
        1,
      );
    });

    test('GP–Minor war still clears all overtures', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 20,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
          ),
        ],
      );

      final after = terminateAgreementsOnWar(game);

      expect(getOverture(after, 'gp1', 'minor1'), isNull);
    });
  });

  group('resolveDiplomacyPhase GP–GP war then peace (Refs #3753 S3)', () {
    test('embassy persists through declare war and offer peace', () {
      var game = twoGpGpWarOvertureGame(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
          OvertureState(
            gpId: 'gp2',
            targetId: 'gp1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );

      game = resolveDiplomacyPhase(
        game,
        Orders(
          diplomaticOrdersByPlayerId: {
            'gp1': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp2',
              ),
            ],
          },
        ),
      ).game;

      expect(getRelation(game, 'gp1', 'gp2')!.atWar, isTrue);
      expect(getOverture(game, 'gp1', 'gp2')!.hasEmbassy, isTrue);
      expect(getOverture(game, 'gp2', 'gp1')!.hasEmbassy, isTrue);

      game = resolveDiplomacyPhase(
        game,
        Orders(
          diplomaticOrdersByPlayerId: {
            'gp1': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp2',
              ),
            ],
            'gp2': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp1',
              ),
            ],
          },
        ),
      ).game;

      expect(getRelation(game, 'gp1', 'gp2')!.atPeace, isTrue);
      expect(getOverture(game, 'gp1', 'gp2')!.stage, OvertureStage.embassy);
      expect(getOverture(game, 'gp2', 'gp1')!.stage, OvertureStage.embassy);
      expect(getOverture(game, 'gp1', 'gp2')!.sinceTurn, 0);
    });
  });
}
