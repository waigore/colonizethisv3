import 'goal_manager.dart';
import 'planner_context.dart';
import 'planning_imports.dart';
import '../util/orders_extensions.dart';
import 'research_planner_decision.dart';
import 'research_planner_funding.dart';

export 'research_planner_decision.dart';

final _log = packageLogger();

/// Computes the research planner threshold the same way [runResearchPlanner]
/// does: `40 - getAgendaResearchModifier(hiddenAgendaId)`.
///
/// Pure and deterministic — identical inputs always yield identical
/// outputs. Used by the orchestrator (Refs #2832 trace
/// decision-provenance) to populate `thresholds.domainGates.thresholds.research`
/// and to scale non-tech slot-fill aggression.
int computeResearchThreshold({required PlannerContext ctx}) =>
    40 - getAgendaResearchModifier(ctx.config.hiddenAgendaId);

/// Whether the research planner treats research as a primary intent this turn.
///
/// Mirrors the gate the planner uses to decide full-slot fill: research is a
/// primary intent when `primaryGoal == tech` **or** `domainWeights.research >=
/// computeResearchThreshold(ctx)`. The planner now runs **every** turn (it may
/// emit zero orders); this predicate drives the trace `researchPlannerRan` gate
/// and is retained for decision-provenance.
///
/// Pure and deterministic — identical inputs always yield identical outputs.
bool researchPlannerWillRun({required PlannerContext ctx}) {
  if (ctx.primaryGoal == StrategicGoal.tech) {
    return true;
  }
  return ctx.domainWeights.research >= computeResearchThreshold(ctx: ctx);
}

/// Reorders [candidates] so research slots targeting a civilian-gating tech
/// (`isCivilianGatingTech`) the player has not yet unlocked come first, then the
/// remaining candidates — each group keeps its original (slot-index-sorted)
/// relative order, so the result is fully deterministic (Refs #3793 AC6;
/// SPEC/ai/civilian-build-planner.md § Tech prioritization).
///
/// The total candidate count is unchanged: the bias only changes *which* techs
/// are selected within the unchanged per-turn slot target, so it funds no extra
/// research slot and cannot exceed the `researchPaperReserveShare` reservation.
/// Returns the input unchanged when no candidate is a not-yet-unlocked
/// civilian-gating tech. [techUnlocked] maps tech id → unlocked flag; a tech is
/// treated as unlocked only when its entry is exactly `true`.
List<ResearchOrder> _prioritizeCivilianGatingTechs(
  List<ResearchOrder> candidates,
  Map<String, bool>? techUnlocked,
) {
  final prioritized = <ResearchOrder>[];
  final rest = <ResearchOrder>[];
  for (final o in candidates) {
    final unlocked = techUnlocked?[o.techId] == true;
    if (!unlocked && isCivilianGatingTech(o.techId)) {
      prioritized.add(o);
    } else {
      rest.add(o);
    }
  }
  if (prioritized.isEmpty) return candidates;
  return <ResearchOrder>[...prioritized, ...rest];
}

/// Full-AI research planner: every turn, fills empty research slots with
/// distinct techs and assigns a uniform treasury-aware balanced funding tier.
///
/// Preserves in-progress research, targets all empty slots when
/// `primaryGoal == tech` (else scales by `researchSlotFillAggression` and the
/// research domain weight), and packs funding by uniform downgrade then
/// highest-index drop within the research debt floor.
/// SPEC/ai/ai-architecture.md § Research; SPEC/program/order-suggestions.md.
Orders runResearchPlanner({required PlannerContext ctx}) =>
    runResearchPlannerWithDecision(ctx: ctx).orders;

