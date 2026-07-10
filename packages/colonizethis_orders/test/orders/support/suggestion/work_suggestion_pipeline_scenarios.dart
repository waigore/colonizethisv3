// Table-driven WorkSuggestionPipeline scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/work_suggestion_pipeline.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'work_suggestion_pipeline_fixtures.dart';
// dart format off

void wspRunDuplicatePendingShortCircuits() {withWspLogCapture((events) {final unit = wspBuilderUnit(); final suggestions = <WorkOrder>[]; final existing = <String,Set<String>>{unit.id: {kWorkTargetBuildImprovement},}; WorkSuggestionPipeline.run(unit: unit,unitType: unit.type,unitRegionId: 'ow',atProvinceId: 'ow|p1',workTarget: kWorkTargetBuildImprovement,existingTargetsByUnit: existing,suggestions: suggestions,candidatesProvider: () => [WorkOrder(unitId: unit.id,target: kWorkTargetBuildImprovement,targetTileKey: 'ow|p1|0|0',),],candidateAcceptor: (_) => true,noCandidateReason: 'no_valid_tile',); expect(suggestions,isEmpty); final lines = wspSuggestWorkLines(events); expect(lines,isNotEmpty); expect(lines.first,contains('reason=duplicate_pending')); });}

void wspRunFirstAcceptedStopsIteration() {withWspLogCapture((events) {final unit = wspBuilderUnit(); final suggestions = <WorkOrder>[]; final existing = <String,Set<String>>{}; WorkSuggestionPipeline.run(unit: unit,unitType: unit.type,unitRegionId: 'ow',atProvinceId: 'ow|p1',workTarget: kWorkTargetBuildImprovement,existingTargetsByUnit: existing,suggestions: suggestions,candidatesProvider: () sync* {yield WorkOrder(unitId: unit.id,target: kWorkTargetBuildImprovement,targetTileKey: 'a',); yield WorkOrder(unitId: unit.id,target: kWorkTargetBuildImprovement,targetTileKey: 'b',); },candidateAcceptor: (_) => true,noCandidateReason: 'no_valid_tile',); expect(suggestions,hasLength(1)); expect(suggestions.single.targetTileKey,'a'); expect(existing[unit.id],contains(kWorkTargetBuildImprovement)); });}

void wspRunIncludeAllAcceptedCollectsMultiple() {
  withWspLogCapture((events) {
    final unit = wspBuilderUnit();
    final suggestions = <WorkOrder>[];
    final existing = <String, Set<String>>{};

    WorkSuggestionPipeline.run(
      unit: unit,
      unitType: unit.type,
      unitRegionId: 'ow',
      atProvinceId: 'ow|p1',
      workTarget: kWorkTargetBuildImprovement,
      existingTargetsByUnit: existing,
      suggestions: suggestions,
      candidatesProvider: () sync* {
        yield WorkOrder(
          unitId: unit.id,
          target: kWorkTargetBuildImprovement,
          targetTileKey: 'a',
        );
        yield WorkOrder(
          unitId: unit.id,
          target: kWorkTargetBuildImprovement,
          targetTileKey: 'b',
        );
      },
      candidateAcceptor: (_) => true,
      noCandidateReason: 'no_valid_tile',
      includeAllAccepted: true,
    );

    expect(suggestions, hasLength(2));
    final lines = wspSuggestWorkLines(events);
    expect(lines.last, contains('includedCount=2'));
  });
}

void wspRunNoCandidatesLogsReason() {withWspLogCapture((events) {final unit = wspBuilderUnit(); final suggestions = <WorkOrder>[]; final existing = <String,Set<String>>{}; WorkSuggestionPipeline.run(unit: unit,unitType: unit.type,unitRegionId: 'ow',atProvinceId: 'ow|p1',workTarget: kWorkTargetBuildImprovement,existingTargetsByUnit: existing,suggestions: suggestions,candidatesProvider: () => const <WorkOrder>[],candidateAcceptor: (_) => true,noCandidateReason: 'custom_empty',); expect(suggestions,isEmpty); final lines = wspSuggestWorkLines(events); expect(lines.single,contains('reason=custom_empty')); });}

void wspRunResolveNoCandidateOverrides() {withWspLogCapture((events) {final unit = wspBuilderUnit(); final suggestions = <WorkOrder>[]; final existing = <String,Set<String>>{}; var probeLast = 'fallback'; WorkSuggestionPipeline.run(unit: unit,unitType: unit.type,unitRegionId: 'ow',atProvinceId: 'ow|p1',workTarget: kWorkTargetBuildImprovement,existingTargetsByUnit: existing,suggestions: suggestions,candidatesProvider: () sync* {probeLast = 'after_probe'; },candidateAcceptor: (_) => true,noCandidateReason: 'ignored_when_resolver',resolveNoCandidateReason: () => probeLast,); expect(suggestions,isEmpty); final lines = wspSuggestWorkLines(events); expect(lines.single,contains('reason=after_probe')); });}

