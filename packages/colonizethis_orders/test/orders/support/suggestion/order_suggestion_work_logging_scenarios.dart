// Table-driven suggestWorkOrders logging scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_suggestion_work_logging_fixtures.dart';
import 'work_suggestion_pipeline_fixtures.dart';
// dart format off

void oswlRunEmitsSummariesForCivilianTypes() {withWspLogCapture((events) { final fixture = osgwFourCivilianUnitsGame(); suggestWorkOrders( fixture.view, fixture.game, fixture.topology, const Orders(), ); final lines = wspSuggestWorkLines(events); expect(lines, isNotEmpty); expect( lines.any( (m) => m.contains('unitId=u_explorer') && m.contains('target=explore') && m.contains('outcome='), ), isTrue, ); expect( lines.any( (m) => m.contains('unitId=u_builder') && m.contains('target=build_improvement') && m.contains('outcome=') && m.contains('reason='), ), isTrue, ); expect( lines.any( (m) => m.contains('unitId=u_spy') && m.contains('target=counter_spy') && m.contains('outcome='), ), isTrue, ); expect( lines.any( (m) => m.contains('unitId=u_merchant') && m.contains('target=purchase_land') && m.contains('outcome=') && m.contains('reason='), ), isTrue, ); expect(lines.length, lessThan(80), reason: 'summary-only, no tile spam'); });}

void oswlRunLoggerLinesNeverEmitUnboundedFullListPayload() {withWspLogCapture((events) {final fixture = osgwSingleExplorerGame(); suggestWorkOrders(fixture.view,fixture.game,fixture.topology,const Orders(),); for (final e in events) {if (e.message.contains('suggestWorkOrders')) {expect(e.message,isNot(contains('full list')),reason: 'bounded preview only (Refs #2133)',); } } });}

void oswlRunMultipleProspectTilesEmitIncludedCount() {withWspLogCapture((events) {final fixture = osgwTwoIronTilesFoggedGame(); final suggestions = suggestWorkOrders(fixture.view,fixture.game,fixture.topology,const Orders(),); final prospectOrders = suggestions.where((o) => o.target == kWorkTargetProspect).toList(); expect(prospectOrders.length,greaterThanOrEqualTo(2),reason: 'fixture must surface multiple prospect rows to assert summary',); final prospectLines = wspSuggestWorkLines(events,).where((l) => l.contains('target=prospect')).toList(); expect(prospectLines,hasLength(1)); expect(prospectLines.single,contains('includedCount=${prospectOrders.length}'),); expect(prospectLines.single,contains('outcome=included')); expect(prospectLines.single,contains('tile=-')); });}

void oswlRunPendingTargetsPreserveDuplicateCheckAndLogOrdering() {withWspLogCapture((events) {final fixture = osgwExplorerPendingDuplicateGame(); suggestWorkOrders(fixture.view,fixture.game,fixture.topology,fixture.orders,); final explorerLines = wspSuggestWorkLines(events,).where((line) => line.contains('unitId=u_explorer')).toList(); expect(explorerLines,hasLength(2)); expect(explorerLines[0],contains('target=explore')); expect(explorerLines[0],contains('reason=duplicate_pending')); expect(explorerLines[1],contains('target=prospect')); expect(explorerLines[1],contains('reason=duplicate_pending')); });}

List<RunnableScenario> orderSuggestionWorkLoggingScenarios() => [
  rs('emits suggest_work summaries for Explorer/Builder/Spy/Merchant', oswlRunEmitsSummariesForCivilianTypes),
  rs('suggestWorkOrders logger lines never emit unbounded full list payload', oswlRunLoggerLinesNeverEmitUnboundedFullListPayload, '#2133'),
  rs('explorer multiple prospect tiles emit one suggest_work with includedCount', oswlRunMultipleProspectTilesEmitIncludedCount),
  rs('explorer pending targets preserve duplicate check and log ordering', oswlRunPendingTargetsPreserveDuplicateCheckAndLogOrdering),
];
