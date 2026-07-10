// Table-driven own-province prospect budget priority scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_prospect_own_province_budget_priority_fixtures.dart';
// dart format off

void ospobpRunCoLocatedFeedstockReceivesProspectAfterBudgetDrain() {final game = orderSuggestionProspectOwnProvinceBudgetPriorityGame(); final topology = orderSuggestionProspectOwnProvinceBudgetPriorityTopology(game,); final view = buildPlayerView(game,topology,orderSuggestionProspectOwnProvinceBudgetPriorityPlayerId,); final suggestions = suggestWorkOrders(view,game,topology,const Orders()); final prospects = orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockProspects(suggestions,); expect(prospects,isNotEmpty); expect(prospects.map((o) => o.targetTileKey),contains(orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockTileKey),);}

void ospobpRunNoFeedstockProspectWhenAlreadyProspected() {final game = orderSuggestionProspectOwnProvinceBudgetPriorityGame(feedstockAlreadyProspected: true,); final topology = orderSuggestionProspectOwnProvinceBudgetPriorityTopology(game,); final view = buildPlayerView(game,topology,orderSuggestionProspectOwnProvinceBudgetPriorityPlayerId,); final suggestions = suggestWorkOrders(view,game,topology,const Orders()); expect(orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockProspects(suggestions,),isEmpty,);}

void ospobpRunOwnProvinceBudgetExemptionDeterministic() {final game = orderSuggestionProspectOwnProvinceBudgetPriorityGame(); final topology = orderSuggestionProspectOwnProvinceBudgetPriorityTopology(game,); final view = buildPlayerView(game,topology,orderSuggestionProspectOwnProvinceBudgetPriorityPlayerId,); final first = suggestWorkOrders(view,game,topology,const Orders()); final second = suggestWorkOrders(view,game,topology,const Orders()); List<String> keyOf(List<WorkOrder> os) => (os.map((o) => '${o.unitId}|${o.target}|${o.targetTileKey}').toList()..sort()); expect(keyOf(first),equals(keyOf(second))); expect(orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockProspects(first),isNotEmpty,);}

/// Scenarios for suggestWorkOrders own-province prospect budget exemption.
List<RunnableScenario>
suggestWorkOrdersOwnProvinceProspectBudgetScenarios() => [
  rs('co-located feedstock Explorer still receives its iron prospect after earlier units drain the shared probe budget', ospobpRunCoLocatedFeedstockReceivesProspectAfterBudgetDrain, '#2847'),
  rs('no feedstock prospect when the co-located tile is already prospected (negative control)', ospobpRunNoFeedstockProspectWhenAlreadyProspected, '#2847'),
  rs('own-province budget exemption is deterministic across runs', ospobpRunOwnProvinceBudgetExemptionDeterministic, '#2847'),
];
