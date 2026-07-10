// Table-driven prospect location province priority scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_prospect_location_province_priority_fixtures.dart';

void osplppRunCoLocatedExplorerReceivesProspectInLateSortedProvince() {
  final game = orderSuggestionProspectLocationProvincePriorityGame();
  final topology = orderSuggestionProspectLocationProvincePriorityTopology(
    game,
  );
  final view = buildPlayerView(
    game,
    topology,
    orderSuggestionProspectLocationProvincePriorityPlayerId,
  );
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  final prospects = suggestions
      .where(
        (o) =>
            o.unitId ==
                orderSuggestionProspectLocationProvincePriorityExplorerUnitId &&
            o.target == kWorkTargetProspect,
      )
      .toList();
  expect(prospects, isNotEmpty);
  expect(
    prospects.map((o) => o.targetTileKey),
    contains(orderSuggestionProspectLocationProvincePriorityIronTileKey),
  );
}

void osplppRunNoProspectWithoutFoggedVisibility() {
  final game = orderSuggestionProspectLocationProvincePriorityGame(
    includeFoggedVisibility: false,
  );
  final topology = orderSuggestionProspectLocationProvincePriorityTopology(
    game,
  );
  final view = buildPlayerView(
    game,
    topology,
    orderSuggestionProspectLocationProvincePriorityPlayerId,
  );
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(suggestions.where((o) => o.target == kWorkTargetProspect), isEmpty);
}

/// Scenarios for suggestWorkOrders prospect location province priority.
List<RunnableScenario>
suggestWorkOrdersProspectLocationProvincePriorityScenarios() => const [
  RunnableScenario(
    label:
        'co-located Explorer in late-sorted province still receives a prospect suggestion for its iron tile',
    run: osplppRunCoLocatedExplorerReceivesProspectInLateSortedProvince,
    refs: '#2847',
  ),
  RunnableScenario(
    label:
        'iron province without fogged visibility still yields no prospect (negative control)',
    run: osplppRunNoProspectWithoutFoggedVisibility,
    refs: '#2847',
  ),
];