/// As [runResearchPlanner], but also returns the multi-slot decision record
/// for the AI trace (Refs #3472 AC10). The orchestrator uses this entry to
/// populate `thresholds.domainGates.research`.
ResearchPlannerResult runResearchPlannerWithDecision({
  required PlannerContext ctx,
}) {
  final thresholds = resolveThresholds(
    ctx.config.personalityId,
    overrides: ctx.config.parameterOverrides,
  );

  final suggestions = ctx.suggestionAPI.suggestResearchOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
    researchNavalWeight: thresholds.researchNaval,
    researchMilitaryWeight: thresholds.researchMilitary,
    researchEconomicWeight: thresholds.researchEconomic,
    researchExplorationWeight: thresholds.researchExploration,
    researchSeed: ctx.seeds.researchSeed,
    categoryDiversifyWeight: kResearchCategoryDiversifyWeight,
  );
  if (suggestions.isEmpty) return ResearchPlannerResult(orders: ctx.orders);

  final progress =
      ctx.view.player.researchProgressByTechId ?? const <String, int>{};
  bool isInProgress(ResearchOrder o) => (progress[o.techId] ?? 0) > 0;

  final mustKeep = suggestions.where(isInProgress).toList();
  final newCandidates = suggestions.where((o) => !isInProgress(o)).toList()
    ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

  // Refs #3793 AC6: when the civilian build planner is enabled, front-load
  // research slots that target a civilian-gating tech the player has not yet
  // unlocked (Merchant ⇐ merchant_companies, Rail Builder ⇐ early_steam_engine)
  // so the AI researches toward the gates that expand the civilian build pool.
  // Reorders within the existing slot pool only (count unchanged) → no extra
  // funding, so the paper-reserve bound holds. Active when the flag mirrors
  // kCivilianBuildPlannerEnabled (now `true` by default); tests can opt out via
  // civilianBuildPlannerEnabled: false.
  // SPEC/ai/civilian-build-planner.md § Tech prioritization.
  final orderedNewCandidates = ctx.civilianBuildPlannerEnabled
      ? _prioritizeCivilianGatingTechs(
          newCandidates,
          ctx.view.player.techUnlocked,
        )
      : newCandidates;

  final slotTarget = researchTargetNewSlotCount(
    ctx: ctx,
    thresholds: thresholds,
    emptyCount: orderedNewCandidates.length,
  );
  final selectedNew = orderedNewCandidates.take(slotTarget.target).toList();

  if (mustKeep.isEmpty && selectedNew.isEmpty) {
    return ResearchPlannerResult(orders: ctx.orders);
  }

  final pack = packResearchFunding(
    ctx: ctx,
    thresholds: thresholds,
    mustKeep: mustKeep,
    selectedNew: selectedNew,
  );
  final funded = pack.orders;
  if (funded.isEmpty) return ResearchPlannerResult(orders: ctx.orders);

  final decision = _buildDecision(
    emptySlotCount: newCandidates.length,
    slotTarget: slotTarget,
    selectedNew: selectedNew,
    pack: pack,
    funded: funded,
  );

  _log.i(
    'research chosen nationId=${ctx.nationId} slots=${funded.length} '
    'funding=${funded.first.funding.name} inProgress=${mustKeep.length} '
    'constraint=${decision.constraintReason}',
  );
  return ResearchPlannerResult(
    orders: ctx.orders.appendResearchOrders(ctx.nationId, funded),
    decision: decision,
  );
}

/// Primary binding constraint for the multi-slot research decision, by
/// documented precedence: `treasuryDrop` > `stalledExpansionCap` > `atWarCap` >
/// `uniformDowngrade` > `none`. Uses guard-style early returns so the precedence
/// chain stays flat (control-flow nesting depth).
String researchConstraintReason(
  ResearchSlotTarget slotTarget,
  ResearchFundingPack pack,
) {
  if (pack.droppedNewCount > 0) return 'treasuryDrop';
  if (slotTarget.stalledExpansionCapApplied) return 'stalledExpansionCap';
  if (slotTarget.atWarCapApplied) return 'atWarCap';
  if (pack.tierIdx < pack.capIdx) return 'uniformDowngrade';
  return 'none';
}

/// Assembles the [ResearchPlannerDecision] from the resolved slot target and
/// treasury-packing outcome. `constraintReason` follows the documented
/// precedence (treasuryDrop > stalledExpansionCap > atWarCap > uniformDowngrade
/// > none).
ResearchPlannerDecision _buildDecision({
  required int emptySlotCount,
  required ResearchSlotTarget slotTarget,
  required List<ResearchOrder> selectedNew,
  required ResearchFundingPack pack,
  required List<ResearchOrder> funded,
}) {
  final keptNewCount = selectedNew.length - pack.droppedNewCount;
  final droppedSlotIndices = <int>[
    for (final o in selectedNew.skip(keptNewCount)) o.slotIndex,
  ].reversed.toList();

  final constraintReason = researchConstraintReason(slotTarget, pack);

  return ResearchPlannerDecision(
    emptySlotCount: emptySlotCount,
    targetSlotCount: slotTarget.target,
    atWarCapApplied: slotTarget.atWarCapApplied,
    stalledExpansionCapApplied: slotTarget.stalledExpansionCapApplied,
    fundingTier: ResearchFundingLevel.values[pack.tierIdx],
    slots: [
      for (final o in funded)
        ResearchSlotDecision(
          slotIndex: o.slotIndex,
          techId: o.techId,
          funding: o.funding,
        ),
    ],
    droppedSlotIndices: droppedSlotIndices,
    constraintReason: constraintReason,
  );
}
