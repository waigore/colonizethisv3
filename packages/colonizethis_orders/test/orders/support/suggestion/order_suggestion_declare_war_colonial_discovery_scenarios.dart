// Table-driven colonial discovery declare-war scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';
import 'order_suggestion_declare_war_colonial_discovery_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();
// dart format off

void osdwcdRunExcludesSeaReachableTribeWithoutNwVisibility() {final game = colonialDiscoveryNoNwVisibilityGame(); final view = colonialDiscoveryViewFor(game); expect(knownDiplomaticTargetFactionIds(view: view,game: game,topology: colonialAcquisitionTopology,),isNot(contains('tribe1')),); final declareOnly = _api.suggestDeclareWarOrders(view,game,colonialAcquisitionTopology,_emptyOrders,); expect(declareOnly.any((o) => o.targetFactionId == 'tribe1' && o.type == DiplomaticOrderType.declareWar,),isFalse,);}

List<RunnableScenario>
orderSuggestionDeclareWarColonialDiscoveryScenarios() => [
  rs('suggestDeclareWarOrders excludes sea-reachable tribe without NW tile visibility (#3620 first-contact gate)', osdwcdRunExcludesSeaReachableTribeWithoutNwVisibility, '#3620'),
];
