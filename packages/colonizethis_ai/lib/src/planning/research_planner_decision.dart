import 'planning_imports.dart';

/// Research planner decision / result types for AI traces (Refs #4104 Slice B).
/// One emitted research slot in the multi-slot decision trace (Refs #3472
/// AC10): the assigned slot index, tech id, and uniform funding tier.
class ResearchSlotDecision {
  const ResearchSlotDecision({
    required this.slotIndex,
    required this.techId,
    required this.funding,
  });

  final int slotIndex;
  final String techId;
  final ResearchFundingLevel funding;

  Map<String, Object?> toJson() => <String, Object?>{
    'slotIndex': slotIndex,
    'techId': techId,
    'funding': funding.name,
  };
}

/// Multi-slot Full-AI research decision provenance for the AI trace
/// (Refs #3472 AC10). Emitted under `thresholds.domainGates.research`;
/// see SPEC/ai/turn-trace-interpretation.md § Domain activation.
///
/// Pure runtime observation of the planner's slot-fill / treasury-packing
/// arithmetic; carries no side effects and is deterministic for fixed inputs.
class ResearchPlannerDecision {
  const ResearchPlannerDecision({
    required this.emptySlotCount,
    required this.targetSlotCount,
    required this.atWarCapApplied,
    required this.stalledExpansionCapApplied,
    required this.fundingTier,
    required this.slots,
    required this.droppedSlotIndices,
    required this.constraintReason,
  });

  /// Empty active slots that had a candidate tech this turn.
  final int emptySlotCount;

  /// New slots targeted after aggression scaling and the slot-fill caps.
  final int targetSlotCount;

  /// Whether the at-war cap reduced the target below its pre-cap value.
  final bool atWarCapApplied;

  /// Whether the stalled-expansion cap reduced the target below its running
  /// value (applied after the at-war cap).
  final bool stalledExpansionCapApplied;

  /// Uniform funding tier applied to every emitted order.
  final ResearchFundingLevel fundingTier;

  /// Emitted slots (in-progress + new), sorted by `slotIndex`.
  final List<ResearchSlotDecision> slots;

  /// New slot indices dropped by treasury packing, highest-index first.
  final List<int> droppedSlotIndices;

  /// Primary binding constraint, by precedence: `treasuryDrop` >
  /// `stalledExpansionCap` > `atWarCap` > `uniformDowngrade` > `none`.
  final String constraintReason;

  Map<String, Object?> toJson() => <String, Object?>{
    'emptySlotCount': emptySlotCount,
    'targetSlotCount': targetSlotCount,
    'atWarCapApplied': atWarCapApplied,
    'stalledExpansionCapApplied': stalledExpansionCapApplied,
    'fundingTier': fundingTier.name,
    'slots': [for (final s in slots) s.toJson()],
    'droppedSlotIndices': droppedSlotIndices,
    'constraintReason': constraintReason,
  };
}

/// Research planner output plus the multi-slot decision record for the trace.
///
/// [decision] is `null` when the planner emitted no research orders (no
/// suggestions, no targeted/in-progress slots, or an empty funded set), so the
/// trace omits `thresholds.domainGates.research` for that turn.
class ResearchPlannerResult {
  const ResearchPlannerResult({required this.orders, this.decision});

  final Orders orders;
  final ResearchPlannerDecision? decision;
}
