// Table-driven WorkSuggestionPipeline scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_suggestion_pipeline_expectations.dart';

/// One row in [workSuggestionPipelineScenarios].
class WorkSuggestionPipelineScenario implements LabeledScenario {
  const WorkSuggestionPipelineScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final WorkSuggestionPipelineTarget target;
}

void runWorkSuggestionPipelineScenario(WorkSuggestionPipelineScenario scenario) {
  runWorkSuggestionPipelineExpectation(scenario.target);
}

/// Canonical scenarios for work_suggestion_pipeline family tests.
List<WorkSuggestionPipelineScenario> workSuggestionPipelineScenarios() =>
    const [
      WorkSuggestionPipelineScenario(
        label:
            'duplicate pending target short-circuits without adding suggestions',
        target: WorkSuggestionPipelineTarget.duplicatePendingShortCircuits,
      ),
      WorkSuggestionPipelineScenario(
        label:
            'first accepted candidate stops iteration when includeAllAccepted is false',
        target: WorkSuggestionPipelineTarget.firstAcceptedStopsIteration,
      ),
      WorkSuggestionPipelineScenario(
        label: 'includeAllAccepted collects multiple rows and logs includedCount',
        target: WorkSuggestionPipelineTarget.includeAllAcceptedCollectsMultiple,
      ),
      WorkSuggestionPipelineScenario(
        label: 'no candidates logs noCandidateReason',
        target: WorkSuggestionPipelineTarget.noCandidatesLogsReason,
      ),
      WorkSuggestionPipelineScenario(
        label:
            'resolveNoCandidateReason overrides noCandidateReason when nothing yielded',
        target: WorkSuggestionPipelineTarget.resolveNoCandidateOverrides,
      ),
      WorkSuggestionPipelineScenario(
        label:
            'maxProbeAttempts override allows more than default cap of accepted rows',
        target: WorkSuggestionPipelineTarget.maxProbeAttemptsOverride,
      ),
      WorkSuggestionPipelineScenario(
        label:
            'default cap of kMaxWorkProbeAttemptsPerUnitPerTarget caps accepted rows',
        target: WorkSuggestionPipelineTarget.defaultCapKMaxWorkProbeAttempts,
      ),
      WorkSuggestionPipelineScenario(
        label: 'rejected candidates log engineRejectedReason',
        target:
            WorkSuggestionPipelineTarget.rejectedCandidatesLogEngineRejectedReason,
      ),
    ];
