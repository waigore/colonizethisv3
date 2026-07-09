// Compact diplomatic-pass suggestion assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/incremental_candidate_validator.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_diplomatic_pass.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/diplomatic_sub_validator.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../diplomatic/diplomatic_orders_test_fixtures.dart';
import 'order_suggestion_diplomatic_pass_fixtures.dart';

/// Pins for [orderSuggestionDiplomaticPassScenarios] rows.
enum OrderSuggestionDiplomaticPassTarget {
  isIndependentDiplomaticCandidateFlagsEconomicAndBoycottTypes,
  playerOverturesByTargetIdForPlayerKeepsFirstRowPerTarget,
  acceptDeclareWarCandidatesForTargetsSkipsSelfAndAtWarTargets,
}

void runOrderSuggestionDiplomaticPassExpectation(
  OrderSuggestionDiplomaticPassTarget target,
) {
  switch (target) {
    case OrderSuggestionDiplomaticPassTarget
        .isIndependentDiplomaticCandidateFlagsEconomicAndBoycottTypes:
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.grantAid),
        isTrue,
      );
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.setSubsidy),
        isTrue,
      );
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.boycott),
        isTrue,
      );
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.alliance),
        isFalse,
      );
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.declareWar),
        isFalse,
      );

    case OrderSuggestionDiplomaticPassTarget
        .playerOverturesByTargetIdForPlayerKeepsFirstRowPerTarget:
      final game = orderSuggestionDiplomaticPassDuplicateOvertureGame();
      final map = playerOverturesByTargetIdForPlayer(game, 'gp1');
      expect(map.keys, ['minor1']);
      expect(map['minor1']!.stage, OvertureStage.tradeConsulate);

    case OrderSuggestionDiplomaticPassTarget
        .acceptDeclareWarCandidatesForTargetsSkipsSelfAndAtWarTargets:
      final atPeaceGame = gpMinorGame(
        includeProvinces: true,
        relationState: RelationState.atPeace,
      );
      final atWarGame = gpMinorGame(
        includeProvinces: true,
        relationState: RelationState.atWar,
      );
      final suggestions = <DiplomaticOrder>[];

      void runPass(Game game) {
        final topology = emptyTopology;
        final inputs = DiplomaticSuggestionPassInputs(
          subValidatorContext: DiplomaticSubValidatorContext(
            game: game,
            playerId: 'gp1',
          ),
          knownTargetIds: {'minor1'},
          knownFactionIds: {'minor1'},
          playerOverturesByTargetId: const {},
          playerHoldsColony: false,
          player: game.players.first,
        );
        acceptDeclareWarCandidatesForTargets(
          sortedTargetIds: ['gp1', 'minor1'],
          playerId: 'gp1',
          inputs: inputs,
          state: DiplomaticSuggestionPassState(
            workingOrders: const Orders(),
            passValidator: IncrementalCandidateValidator.forPlayer(
              game: game,
              topology: topology,
              playerId: 'gp1',
              basePrefix: const Orders(),
            ),
            suggestions: suggestions,
          ),
        );
      }

      runPass(atPeaceGame);
      expect(suggestions.map((o) => o.targetFactionId), isNot(contains('gp1')));
      expect(suggestions, isNotEmpty);
      for (final order in suggestions) {
        expect(order.type, DiplomaticOrderType.declareWar);
      }

      suggestions.clear();
      runPass(atWarGame);
      expect(suggestions, isEmpty);
  }
}
