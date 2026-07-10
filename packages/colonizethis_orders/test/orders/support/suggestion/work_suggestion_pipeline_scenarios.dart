// Table-driven WorkSuggestionPipeline scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_suggestion_pipeline_run_rows.dart';

/// One row in [workSuggestionPipelineScenarios].
class WorkSuggestionPipelineScenario implements LabeledScenario {
  const WorkSuggestionPipelineScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runWorkSuggestionPipelineScenario(
  WorkSuggestionPipelineScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for work_suggestion_pipeline family tests.
List<WorkSuggestionPipelineScenario>
workSuggestionPipelineScenarios() => const [
  WorkSuggestionPipelineScenario(
    label: 'duplicate pending target short-circuits without adding suggestions',
    run: wspRunDuplicatePendingShortCircuits,
  ),
  WorkSuggestionPipelineScenario(
    label:
        'first accepted candidate stops iteration when includeAllAccepted is false',
    run: wspRunFirstAcceptedStopsIteration,
  ),
  WorkSuggestionPipelineScenario(
    label: 'includeAllAccepted collects multiple rows and logs includedCount',
    run: wspRunIncludeAllAcceptedCollectsMultiple,
  ),
  WorkSuggestionPipelineScenario(
    label: 'no candidates logs noCandidateReason',
    run: wspRunNoCandidatesLogsReason,
  ),
  WorkSuggestionPipelineScenario(
    label:
        'resolveNoCandidateReason overrides noCandidateReason when nothing yielded',
    run: wspRunResolveNoCandidateOverrides,
  ),
  WorkSuggestionPipelineScenario(
    label:
        'maxProbeAttempts override allows more than default cap of accepted rows',
    run: wspRunMaxProbeAttemptsOverride,
  ),
  WorkSuggestionPipelineScenario(
    label:
        'default cap of kMaxWorkProbeAttemptsPerUnitPerTarget caps accepted rows',
    run: wspRunDefaultCapKMaxWorkProbeAttempts,
  ),
  WorkSuggestionPipelineScenario(
    label: 'rejected candidates log engineRejectedReason',
    run: wspRunRejectedCandidatesLogEngineRejectedReason,
  ),
];
