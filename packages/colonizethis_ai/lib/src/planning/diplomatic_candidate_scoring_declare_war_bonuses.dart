import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'phase_planner_diplomacy_filter.dart';
import 'planning_helpers.dart' show kDiplomaticDefaultBaseScore;
import 'planning_imports.dart';
import 'diplomatic_candidate_scoring_declare_war_bonuses_stalled.dart';

final _log = packageLogger();

/// OW-expansion declare-war addend scaled by [oldWorldConquestWeight].
int owConquestDeclareWarBonus(DeclareWarTargetContext ctx, int baseBonus) =>
    declareWarOldWorldConquestScaledBonus(
      baseBonus: baseBonus,
      oldWorldConquestWeight: ctx.oldWorldConquestWeight,
    );

/// Raises [currentScore] to the OW-conquest floor for [floorBonus], scaled by
/// the context's [oldWorldConquestWeight].
///
/// Captures the repeated `oldWorldConquestWeight: ctx.oldWorldConquestWeight`
/// plumbing across the five declare-war floor call sites in this file (Refs
/// #3717 declare-war OW-conquest scoring-skeleton dedup), mirroring the sibling
/// [owConquestDeclareWarBonus] addend wrapper. Pure delegation to the shared
/// [raiseToDeclareWarOldWorldConquestFloor] helper — byte-identical to the
/// inline keyword call it replaces.
int raiseToOwConquestDeclareWarFloorLocal(
  DeclareWarTargetContext ctx, {
  required int currentScore,
  required int floorBonus,
}) => raiseToDeclareWarOldWorldConquestFloor(
  currentScore: currentScore,
  floorBonus: floorBonus,
  oldWorldConquestWeight: ctx.oldWorldConquestWeight,
);

int scoreDeclareWarBonuses(DeclareWarTargetContext ctx) {
  var s = _declareWarCoreBonuses(ctx);
  s = _declareWarExpansionAndColonialBonuses(ctx, s);
  s = declareWarAdjacencyAndStalledBonuses(ctx, s);
  return declareWarFinalizeBonuses(ctx, s);
}

int _declareWarCoreBonuses(DeclareWarTargetContext ctx) {
  final warDesire = ctx.warDesireForTarget(
    ctx.order.targetFactionId,
    ctx.relationScore,
  );
  final targetProvinceCount = ctx.targetProvinceCount;
  final desiredTerritory = targetProvinceCount <= 0
      ? 1
      : ((warDesire / 25).round()).clamp(1, targetProvinceCount);
  var s = kDiplomaticDefaultBaseScore;
  s += getAgendaConquerModifier(ctx.agendaId);
  s += getAgendaTreatyBreakingModifier(ctx.agendaId);
  s += (ctx.thresholds.warLikelihood - 50);
  s += (warDesire - 50);
  if (!ctx.suppressGpDeclareWar &&
      ctx.snapshot.opportunities.weakNeighbors.contains(
        ctx.order.targetFactionId,
      )) {
    s += getDeclareWarTargetBonusWeakerNeighbor(ctx.agendaId);
    if (ctx.targetIsGreatPower &&
        warDesire >= kDeclareWarGpWeakNeighborMinWarDesire) {
      s += kDeclareWarGpWeakNeighborBonus;
    }
  }
  if (ctx.snapshot.conquest.preferredConquestTargetFactionIdsSorted.contains(
    ctx.order.targetFactionId,
  )) {
    s += owConquestDeclareWarBonus(ctx, 15);
  }
  if (_log.debugEnabled) {
    _log.d(
      'diplomacy warDesire nationId=${ctx.nationId} '
      'targetFactionId=${ctx.order.targetFactionId} '
      'warDesire=$warDesire desiredTerritory=$desiredTerritory',
    );
  }
  return s;
}

int stalledOwMinorRecoveryBonus(DeclareWarTargetContext ctx) {
  final owned = ctx.snapshot.conquest.oldWorldProvincesOwned;
  if (owned <= kFewOldWorldProvincesDefendThreshold) {
    return kDeclareWarWeakGpOwMinorRecoveryBonus;
  }
  if (isBelowObserverConquestQuota(owned)) {
    return kDeclareWarBelowQuotaOwMinorRecoveryBonus;
  }
  return 0;
}