void wspRunMaxProbeAttemptsOverride() {withWspLogCapture((events) {final unit = wspExplorerUnit(); final suggestions = <WorkOrder>[]; final existing = <String,Set<String>>{}; WorkSuggestionPipeline.run(unit: unit,unitType: unit.type,unitRegionId: 'ow',atProvinceId: 'ow|p1',workTarget: kWorkTargetProspect,existingTargetsByUnit: existing,suggestions: suggestions,candidatesProvider: () sync* {for (var i = 0; i < 6; i++) {yield WorkOrder(unitId: unit.id,target: kWorkTargetProspect,targetTileKey: 'ow|p1|$i|0',); } },candidateAcceptor: (_) => true,noCandidateReason: 'no_valid_tile',includeAllAccepted: true,maxProbeAttempts: 6,); expect(suggestions,hasLength(6)); final lines = wspSuggestWorkLines(events); expect(lines.last,contains('includedCount=6')); });}

void wspRunDefaultCapKMaxWorkProbeAttempts() {
  withWspLogCapture((events) {
    final unit = wspExplorerUnit();
    final suggestions = <WorkOrder>[];
    final existing = <String, Set<String>>{};

    WorkSuggestionPipeline.run(
      unit: unit,
      unitType: unit.type,
      unitRegionId: 'ow',
      atProvinceId: 'ow|p1',
      workTarget: kWorkTargetProspect,
      existingTargetsByUnit: existing,
      suggestions: suggestions,
      candidatesProvider: () sync* {
        for (var i = 0; i < 6; i++) {
          yield WorkOrder(
            unitId: unit.id,
            target: kWorkTargetProspect,
            targetTileKey: 'ow|p1|$i|0',
          );
        }
      },
      candidateAcceptor: (_) => true,
      noCandidateReason: 'no_valid_tile',
      includeAllAccepted: true,
    );

    expect(
      suggestions,
      hasLength(kMaxWorkProbeAttemptsPerUnitPerTarget),
      reason:
          'default cap should match SPEC § Throughput bounds '
          'kMaxWorkProbeAttemptsPerUnitPerTarget',
    );
  });
}

void wspRunRejectedCandidatesLogEngineRejectedReason() {withWspLogCapture((events) {final unit = wspBuilderUnit(); final suggestions = <WorkOrder>[]; final existing = <String,Set<String>>{}; WorkSuggestionPipeline.run(unit: unit,unitType: unit.type,unitRegionId: 'ow',atProvinceId: 'ow|p1',workTarget: kWorkTargetBuildImprovement,existingTargetsByUnit: existing,suggestions: suggestions,candidatesProvider: () => [WorkOrder(unitId: unit.id,target: kWorkTargetBuildImprovement,targetTileKey: 'a',),],candidateAcceptor: (_) => false,noCandidateReason: 'no_valid_tile',engineRejectedReason: 'rejected_by_test',); expect(suggestions,isEmpty); final lines = wspSuggestWorkLines(events); expect(lines.single,contains('reason=rejected_by_test')); });}

/// Canonical scenarios for work_suggestion_pipeline family tests.
List<RunnableScenario> workSuggestionPipelineScenarios() => [
  rs('duplicate pending target short-circuits without adding suggestions', wspRunDuplicatePendingShortCircuits),
  rs('first accepted candidate stops iteration when includeAllAccepted is false', wspRunFirstAcceptedStopsIteration),
  rs('includeAllAccepted collects multiple rows and logs includedCount', wspRunIncludeAllAcceptedCollectsMultiple),
  rs('no candidates logs noCandidateReason', wspRunNoCandidatesLogsReason),
  rs('resolveNoCandidateReason overrides noCandidateReason when nothing yielded', wspRunResolveNoCandidateOverrides),
  rs('maxProbeAttempts override allows more than default cap of accepted rows', wspRunMaxProbeAttemptsOverride),
  rs('default cap of kMaxWorkProbeAttemptsPerUnitPerTarget caps accepted rows', wspRunDefaultCapKMaxWorkProbeAttempts),
  rs('rejected candidates log engineRejectedReason', wspRunRejectedCandidatesLogEngineRejectedReason),
];
