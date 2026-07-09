// Intervention-risk declare-war assertions (Refs #2509, #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';
import 'order_suggestion_declare_war_intervention_risk_fixtures.dart';

/// Pins for [orderSuggestionDeclareWarInterventionRiskScenarios] rows.
enum OrderSuggestionDeclareWarInterventionRiskTarget {
  tribeStaysInCandidates,
  deterministicAcrossRepeatedCalls,
}

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

void runOrderSuggestionDeclareWarInterventionRiskExpectation(
  OrderSuggestionDeclareWarInterventionRiskTarget target,
) {
  switch (target) {
    case OrderSuggestionDeclareWarInterventionRiskTarget.tribeStaysInCandidates:
      final game = interventionRiskDeclareWarScenarioGame();
      final view = interventionRiskViewFor(game);
      expect(
        knownDiplomaticTargetFactionIds(
          view: view,
          game: game,
          topology: colonialAcquisitionTopology,
        ),
        contains('tribe1'),
      );
      final declareOnly = _api.suggestDeclareWarOrders(
        view,
        game,
        colonialAcquisitionTopology,
        _emptyOrders,
      );
      expect(
        declareOnly.any(
          (o) =>
              o.targetFactionId == 'tribe1' &&
              o.type == DiplomaticOrderType.declareWar,
        ),
        isTrue,
        reason:
            'tribe declare-war candidate must remain in the set even when '
            'intervention risk (GP embassies on the tribe) would discourage '
            'the war via war-desire scoring',
      );

    case OrderSuggestionDeclareWarInterventionRiskTarget
        .deterministicAcrossRepeatedCalls:
      final game = interventionRiskDeclareWarScenarioGame(
        gameId: 'g-intervention-risk-deterministic',
      );
      final view = interventionRiskViewFor(game);
      final first = _api.suggestDeclareWarOrders(
        view,
        game,
        colonialAcquisitionTopology,
        _emptyOrders,
      );
      final second = _api.suggestDeclareWarOrders(
        view,
        game,
        colonialAcquisitionTopology,
        _emptyOrders,
      );
      final firstTargetIds =
          first.map(interventionRiskDeclareWarOrderKey).toList();
      final secondTargetIds =
          second.map(interventionRiskDeclareWarOrderKey).toList();
      expect(secondTargetIds, equals(firstTargetIds));
      expect(
        firstTargetIds,
        contains('declareWar:tribe1'),
        reason:
            'deterministic candidate set must include the tribe target '
            'despite high intervention risk; pins the AC determinism clause',
      );
  }
}
