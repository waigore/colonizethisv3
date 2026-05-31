/// Domain planner gate provenance. SPEC/program/turn-resolution-json-trace.md
/// and SPEC/ai/turn-trace-interpretation.md.
///
/// Captures which domain planners executed their decision logic and which
/// were skipped by their internal weight/threshold gates during a single
/// [runDomainPlannersWithOutcome] pass. The strategic-AI trace builder
/// (Refs #2832) emits this under `thresholds.domainGates` so a reader can
/// distinguish "planner skipped due to weight below threshold" from
/// "planner ran but produced no targets" without consulting the planner
/// source code.
///
/// All fields are pure runtime observations of the orchestrator's gate
/// arithmetic. The class carries no side effects and is `const`-friendly
/// so identical inputs produce identical instances (Refs #2509 Must-have
/// #7 determinism alignment).
library;

/// Snapshot of domain planner activation gates for one AI player turn.
class DomainGateData {
  const DomainGateData({
    required this.workPlannerRan,
    required this.buildPlannerRan,
    required this.movePlannerRan,
    required this.diplomacyPlannerRan,
    required this.navalPlannerRan,
    required this.researchPlannerRan,
    required this.conquestArmyMovePlannerRan,
    required this.conquestPasses,
    required this.tradePlannerRan,
    this.workThreshold,
    this.buildThreshold,
    this.researchThreshold,
  });

  /// Whether the civilian work planner executed its full selection pass.
  ///
  /// Mirrors the orchestrator's `runFullAiCivilianWork` boolean: `true`
  /// when the work pass was invoked (either by primary goal, the
  /// domain-weight gate, an active colonial-pressure boost, or because
  /// the GP already owns NW provinces); `false` when civilian work was
  /// skipped because the domain weight was below the resolved
  /// `workThreshold` and no overriding signal applied.
  final bool workPlannerRan;

  /// Whether the build pass picked a unit (`true`) or short-circuited
  /// on the build-threshold gate (`false`).
  ///
  /// `true` when either the resolved `domainEconomyWeight` cleared
  /// `buildThreshold` or a force-rebuild signal pinned the threshold
  /// to zero. `false` when build candidates existed but the planner
  /// skipped them due to insufficient weight without a force-rebuild
  /// override.
  final bool buildPlannerRan;

  /// The move planner is unconditionally invoked on every player turn,
  /// so this is always `true` today. Recorded for symmetry so future
  /// gates (Refs SPEC/ai/turn-trace-interpretation.md) become observable
  /// without an additive schema change.
  final bool movePlannerRan;

  /// The diplomacy planner is unconditionally invoked across two
  /// orchestrator passes per turn, so this is always `true` today.
  final bool diplomacyPlannerRan;

  /// Whether the naval planner executed its move/mission selection pass.
  ///
  /// Mirrors the planner's internal `weight >= kNavalRunMinWeight` gate
  /// computed by [computeNavalRunGate]. `false` when the resolved weight
  /// (including colonial-pressure adjustments and minimums) was below the
  /// run threshold so the planner returned its input orders unchanged.
  final bool navalPlannerRan;

  /// Whether the research planner executed its weighted-pick selection.
  ///
  /// Mirrors the planner's internal threshold gate via
  /// [researchPlannerWillRun]: `true` when `primaryGoal == tech` or the
  /// `domainWeights.research` value cleared the resolved
  /// `researchThreshold`; `false` when the gate trips. The trace also
  /// records the threshold so a reader can compute the gap.
  final bool researchPlannerRan;

  /// Whether at least one conquest army-move pass executed.
  ///
  /// The orchestrator always invokes the first pass, so this is
  /// effectively always `true` today; recorded for forward compatibility
  /// when future suppression slices (Refs `SPEC/ai/ai-architecture.md`
  /// § Observer goal phases) may structurally skip the conquest planner
  /// for non-EXPAND/COLONIAL phases.
  final bool conquestArmyMovePlannerRan;

  /// Resolved conquest pass count for this turn.
  ///
  /// `kStalledConquestArmyMovePasses` (22) when the phase plan resolves
  /// to EXPAND/COLONIAL-lite extra-passes, otherwise `1`. The trace
  /// records this so a reader can correlate the configured cap with the
  /// active phase.
  final int conquestPasses;

  /// Whether the treasury planner emitted at least one trade order for
  /// this player turn (Refs #2994 F7). `true` iff the orchestrator
  /// merged a non-empty `economyPlan.tradeOrders` list into
  /// `Orders.tradeOrdersByPlayerId[nationId]`. `false` covers two cases
  /// the trace must distinguish only via the per-domain output count:
  /// the planner ran but produced zero orders (no surplus and no buy
  /// gate cleared) and the upstream caller passed an `EconomyPlan` with
  /// no trade orders. Either way the orchestrator skips the
  /// trade-orders append, so downstream `MapEquality` checks see no
  /// `nationId` entry under `tradeOrdersByPlayerId`.
  final bool tradePlannerRan;

  /// Computed civilian work threshold (`workThreshold`) used by the
  /// orchestrator's `runFullAiCivilianWork` gate, or `null` when the
  /// orchestrator did not compute a threshold (no domain weight check
  /// applied because a structural override fired before the threshold
  /// arithmetic).
  final int? workThreshold;

  /// Computed build threshold (`buildThreshold`) used by the
  /// `_appendEconomyBuildOrders` gate, or `null` when the orchestrator
  /// short-circuited before threshold arithmetic.
  final int? buildThreshold;

  /// Computed research threshold (`researchThreshold`) used by the
  /// research planner's gate via [computeResearchThreshold].
  ///
  /// Always populated today because the orchestrator always reaches the
  /// research planner; declared nullable so future structural skips
  /// (e.g. observer phases that suppress research) can omit the value
  /// without forcing a sentinel.
  final int? researchThreshold;

  /// JSON-serializable map for emission under
  /// `thresholds.domainGates` in the AI trace section. Empty per-planner
  /// thresholds are omitted to keep the payload compact (Refs #2832).
  Map<String, Object?> toJson() {
    final thresholdsJson = <String, Object?>{
      if (workThreshold != null) 'work': workThreshold,
      if (buildThreshold != null) 'build': buildThreshold,
      if (researchThreshold != null) 'research': researchThreshold,
    };
    return <String, Object?>{
      'workPlannerRan': workPlannerRan,
      'buildPlannerRan': buildPlannerRan,
      'movePlannerRan': movePlannerRan,
      'diplomacyPlannerRan': diplomacyPlannerRan,
      'navalPlannerRan': navalPlannerRan,
      'researchPlannerRan': researchPlannerRan,
      'conquestArmyMovePlannerRan': conquestArmyMovePlannerRan,
      'conquestPasses': conquestPasses,
      'tradePlannerRan': tradePlannerRan,
      if (thresholdsJson.isNotEmpty) 'thresholds': thresholdsJson,
    };
  }
}
