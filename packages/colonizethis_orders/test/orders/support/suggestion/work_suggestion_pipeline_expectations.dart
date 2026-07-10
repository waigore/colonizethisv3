// Compact WorkSuggestionPipeline assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/work_suggestion_pipeline.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'work_suggestion_pipeline_fixtures.dart';

/// Pins for [workSuggestionPipelineScenarios] rows.
enum WorkSuggestionPipelineTarget {
  duplicatePendingShortCircuits,
  firstAcceptedStopsIteration,
  includeAllAcceptedCollectsMultiple,
  noCandidatesLogsReason,
  resolveNoCandidateOverrides,
  maxProbeAttemptsOverride,
  defaultCapKMaxWorkProbeAttempts,
  rejectedCandidatesLogEngineRejectedReason,
}

void runWorkSuggestionPipelineExpectation(WorkSuggestionPipelineTarget target) {
  withWspLogCapture((events) {
    switch (target) {
      case WorkSuggestionPipelineTarget.duplicatePendingShortCircuits:
        final unit = wspBuilderUnit();
        final suggestions = <WorkOrder>[];
        final existing = <String, Set<String>>{
          unit.id: {kWorkTargetBuildImprovement},
        };

        WorkSuggestionPipeline.run(
          unit: unit,
          unitType: unit.type,
          unitRegionId: 'ow',
          atProvinceId: 'ow|p1',
          workTarget: kWorkTargetBuildImprovement,
          existingTargetsByUnit: existing,
          suggestions: suggestions,
          candidatesProvider: () => [
            WorkOrder(
              unitId: unit.id,
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'ow|p1|0|0',
            ),
          ],
          candidateAcceptor: (_) => true,
          noCandidateReason: 'no_valid_tile',
        );

        expect(suggestions, isEmpty);
        final lines = wspSuggestWorkLines(events);
        expect(lines, isNotEmpty);
        expect(lines.first, contains('reason=duplicate_pending'));

      case WorkSuggestionPipelineTarget.firstAcceptedStopsIteration:
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
        );

        expect(suggestions, hasLength(1));
        expect(suggestions.single.targetTileKey, 'a');
        expect(existing[unit.id], contains(kWorkTargetBuildImprovement));

      case WorkSuggestionPipelineTarget.includeAllAcceptedCollectsMultiple:
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

      case WorkSuggestionPipelineTarget.noCandidatesLogsReason:
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
          candidatesProvider: () => const <WorkOrder>[],
          candidateAcceptor: (_) => true,
          noCandidateReason: 'custom_empty',
        );

        expect(suggestions, isEmpty);
        final lines = wspSuggestWorkLines(events);
        expect(lines.single, contains('reason=custom_empty'));

      case WorkSuggestionPipelineTarget.resolveNoCandidateOverrides:
        final unit = wspBuilderUnit();
        final suggestions = <WorkOrder>[];
        final existing = <String, Set<String>>{};
        var probeLast = 'fallback';

        WorkSuggestionPipeline.run(
          unit: unit,
          unitType: unit.type,
          unitRegionId: 'ow',
          atProvinceId: 'ow|p1',
          workTarget: kWorkTargetBuildImprovement,
          existingTargetsByUnit: existing,
          suggestions: suggestions,
          candidatesProvider: () sync* {
            probeLast = 'after_probe';
          },
          candidateAcceptor: (_) => true,
          noCandidateReason: 'ignored_when_resolver',
          resolveNoCandidateReason: () => probeLast,
        );

        expect(suggestions, isEmpty);
        final lines = wspSuggestWorkLines(events);
        expect(lines.single, contains('reason=after_probe'));

      case WorkSuggestionPipelineTarget.maxProbeAttemptsOverride:
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
          maxProbeAttempts: 6,
        );

        expect(suggestions, hasLength(6));
        final lines = wspSuggestWorkLines(events);
        expect(lines.last, contains('includedCount=6'));

      case WorkSuggestionPipelineTarget.defaultCapKMaxWorkProbeAttempts:
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

      case WorkSuggestionPipelineTarget.rejectedCandidatesLogEngineRejectedReason:
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
          candidatesProvider: () => [
            WorkOrder(
              unitId: unit.id,
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'a',
            ),
          ],
          candidateAcceptor: (_) => false,
          noCandidateReason: 'no_valid_tile',
          engineRejectedReason: 'rejected_by_test',
        );

        expect(suggestions, isEmpty);
        final lines = wspSuggestWorkLines(events);
        expect(lines.single, contains('reason=rejected_by_test'));
    }
  });
}
