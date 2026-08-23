import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'diplomatic_candidate_scoring_shared.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_diplomacy_filter.dart';
import 'planning_imports.dart';

/// Declare-war suppression helpers extracted from the score ladder
/// (Refs #4602 Slice A). Chain order is owned by
/// `diplomatic_candidate_scoring_declare_war.dart`.
int? declareWarSuppressedDevelopPhaseScore(DeclareWarTargetContext ctx) {
  // Refs #2509 S5: derive DEVELOP suppression from the dispatched phase
  // plan instead of recomputing `observerGoalPhaseFor` per declare-war
  // candidate via `isObserverDevelopPhase`. The phase dispatcher already
  // resolved `observerGoalPhaseFor` once per player turn; this branch
  // mirrors `resolvePhaseDiplomacyDeclareWarColonialPressureActive`,
  // `resolvePhaseEconomyColonialPressureActive`, and
  // `resolvePhaseConquestColonialPressureActive` by routing the phase
  // check off the dispatched `PhasePlanOutcome`. Falls back to the
  // legacy compute when no phase plan was threaded through (test paths
  // and other callers); the orchestrator always passes `phasePlan` so
  // production runs route through the phase-derived value.
  final develop = ctx.phasePlan != null
      ? resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
          phasePlan: ctx.phasePlan!,
        )
      : isObserverDevelopPhase(snapshot: ctx.snapshot, game: ctx.game);
  if (!develop) {
    return null;
  }
  return kDeclareWarNonAdjacentSuppressedScore;
}

/// Shared NW-colonial declare-war suppression skeleton (Refs #3717
/// diplomatic-scoring dedup).
///
/// Single source of truth for the soft-phase NW-weight predicate that both
/// `declareWarSuppressedExpandColonialScore` and
/// `declareWarSuppressedColonialLiteScore` express identically: when the
/// soft-phase NW acquisition weight has not collapsed
/// (`nwAcquisitionWeight > 0.0`) NW colonial targets stay scorable (`null`);
/// otherwise the NW colonial candidates (tribe, NW owner, colonial-adjacent
/// owner) collapse to [kDeclareWarNonAdjacentSuppressedScore], while non-NW
/// targets remain scorable. Both call sites previously inlined this exact
/// three-line body, so routing them through one helper is pure delegation and
/// byte-identical to the inline checks it replaces. The two distinct chain
/// entries are retained at their call sites (see each delegating function) so
/// the suppression ordering in `_declareWarSuppressedScore` and the
/// independent Phase 4 retirement paths for the EXPAND / COLONIAL-lite Phase 2
/// resolvers are unchanged.
int? declareWarSuppressedNwColonialScore(DeclareWarTargetContext ctx) {
  if (ctx.nwAcquisitionWeight > 0.0) {
    return null;
  }
  if (ctx.isTribeTarget || ctx.ownsInvadableNw || ctx.isColonialAdjacentOwner) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  return null;
}

int? declareWarSuppressedExpandColonialScore(DeclareWarTargetContext ctx) {
  // Refs #2847 Phase 3 diplomacy wiring: derive EXPAND NW-colonial
  // suppression from the soft-phase NW acquisition weight on the
  // dispatched phase plan instead of the boolean
  // `resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive`
  // (`phase == ObserverGoalPhase.expand`). The legacy hard-suppress
  // contract is preserved exactly at `nwAcquisitionWeight <= 0.0`
  // (mirroring `runConquestArmyMovePlanner`'s NW invadable-bonus zeroing
  // gate); the default soft-phase curve produces a `0.05` early-sprint
  // floor at OW<=7, so EXPAND turns now keep NW declare-war candidates
  // scorable at low priority rather than structurally collapsing them.
  // Callers without a phase plan use the legacy-derived weight (1.0 /
  // 0.0) from `DeclareWarTargetContext.build`, preserving the
  // pre-soft-phase behaviour for tests and other entry points. The
  // soft-phase NW-weight predicate body is shared with the COLONIAL-lite
  // branch via `declareWarSuppressedNwColonialScore` (Refs #3717).
  return declareWarSuppressedNwColonialScore(ctx);
}

