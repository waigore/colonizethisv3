import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_gate_data.dart';
import 'phase_planner_dispatch.dart';

/// Orders plus per-turn planning provenance for AI trace export.
///
/// Carries the legacy declare-war target and conquest army-move count
/// alongside the resolved [PhasePlanOutcome] and [DomainGateData] that
/// drive `state.phasePlan` and `thresholds.domainGates` emission in the
/// AI trace (Refs #2832 decision-provenance).
class DomainPlannerOutcome {
  const DomainPlannerOutcome({
    required this.orders,
    this.declaredWarTargetFactionId,
    this.conquestArmyMoveCount = 0,
    this.phasePlan,
    this.domainGateData,
  });

  final Orders orders;
  final String? declaredWarTargetFactionId;
  final int conquestArmyMoveCount;

  /// Resolved phase plan from [runPhasePlanners], or `null` when this
  /// outcome was produced via the legacy `runDomainPlanners` entry that
  /// does not surface the plan upward.
  final PhasePlanOutcome? phasePlan;

  /// Domain planner activation gates and resolved thresholds captured by
  /// the orchestrator during this pass, or `null` when not recorded
  /// (e.g. callers that pre-date the trace decision-provenance wiring).
  final DomainGateData? domainGateData;
}
