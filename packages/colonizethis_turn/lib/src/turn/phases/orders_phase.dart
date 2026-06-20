import '../turn_phase_handler_helpers.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

/// Orders phase handler — passes pipeline state through unchanged.
/// Orders are already merged and validated before turn resolution begins;
/// this phase exists in the sequence so downstream phases can observe a
/// stable Orders boundary in traces. Refs #2560.
TurnPhaseStepOutcome ordersTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => simplePipelinePhase((pipeline) => pipeline)(acc, config, turn);