// COLONIAL-lite NW `declareWar` suppression (Refs #2509 S10).
//
// SPEC/ai/ai-architecture.md § Observer goal phases (Full AI),
// COLONIAL-lite: "suppresses NW declareWar, invasion army moves, and
// purchase_land only". `shouldSuppressNewWorldDeclareWarInvasionAndPurchase`
// already returns true for COLONIAL-lite, and `conquest_planner.dart` uses
// it to gate army moves and `purchase_land`. The diplomatic declare-war
// scoring path previously only consulted `shouldSuppressNewWorldColonialOrders`
// (EXPAND-only) and so left NW `declareWar` reachable in COLONIAL-lite,
// allowing near-quota GPs at turn >= `kObserverColonialLiteMinTurn` to
// burn turns declaring on NW tribes before reaching the OW quota and
// regressing the canonical seed-42 `--verify-conquest` per-GP +3 OW gain
// gate at turn 100.
//
// The function mirrors `declareWarSuppressedExpandColonialScore`: suppress
// only NW colonial targets (tribe, NW owner, colonial-adjacent owner) — not
// every declare-war candidate — so the COLONIAL-lite allow list
// ("establishOverture, colonial naval/cargo") is unaffected and the rule
// stays distinct from the broader DEVELOP suppression
// (`declareWarSuppressedDevelopPhaseScore`).
int? declareWarSuppressedColonialLiteScore(DeclareWarTargetContext ctx) {
  // Refs #2847 Phase 3 diplomacy wiring: collapsed to the same soft-phase
  // NW-weight predicate as `declareWarSuppressedExpandColonialScore`.
  // Under the soft-phase curve both EXPAND and COLONIAL-lite share the
  // same low-NW-priority profile (early-sprint plateau at OW<=9), so the
  // suppression contract is "NW colonial declare-war collapses iff
  // `nwAcquisitionWeight <= 0.0`" — which is reached only when an
  // explicit phase-plan override sets the weight to `0.0` (no override
  // does so today; default curves never produce `0.0`).
  //
  // The branch remains in the suppression chain (rather than being
  // inlined into the EXPAND branch) so the structural ordering matches
  // `_declareWarSuppressedScore` and so future Phase 4 SPEC alignment
  // can retire the EXPAND / COLONIAL-lite Phase 2 boolean resolvers
  // independently of this scoring path. Callers without a phase plan
  // use the legacy-derived weight (1.0 / 0.0) from
  // `DeclareWarTargetContext.build`. The soft-phase NW-weight predicate
  // body is shared with the EXPAND branch via
  // `declareWarSuppressedNwColonialScore` (Refs #3717).
  return declareWarSuppressedNwColonialScore(ctx);
}

int? declareWarSuppressedStalledOwFrontierScore(DeclareWarTargetContext ctx) {
  if (ctx.isTribeTarget &&
      ctx.stalledOwExpansion &&
      (ctx.minorsHoldOldWorldProvinces ||
          ctx.activeMinorConflicts.isNotEmpty ||
          ctx.invadableOwOwnedByGp)) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableOwOwnedByGp &&
      !ctx.hasInvadableMinorOwner &&
      (ctx.isTribeTarget ||
          (ctx.targetIsGreatPower && !ctx.invadableGpBlocker) ||
          (ctx.isMinorTarget &&
              !ctx.isTribeTarget &&
              !ctx.weakerDistantMinor))) {
    return 0;
  }
  if (ctx.stalledOwExpansion && ctx.isMinorTarget && !ctx.isTribeTarget) {
    final continuingMinorConflict = ctx.activeMinorConflicts.contains(
      ctx.order.targetFactionId,
    );
    final adjacentInvadableMinor =
        ctx.isAdjacentOwner && ctx.targetIsInvadableOwner;
    final distantInvadableMinorOwner = ctx.targetIsInvadableOwner;
    if (ctx.activeMinorConflicts.isNotEmpty) {
      if (!continuingMinorConflict) {
        return 0;
      }
    } else if (ctx.hasAdjacentInvadableMinorOwner) {
      if (!adjacentInvadableMinor) {
        return 0;
      }
    } else if (!adjacentInvadableMinor &&
        !ctx.weakerDistantMinor &&
        !distantInvadableMinorOwner &&
        !(ctx.behindVictoryPace &&
            ctx.anyMinorOwnsOldWorld &&
            minorOwnsOldWorldProvinces(ctx.game, ctx.order.targetFactionId))) {
      return 0;
    }
  }
  if (ctx.behindVictoryPace &&
      ctx.adjacentOwners.isNotEmpty &&
      !ctx.isAdjacentOwner &&
      !ctx.isColonialAdjacentOwner &&
      !(ctx.ownsInvadableNw && ctx.isMinorTarget) &&
      !(ctx.stalledOwExpansion && ctx.ownsInvadableOwMinor) &&
      !ctx.weakerDistantMinor) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (ctx.stalledOwExpansion &&
      ctx.isAdjacentGp &&
      !ctx.invadableGpBlockerWeaker &&
      !ctx.invadableGpBlocker) {
    return 0;
  }
  return null;
}

int? declareWarSuppressedRelationAndCooldownScore(DeclareWarTargetContext ctx) {
  final effectiveMaxRelation = ctx.behindVictoryPace && ctx.isMinorTarget
      ? kDeclareWarMinorMaxRelationWhenFarFromVictory
      : ctx.behindVictoryPace && ctx.isAdjacentGp
      ? kDeclareWarGpMaxRelationWhenFarFromVictory
      : ctx.maxRelationForDeclareWar;
  if (ctx.relationScore > effectiveMaxRelation) {
    return 0;
  }
  if (isDecisionOnCooldown(
    game: ctx.game,
    actorFactionId: ctx.nationId,
    targetFactionId: ctx.order.targetFactionId,
    eventTypes: const [DiplomaticEventType.declareWar],
    cooldownTurns: ctx.warCooldownTurns,
    currentTurn: ctx.currentTurn,
  )) {
    return 0;
  }
  return null;
}
