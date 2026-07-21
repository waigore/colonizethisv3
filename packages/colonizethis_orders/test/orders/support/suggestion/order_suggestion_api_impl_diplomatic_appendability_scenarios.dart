// Table-driven diplomatic appendability scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_api_impl_diplomatic_appendability_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();
const _gp1 = 'gp1';
// dart format off

void osaidaRunExcludesTargetAlreadyInDraft() {final game = diplomaticAppendabilityTwoGpNeutralGame(); final view = buildPlayerView(game,diplomaticAppendabilityEmptyTopology,_gp1,); final withPending = Orders(diplomaticOrdersByPlayerId: {_gp1: [const DiplomaticOrder(type: DiplomaticOrderType.alliance,targetFactionId: 'gp2',),],},); final list = _api.suggestDiplomaticOrders(view,game,diplomaticAppendabilityEmptyTopology,withPending,); expect(list.where((o) => o.targetFactionId == 'gp2'),isEmpty);}

void osaidaRunCumulativeListAppendableAndValidates() {final game = diplomaticAppendabilityTwoGpAlliedGame(); final view = buildPlayerView( game, diplomaticAppendabilityEmptyTopology, _gp1, ); final suggestions = _api.suggestDiplomaticOrders( view, game, diplomaticAppendabilityEmptyTopology, const Orders(), ); final byTarget = <String, List<DiplomaticOrderType>>{}; for (final o in suggestions) { byTarget.putIfAbsent(o.targetFactionId, () => []).add(o.type); } for (final e in byTarget.entries) { final types = e.value; expect( types.toSet().length, types.length, reason: 'at most one suggestion per type per target ${e.key}', ); final nonEconomic = types .where( (t) => t != DiplomaticOrderType.grantAid && t != DiplomaticOrderType.setSubsidy, ) .length; expect( nonEconomic, lessThanOrEqualTo(1), reason: 'at most one primary diplomatic suggestion per target ${e.key}', ); } final eng = OrderEngine(); for (final o in suggestions) { final addResult = eng.addDiplomaticOrderWithContext( game, diplomaticAppendabilityEmptyTopology, _gp1, o, ); expect( addResult.isAccepted, isTrue, reason: '${o.type} ${o.targetFactionId} after prior suggestions', ); } final validateResults = eng.validatePlayerOrdersWithContext( game, diplomaticAppendabilityEmptyTopology, _gp1, ); expect(validateResults, isNotEmpty); expect( validateResults.every((r) => r.isAccepted), isTrue, reason: 'full merged diplomatic list validates', );}

void osaidaRunRemovingPendingRestoresSuggestions() {final game = diplomaticAppendabilityTwoGpNeutralGame(); final view = buildPlayerView( game, diplomaticAppendabilityEmptyTopology, _gp1, ); final pending = Orders( diplomaticOrdersByPlayerId: { _gp1: [ const DiplomaticOrder( type: DiplomaticOrderType.alliance, targetFactionId: 'gp2', ), ], }, ); expect( _api .suggestDiplomaticOrders( view, game, diplomaticAppendabilityEmptyTopology, pending, ) .where((o) => o.targetFactionId == 'gp2'), isEmpty, ); final afterClear = _api.suggestDiplomaticOrders( view, game, diplomaticAppendabilityEmptyTopology, const Orders(), ); expect(afterClear.where((o) => o.targetFactionId == 'gp2'), isNotEmpty);}

List<RunnableScenario>
orderSuggestionApiImplDiplomaticAppendabilityScenarios() => [
  rs('does not suggest toward target already in draft diplomatic orders', osaidaRunExcludesTargetAlreadyInDraft),
  rs('suggestDiplomaticOrders: cumulative list appendable and validates', osaidaRunCumulativeListAppendableAndValidates),
  rs('removing pending diplomatic order restores suggestions for that target', osaidaRunRemovingPendingRestoresSuggestions),
];
