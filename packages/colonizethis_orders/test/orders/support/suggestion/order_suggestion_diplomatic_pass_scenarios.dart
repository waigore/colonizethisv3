// Table-driven diplomatic-pass suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/incremental_candidate_validator.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_diplomatic_pass.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/diplomatic_sub_validator.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import '../diplomatic/diplomatic_orders_test_fixtures.dart';
import 'order_suggestion_diplomatic_pass_fixtures.dart';

void osdpRunIsIndependentDiplomaticCandidateFlagsEconomicAndBoycottTypes() {
  expect(
    isIndependentDiplomaticCandidate(DiplomaticOrderType.grantAid),
    isTrue,
  );
  expect(
    isIndependentDiplomaticCandidate(DiplomaticOrderType.setSubsidy),
    isTrue,
  );
  expect(isIndependentDiplomaticCandidate(DiplomaticOrderType.boycott), isTrue);
  expect(
    isIndependentDiplomaticCandidate(DiplomaticOrderType.alliance),
    isFalse,
  );
  expect(
    isIndependentDiplomaticCandidate(DiplomaticOrderType.declareWar),
    isFalse,
  );
}

void osdpRunPlayerOverturesByTargetIdForPlayerKeepsFirstRowPerTarget() {
  final game = orderSuggestionDiplomaticPassDuplicateOvertureGame();
  final map = playerOverturesByTargetIdForPlayer(game, 'gp1');
  expect(map.keys, ['minor1']);
  expect(map['minor1']!.stage, OvertureStage.tradeConsulate);
}

void osdpRunAcceptDeclareWarCandidatesForTargetsSkipsSelfAndAtWarTargets() {
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

List<RunnableScenario> orderSuggestionDiplomaticPassScenarios() => const [
  RunnableScenario(
    label: 'isIndependentDiplomaticCandidate flags economic and boycott types',
    run: osdpRunIsIndependentDiplomaticCandidateFlagsEconomicAndBoycottTypes,
  ),
  RunnableScenario(
    label: 'playerOverturesByTargetIdForPlayer keeps first row per target',
    run: osdpRunPlayerOverturesByTargetIdForPlayerKeepsFirstRowPerTarget,
  ),
  RunnableScenario(
    label: 'acceptDeclareWarCandidatesForTargets skips self and at-war targets',
    run: osdpRunAcceptDeclareWarCandidatesForTargetsSkipsSelfAndAtWarTargets,
  ),
];
