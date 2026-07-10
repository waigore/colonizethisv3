// Table-driven diplomatic validator-reuse scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_diplomatic_validator_reuse_fixtures.dart';

const _emptyOrders = Orders();
// dart format off

void osdvrRunOnePassLevelValidatorAcrossTargets() {final game = dvrTwoGpPeaceGame(); final view = buildPlayerView(game,dvrEmptyTopology,'gp1'); resetIncrementalCandidateValidatorBuildCountForTests(); final suggestions = suggestDiplomaticOrders(view,game,dvrEmptyTopology,_emptyOrders,); expect(suggestions.where((o) => o.targetFactionId == 'gp2'),hasLength(1)); expect(suggestions.single.type,DiplomaticOrderType.alliance); expect(incrementalCandidateValidatorBuildCountForTests,1,reason: 'one pass-level build; must not call buildIncrementalCandidateValidator ' 'per target for the economic pass (Refs #2394)',);}

void osdvrRunSkipsPassLevelBuildWhenSharedSupplied() {final game = dvrTwoGpPeaceGame(); final view = buildPlayerView(game,dvrEmptyTopology,'gp1'); final shared = buildIncrementalCandidateValidator(game: game,topology: dvrEmptyTopology,playerId: 'gp1',baseOrders: _emptyOrders,resolution: orderResolutionContextFromView(view,game),); resetIncrementalCandidateValidatorBuildCountForTests(); suggestDiplomaticOrders(view,game,dvrEmptyTopology,_emptyOrders,sharedCandidateValidator: shared,); expect(incrementalCandidateValidatorBuildCountForTests,0);}

void osdvrRunRebindsPassValidatorAfterEachTarget() {final game = dvrThreeGpPeaceGame(); final view = buildPlayerView(game,dvrEmptyTopology,'gp1'); resetIncrementalCandidateValidatorBuildCountForTests(); final suggestions = suggestDiplomaticOrders(view,game,dvrEmptyTopology,_emptyOrders,); expect(suggestions,hasLength(2)); expect(suggestions.map((o) => o.targetFactionId).toSet(),{'gp2','gp3'}); expect(incrementalCandidateValidatorBuildCountForTests,1,reason: 'one pass-level build across three targets (Refs #2394)',);}

List<RunnableScenario>
orderSuggestionDiplomaticValidatorReuseScenarios() => [
  rs('builds one pass-level validator across multiple diplomatic targets', osdvrRunOnePassLevelValidatorAcrossTargets, '#2394'),
  rs('skips pass-level build when sharedCandidateValidator is supplied', osdvrRunSkipsPassLevelBuildWhenSharedSupplied, '#2394'),
  rs('rebinds pass validator to workingOrders after each target', osdvrRunRebindsPassValidatorAfterEachTarget, '#2394'),
];