int _declareWarColonialNwTribeBonuses(DeclareWarTargetContext ctx, int s) {
  if (!ctx.colonialPressure || !ctx.ownsInvadableNw || !ctx.isTribeTarget) {
    return s;
  }
  // Refs #2847 Phase 3 diplomacy declare-war NW-tribe bonus wiring: scale the
  // NW-tribe dominance / priority-over-OW-minor addends by the soft-phase NW
  // acquisition weight (`ctx.nwAcquisitionWeight`) instead of applying their
  // full magnitudes on the binary `colonialPressure` (weight > 0) gate. The
  // active phase now biases the magnitude of these NW-acquisition score
  // contributions along the continuous weight curve (requirement
  // clarification #1/#2/#6) — at the early-sprint default curve (0.05 at
  // OW <= 7) the addends collapse to a token nudge so the OW conquest sprint
  // stays dominant and the gp1/gp2 +6 OW baseline holds by construction; the
  // § Resource-need override floors keep a proportionate NW-tribe bias for
  // treasury / zero-regiment locked GPs. See
  // `SPEC/ai/phase-planner-architecture.md` § Phase 3 consumer wiring —
  // diplomacy declare-war NW scoring.
  s += declareWarColonialNwTribeDominanceBonus(
    nwAcquisitionWeight: ctx.nwAcquisitionWeight,
  );
  if (ctx.stalledOwExpansion &&
      !ctx.hasInvadableMinorOwner &&
      !ctx.atWarInvadableOwMinor) {
    s += declareWarColonialNwTribePriorityOverOwMinorBonus(
      nwAcquisitionWeight: ctx.nwAcquisitionWeight,
    );
  }
  return s;
}

int _declareWarStalledOldWorldExpansionBonuses(
  DeclareWarTargetContext ctx,
  int s,
) {
  // Reuse the precomputed [DeclareWarTargetContext.stalledOwExpansion] field
  // (built once from the same `snapshot.conquest.oldWorldProvincesOwned`)
  // instead of recomputing the observer expansion-pressure predicate inline
  // (Refs #3717 diplomatic-scoring dedup).
  final observerExpansionPressure = ctx.stalledOwExpansion;
  final hasInvadableOldWorld =
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  if (!observerExpansionPressure || !hasInvadableOldWorld) {
    return s;
  }
  if (ctx.isAdjacentInvadableOwMinor) {
    s += owConquestDeclareWarBonus(
      ctx,
      kDeclareWarStalledOwMinorPriorityBonus,
    );
    s += owConquestDeclareWarBonus(ctx, stalledOwMinorRecoveryBonus(ctx));
    if (ctx.lowWarLikelihood) {
      s += owConquestDeclareWarBonus(
        ctx,
        kDeclareWarLowWarLikelihoodAdjacentBonus,
      );
    }
  }
  if (ctx.isTribeTarget && !ctx.ownsInvadableNw) {
    s -= kDeclareWarStalledExpansionTribePenalty;
  }
  return s;
}

int _declareWarEarlyExpansionBonuses(DeclareWarTargetContext ctx, int s) {
  // Reuse the precomputed [DeclareWarTargetContext.stalledOwExpansion] field
  // rather than recomputing the observer expansion-pressure predicate inline
  // (Refs #3717 diplomatic-scoring dedup).
  final observerExpansionPressure = ctx.stalledOwExpansion;
  final hasInvadableOldWorld =
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  if (ctx.currentTurn > kDeclareWarEarlyExpansionMaxTurn ||
      !ctx.anyMinorOwnsOldWorld ||
      !observerExpansionPressure ||
      !hasInvadableOldWorld) {
    return s;
  }
  if (ctx.isAdjacentInvadableOwMinor) {
    s += owConquestDeclareWarBonus(ctx, kDeclareWarEarlyExpansionMinorBonus);
  }
  if (ctx.isTribeTarget && !ctx.ownsInvadableNw) {
    s -= kDeclareWarEarlyExpansionTribePenalty;
  }
  return s;
}

int _declareWarColonialPressureOwMinorPenalty(
  DeclareWarTargetContext ctx,
  int s,
) {
  if (!ctx.colonialPressure ||
      !ctx.isMinorTarget ||
      ctx.isTribeTarget ||
      ctx.ownsInvadableNw) {
    return s;
  }
  s -= kDeclareWarColonialPressureOwMinorPenalty;
  if (ctx.stalledOwExpansion && ctx.ownsInvadableOwMinor) {
    s -= kDeclareWarColonialPressureOwMinorPenalty;
  }
  return s;
}

int _declareWarExpansionAndColonialBonuses(
  DeclareWarTargetContext ctx,
  int s,
) {
  if (ctx.ownsInvadableNw && ctx.isMinorTarget && !ctx.stalledOwExpansion) {
    s += kDeclareWarColonialInvadableOwnerBonus;
  }
  s = _declareWarColonialNwTribeBonuses(ctx, s);
  s = _declareWarStalledOldWorldExpansionBonuses(ctx, s);
  s = _declareWarEarlyExpansionBonuses(ctx, s);
  s = _declareWarColonialPressureOwMinorPenalty(ctx, s);
  if (ctx.isColonialAdjacentOwner && ctx.isTribeTarget) {
    s += kDeclareWarColonialAdjacentTribeBonus;
  }
  return s;
}

