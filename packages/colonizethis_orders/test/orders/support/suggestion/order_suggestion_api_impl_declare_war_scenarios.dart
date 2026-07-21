// Table-driven API declare-war suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_api_impl_declare_war_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

void osaidwRunDeclareWarWhenOvertureWouldWinInDiplomaticPass() {final game = apiImplDeclareWarMinorScenarioGame(); final view = apiImplDeclareWarViewFor(game); final general = _api.suggestDiplomaticOrders( view, game, apiImplDeclareWarEmptyTopology, _emptyOrders, ); final declareOnly = _api.suggestDeclareWarOrders( view, game, apiImplDeclareWarEmptyTopology, _emptyOrders, ); expect( general.any( (o) => o.targetFactionId == 'minor1' && o.type == DiplomaticOrderType.establishOverture, ), isTrue, ); expect( general.any( (o) => o.targetFactionId == 'minor1' && o.type == DiplomaticOrderType.declareWar, ), isFalse, ); expect( declareOnly.any( (o) => o.targetFactionId == 'minor1' && o.type == DiplomaticOrderType.declareWar, ), isTrue, ); expect( declareOnly.every((o) => o.type == DiplomaticOrderType.declareWar), isTrue, );}

List<RunnableScenario> orderSuggestionApiImplDeclareWarScenarios() => [
  rs('returns declareWar toward minor when establishOverture would win in suggestDiplomaticOrders', osaidwRunDeclareWarWhenOvertureWouldWinInDiplomaticPass),
];
