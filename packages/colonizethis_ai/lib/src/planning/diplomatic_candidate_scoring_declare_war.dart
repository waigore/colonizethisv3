part of 'diplomatic_candidate_scoring.dart';

int _scoreDeclareWarDiplomaticOrder({
  required DiplomaticOrder order,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required String agendaId,
  required PersonalityThresholds thresholds,
  required int maxRelationForDeclareWar,
  required bool behindVictoryPace,
  required bool suppressGpDeclareWar,
  required Set<String> invadableOwners,
  required Map<String, String> provinceOwner,
  required int warCooldownTurns,
  required int currentTurn,
  required bool anyMinorOwnsOldWorld,
  required StrategicGoal? primaryGoal,
  required int Function(String targetFactionId, int relationScore)
  warDesireForTarget,
  Orders? sameTurnPriorDiplomaticOrders,
  PhasePlanOutcome? phasePlan,
}) {
  final ctx = _DeclareWarTargetContext.build(
    order: order,
    nationId: nationId,
    game: game,
    snapshot: snapshot,
    thresholds: thresholds,
    maxRelationForDeclareWar: maxRelationForDeclareWar,
    behindVictoryPace: behindVictoryPace,
    suppressGpDeclareWar: suppressGpDeclareWar,
    invadableOwners: invadableOwners,
    provinceOwner: provinceOwner,
    warCooldownTurns: warCooldownTurns,
    currentTurn: currentTurn,
    anyMinorOwnsOldWorld: anyMinorOwnsOldWorld,
    primaryGoal: primaryGoal,
    warDesireForTarget: warDesireForTarget,
    agendaId: agendaId,
    phasePlan: phasePlan,
  );
  final suppressed = _declareWarSuppressedScore(
    ctx,
    sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
  );
  if (suppressed != null) {
    return suppressed;
  }
  return _scoreDeclareWarBonuses(ctx);
}

final class _DeclareWarTargetContext {
  _DeclareWarTargetContext._({
    required this.order,
    required this.nationId,
    required this.game,
    required this.snapshot,
    required this.agendaId,
    required this.thresholds,
    required this.maxRelationForDeclareWar,
    required this.behindVictoryPace,
    required this.suppressGpDeclareWar,
    required this.invadableOwners,
    required this.provinceOwner,
    required this.warCooldownTurns,
    required this.currentTurn,
    required this.anyMinorOwnsOldWorld,
    required this.primaryGoal,
    required this.warDesireForTarget,
    required this.relation,
    required this.relationScore,
    required this.adjacentOwners,
    required this.isAdjacentOwner,
    required this.isColonialAdjacentOwner,
    required this.isMinorTarget,
    required this.ownsInvadableNw,
    required this.colonialPressure,
    required this.nwAcquisitionWeight,
    required this.oldWorldConquestWeight,
    required this.isTribeTarget,
    required this.stalledOwExpansion,
    required this.ownsInvadableOwMinor,
    required this.weakerDistantMinor,
    required this.hasInvadableMinorOwner,
    required this.minorsHoldOldWorldProvinces,
    required this.atWarInvadableOwMinor,
    required this.activeMinorConflicts,
    required this.hasAdjacentInvadableMinorOwner,
    required this.isAdjacentGp,
    required this.invadableGpBlocker,
    required this.invadableGpBlockerWeaker,
    required this.invadableOwOwnedByGp,
    required this.tribeOwnsOwInvadable,
    required this.phasePlan,
  });

  final DiplomaticOrder order;
  final String nationId;
  final Game game;
  final AIWorldSnapshot snapshot;
  final String agendaId;
  final PersonalityThresholds thresholds;
  final int maxRelationForDeclareWar;
  final bool behindVictoryPace;
  final bool suppressGpDeclareWar;
  final Set<String> invadableOwners;
  final Map<String, String> provinceOwner;
  final int warCooldownTurns;
  final int currentTurn;
  final bool anyMinorOwnsOldWorld;
  final StrategicGoal? primaryGoal;
  final int Function(String targetFactionId, int relationScore)
  warDesireForTarget;
  final DiplomacyRelation? relation;
  final int relationScore;
  final List<String> adjacentOwners;
  final bool isAdjacentOwner;
  final bool isColonialAdjacentOwner;
  final bool isMinorTarget;
  final bool ownsInvadableNw;
  final bool colonialPressure;

  /// Soft-phase NW acquisition weight for the active player turn (Refs
  /// #2847 Phase 3 diplomacy declare-war wiring). Sourced from
  /// `resolvePhaseDiplomacyDeclareWarColonialPressureWeight(phasePlan)`
  /// when a [PhasePlanOutcome] is threaded through, otherwise mapped
  /// from the legacy boolean
  /// `shouldSuppressNewWorldDeclareWarInvasionAndPurchase` (`true ->
  /// 0.0`, `false -> 1.0`) so callers without a phase plan keep the
  /// pre-soft-phase hard-suppress semantics.
  ///
  /// Consumed by `_declareWarSuppressedExpandColonialScore`,
  /// `_declareWarSuppressedColonialLiteScore`, and the
  /// `_declareWarSuppressedWarConcentrationScore` colonial-pressure
  /// carve-out: when `nwAcquisitionWeight <= 0.0` the NW colonial
  /// declare-war candidates (tribe / NW owner / colonial-adjacent
  /// owner) collapse to `kDeclareWarNonAdjacentSuppressedScore`
  /// (legacy hard-suppress equivalent); when `> 0.0` the NW candidates
  /// remain scorable and the colonial-pressure carve-out preserves
  /// stalled-OW tribe declare-war scoring. The default soft-phase
  /// curve never produces `0.0` (min `0.05` at OW≤7) so the production
  /// hot path now keeps NW declare-war reachable at low priority
  /// instead of being structurally collapsed under EXPAND /
  /// COLONIAL-lite (Refs #2847 § Soft-phase priority weights).
  final double nwAcquisitionWeight;

  /// Soft-phase OW conquest weight for the active player turn (Refs
  /// #2847 Phase 3 diplomacy declare-war OW scoring). Sourced from
  /// `resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(phasePlan)`
  /// when a [PhasePlanOutcome] is threaded through; callers without a
  /// phase plan use `1.0` (legacy full-magnitude OW bonuses).
  ///
  /// Consumed by `_scoreDeclareWarBonuses` via
  /// [declareWarOldWorldConquestScaledBonus] on OW-expansion addends
  /// (stalled-OW minor priority, adjacent invadable minor bonuses,
  /// invadable-GP-blocker bonuses, score floors). NW-tribe addends use
  /// [nwAcquisitionWeight] instead.
  final double oldWorldConquestWeight;

  final bool isTribeTarget;

  /// Whether the active player's Old-World expansion is under observer
  /// conquest expansion pressure
  /// (`isObserverConquestExpansionPressure(snapshot.conquest
  /// .oldWorldProvincesOwned)`), computed once in [build].
  ///
  /// Single source of truth for the observer expansion-pressure projection in
  /// the declare-war scoring family: the suppression and bonus branches read
  /// this precomputed field instead of recomputing the predicate inline (Refs
  /// #3717 diplomatic-scoring dedup), avoiding redundant per-branch
  /// recomputation on the hot planning path
  /// (`colonizethis-turn-resolution-budget.mdc`).
  final bool stalledOwExpansion;
  final bool ownsInvadableOwMinor;
  final bool weakerDistantMinor;
  final bool hasInvadableMinorOwner;
  final bool minorsHoldOldWorldProvinces;
  final bool atWarInvadableOwMinor;
  final Set<String> activeMinorConflicts;
  final bool hasAdjacentInvadableMinorOwner;
  final bool isAdjacentGp;
  final bool invadableGpBlocker;
  final bool invadableGpBlockerWeaker;
  final bool invadableOwOwnedByGp;
  final bool tribeOwnsOwInvadable;

  /// Optional dispatched phase plan threaded from
  /// `runDiplomacyPlannerWithResult`. When non-null, the suppression
  /// scoring branches (`_declareWarSuppressedDevelopPhaseScore`,
  /// `_declareWarSuppressedColonialLiteScore`,
  /// `_declareWarSuppressedExpandColonialScore`) read the active phase
  /// off this single dispatched value via the
  /// `resolvePhaseDiplomacyDeclareWar*Suppression*Active` resolvers
  /// instead of recomputing `observerGoalPhaseFor` per candidate.
  ///
  /// `null` preserves the legacy per-candidate phase compute for tests
  /// and other callers that pre-date the orchestrator threading; the
  /// orchestrator always passes `phasePlan` so production runs route
  /// through the phase-derived value (Refs #2509 S5).
  final PhasePlanOutcome? phasePlan;

  /// Whether the declare-war target is a Great Power (a [Player] entry in
  /// [game]) rather than a minor nation or tribe.
  ///
  /// Single source of truth for the `game.playerById(order.targetFactionId)
  /// != null` projection repeated across the declare-war suppression and
  /// bonus scoring branches (Refs #3717 diplomatic-scoring dedup). Pure
  /// projection over [game] / [order]; byte-identical to the inline checks it
  /// replaces (Refs #2509 Must-have #7).
  bool get targetIsGreatPower => game.playerById(order.targetFactionId) != null;

  /// Whether the active player is *not* already at war with the declare-war
  /// target.
  ///
  /// Single source of truth for the
  /// `!snapshot.threats.atWarWith.contains(order.targetFactionId)` guard
  /// repeated across the adjacent-GP and war-concentration suppression
  /// branches (Refs #3717 diplomatic-scoring dedup). Pure projection over
  /// [snapshot] / [order]; byte-identical to the inline checks it replaces
  /// (Refs #2509 Must-have #7).
  bool get targetNotAlreadyAtWar =>
      !snapshot.threats.atWarWith.contains(order.targetFactionId);

  /// Whether the target is an adjacent, invadable Old-World minor nation: a
  /// non-tribe minor the active player borders and can currently invade.
  ///
  /// Single source of truth for the
  /// `isMinorTarget && !isTribeTarget && isAdjacentOwner &&
  /// invadableOwners.contains(order.targetFactionId)` projection repeated
  /// across the declare-war OW-conquest bonus branches (Refs #3717
  /// diplomatic-scoring dedup). Equivalent to
  /// `isAdjacentOwner && ownsInvadableOwMinor` — [ownsInvadableOwMinor]
  /// already folds the minor / non-tribe / invadable trio — so this getter is
  /// a pure projection over precomputed fields and is byte-identical to the
  /// inline checks it replaces (Refs #2509 Must-have #7).
  bool get isAdjacentInvadableOwMinor =>
      isAdjacentOwner && ownsInvadableOwMinor;

  /// Whether the declare-war target faction currently owns at least one of the
  /// active player's invadable Old-World provinces.
  ///
  /// Single source of truth for the
  /// `invadableOwners.contains(order.targetFactionId)` projection repeated
  /// across the declare-war suppression and bonus scoring branches (Refs #3717
  /// diplomatic-scoring dedup). Pure projection over [invadableOwners] /
  /// [order]; byte-identical to the inline checks it replaces (Refs #2509
  /// Must-have #7).
  bool get targetIsInvadableOwner =>
      invadableOwners.contains(order.targetFactionId);

  /// Number of provinces the declare-war target faction currently owns.
  ///
  /// Single source of truth for the
  /// `provinceCountOwnedBy(game, order.targetFactionId)` projection repeated
  /// across the declare-war suppression and bonus scoring branches (Refs #3717
  /// declare-war OW-conquest scoring-skeleton dedup). Backed by the O(1)
  /// memoised [ProvinceOwnerCache.countOwnedBy] lookup, so reading it is a pure
  /// projection over [game] / [order]; byte-identical to the inline calls it
  /// replaces (Refs #2509 Must-have #7).
  int get targetProvinceCount =>
      provinceCountOwnedBy(game, order.targetFactionId);

  /// Whether the active player's war-likelihood personality threshold is at or
  /// below the declare-war low-war-likelihood band
  /// (`thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold`).
  ///
  /// Single source of truth for the low-war-likelihood predicate repeated
  /// across the declare-war suppression and bonus scoring branches (Refs #3717
  /// diplomatic-scoring dedup). Pure projection over [thresholds];
  /// byte-identical to the inline comparisons it replaces (Refs #2509
  /// Must-have #7).
  bool get lowWarLikelihood =>
      thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold;

  factory _DeclareWarTargetContext.build({
    required DiplomaticOrder order,
    required String nationId,
    required Game game,
    required AIWorldSnapshot snapshot,
    required String agendaId,
    required PersonalityThresholds thresholds,
    required int maxRelationForDeclareWar,
    required bool behindVictoryPace,
    required bool suppressGpDeclareWar,
    required Set<String> invadableOwners,
    required Map<String, String> provinceOwner,
    required int warCooldownTurns,
    required int currentTurn,
    required bool anyMinorOwnsOldWorld,
    required StrategicGoal? primaryGoal,
    required int Function(String targetFactionId, int relationScore)
    warDesireForTarget,
    PhasePlanOutcome? phasePlan,
  }) {
    final relation = snapshot.relations[order.targetFactionId];
    final relationScore = relation?.score ?? 50;
    final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
    final colonialAdjacent =
        snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted;
    final isAdjacentOwner = adjacentOwners.contains(order.targetFactionId);
    final isColonialAdjacentOwner = colonialAdjacent.contains(
      order.targetFactionId,
    );
    final isMinorTarget = isMinorOrTribeFaction(game, order.targetFactionId);
    final ownsInvadableNw = snapshot.colonial.invadableNewWorldProvinceIdsSorted
        .any((pid) => provinceOwner[pid] == order.targetFactionId);
    // Refs #2847 Phase 3 diplomacy wiring: derive the NW acquisition
    // weight from the dispatched phase plan when available, and
    // collapse the legacy COLONIAL-only `colonialPressure` boolean to
    // `nwAcquisitionWeight > 0.0` so the colonial-pressure carve-out
    // in `_declareWarSuppressedWarConcentrationScore` scales continuously
    // with the soft-phase NW priority instead of switching on/off at
    // the EXPAND→COLONIAL boundary
    // (`SPEC/ai/phase-planner-architecture.md` § Soft-phase priority
    // weights). Falls back to the legacy three-predicate compute when no
    // phase plan was threaded through (test paths and other callers);
    // the orchestrator always passes `phasePlan` so production runs
    // route through the weight-derived value. The legacy path retires
    // structurally once every consumer migrates.
    final nwAcquisitionWeight = phasePlan != null
        ? resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
            phasePlan: phasePlan,
          )
        : (hasColonialAcquisitionTargets(snapshot.colonial) &&
                  !isStalledOldWorldGpBlockerFocus(
                    game: game,
                    snapshot: snapshot,
                  ) &&
                  !shouldSuppressNewWorldColonialOrders(
                    snapshot: snapshot,
                    game: game,
                  )
              ? 1.0
              : 0.0);
    final colonialPressure = nwAcquisitionWeight > 0.0;
    final oldWorldConquestWeight = phasePlan != null
        ? resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
            phasePlan: phasePlan,
          )
        : 1.0;
    final isTribeTarget = isTribeFaction(game, order.targetFactionId);
    final stalledOwExpansion = isObserverConquestExpansionPressure(
      snapshot.conquest.oldWorldProvincesOwned,
    );
    final ownsInvadableOwMinor =
        isMinorTarget &&
        !isTribeTarget &&
        invadableOwners.contains(order.targetFactionId);
    final minorProvinces = isMinorTarget && !isTribeTarget
        ? provinceCountOwnedBy(game, order.targetFactionId)
        : 0;
    final weakerDistantMinor =
        stalledOwExpansion &&
        behindVictoryPace &&
        isMinorTarget &&
        !isTribeTarget &&
        !isAdjacentOwner &&
        !invadableOwners.contains(order.targetFactionId) &&
        !isColonialAdjacentOwner &&
        !ownsInvadableNw &&
        minorProvinces > 0 &&
        minorProvinces < snapshot.conquest.oldWorldProvincesOwned;
    final hasInvadableMinorOwner = invadableOwners.any(
      (id) => isMinorFaction(game, id),
    );
    final ownerCache = ProvinceOwnerCache.of(game.worldState);
    final minorsHoldOldWorldProvinces = game.minorNations.any(
      (m) => ownerCache.ownsAnyInRegion(m.id, kRegionOldWorld),
    );
    final atWarInvadableOwMinor = snapshot.threats.atWarWith.any(
      (factionId) =>
          isMinorFaction(game, factionId) &&
          invadableOwners.contains(factionId),
    );
    final activeMinorConflicts = _activeOldWorldMinorConflictIds(
      game: game,
      nationId: nationId,
      currentTurn: currentTurn,
      warCooldownTurns: warCooldownTurns,
    );
    final hasAdjacentInvadableMinorOwner = adjacentOwners.any(
      (id) =>
          isMinorFaction(game, id) &&
          invadableOwners.contains(id),
    );
    final isAdjacentGp =
        isAdjacentOwner && game.playerById(order.targetFactionId) != null;
    final invadableGpBlocker =
        game.playerById(order.targetFactionId) != null &&
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: provinceOwner,
          factionId: order.targetFactionId,
        );
    final invadableGpBlockerWeaker =
        invadableGpBlocker &&
        provinceCountOwnedBy(game, order.targetFactionId) <=
            snapshot.conquest.oldWorldProvincesOwned;
    final invadableOwOwnedByGp = anyInvadableProvinceOwnedByGreatPower(
      game: game,
      snapshot: snapshot,
      provinceOwner: provinceOwner,
    );
    final tribeOwnsOwInvadable =
        isTribeTarget &&
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: provinceOwner,
          factionId: order.targetFactionId,
        );
    return _DeclareWarTargetContext._(
      order: order,
      nationId: nationId,
      game: game,
      snapshot: snapshot,
      agendaId: agendaId,
      thresholds: thresholds,
      maxRelationForDeclareWar: maxRelationForDeclareWar,
      behindVictoryPace: behindVictoryPace,
      suppressGpDeclareWar: suppressGpDeclareWar,
      invadableOwners: invadableOwners,
      provinceOwner: provinceOwner,
      warCooldownTurns: warCooldownTurns,
      currentTurn: currentTurn,
      anyMinorOwnsOldWorld: anyMinorOwnsOldWorld,
      primaryGoal: primaryGoal,
      warDesireForTarget: warDesireForTarget,
      relation: relation,
      relationScore: relationScore,
      adjacentOwners: adjacentOwners,
      isAdjacentOwner: isAdjacentOwner,
      isColonialAdjacentOwner: isColonialAdjacentOwner,
      isMinorTarget: isMinorTarget,
      ownsInvadableNw: ownsInvadableNw,
      colonialPressure: colonialPressure,
      nwAcquisitionWeight: nwAcquisitionWeight,
      oldWorldConquestWeight: oldWorldConquestWeight,
      isTribeTarget: isTribeTarget,
      stalledOwExpansion: stalledOwExpansion,
      ownsInvadableOwMinor: ownsInvadableOwMinor,
      weakerDistantMinor: weakerDistantMinor,
      hasInvadableMinorOwner: hasInvadableMinorOwner,
      minorsHoldOldWorldProvinces: minorsHoldOldWorldProvinces,
      atWarInvadableOwMinor: atWarInvadableOwMinor,
      activeMinorConflicts: activeMinorConflicts,
      hasAdjacentInvadableMinorOwner: hasAdjacentInvadableMinorOwner,
      isAdjacentGp: isAdjacentGp,
      invadableGpBlocker: invadableGpBlocker,
      invadableGpBlockerWeaker: invadableGpBlockerWeaker,
      invadableOwOwnedByGp: invadableOwOwnedByGp,
      tribeOwnsOwInvadable: tribeOwnsOwInvadable,
      phasePlan: phasePlan,
    );
  }
}

/// Returns a suppressed score when declare-war should not proceed; null = score.
int? _declareWarSuppressedScore(
  _DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  return _declareWarSuppressedDevelopPhaseScore(ctx) ??
      _declareWarSuppressedColonialLiteScore(ctx) ??
      _declareWarSuppressedExpandColonialScore(ctx) ??
      _declareWarSuppressedStalledOwFrontierScore(ctx) ??
      _declareWarSuppressedAdjacentGpScore(
        ctx,
        sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
      ) ??
      _declareWarSuppressedWarConcentrationScore(
        ctx,
        sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
      ) ??
      _declareWarSuppressedRelationAndCooldownScore(ctx);
}

int? _declareWarSuppressedDevelopPhaseScore(_DeclareWarTargetContext ctx) {
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
/// `_declareWarSuppressedExpandColonialScore` and
/// `_declareWarSuppressedColonialLiteScore` express identically: when the
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
int? _declareWarSuppressedNwColonialScore(_DeclareWarTargetContext ctx) {
  if (ctx.nwAcquisitionWeight > 0.0) {
    return null;
  }
  if (ctx.isTribeTarget || ctx.ownsInvadableNw || ctx.isColonialAdjacentOwner) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  return null;
}

int? _declareWarSuppressedExpandColonialScore(_DeclareWarTargetContext ctx) {
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
  // 0.0) from `_DeclareWarTargetContext.build`, preserving the
  // pre-soft-phase behaviour for tests and other entry points. The
  // soft-phase NW-weight predicate body is shared with the COLONIAL-lite
  // branch via `_declareWarSuppressedNwColonialScore` (Refs #3717).
  return _declareWarSuppressedNwColonialScore(ctx);
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
// The function mirrors `_declareWarSuppressedExpandColonialScore`: suppress
// only NW colonial targets (tribe, NW owner, colonial-adjacent owner) — not
// every declare-war candidate — so the COLONIAL-lite allow list
// ("establishOverture, colonial naval/cargo") is unaffected and the rule
// stays distinct from the broader DEVELOP suppression
// (`_declareWarSuppressedDevelopPhaseScore`).
int? _declareWarSuppressedColonialLiteScore(_DeclareWarTargetContext ctx) {
  // Refs #2847 Phase 3 diplomacy wiring: collapsed to the same soft-phase
  // NW-weight predicate as `_declareWarSuppressedExpandColonialScore`.
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
  // `_DeclareWarTargetContext.build`. The soft-phase NW-weight predicate
  // body is shared with the EXPAND branch via
  // `_declareWarSuppressedNwColonialScore` (Refs #3717).
  return _declareWarSuppressedNwColonialScore(ctx);
}

int? _declareWarSuppressedStalledOwFrontierScore(_DeclareWarTargetContext ctx) {
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
          (ctx.targetIsGreatPower &&
              !ctx.invadableGpBlocker) ||
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
            _minorOwnsOldWorldProvinces(ctx.game, ctx.order.targetFactionId))) {
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

int? _declareWarSuppressedAdjacentGpScore(
  _DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  if (ctx.order.type == DiplomaticOrderType.declareWar && ctx.isAdjacentGp) {
    final attackerOw = ctx.snapshot.conquest.oldWorldProvincesOwned;
    final targetOw = ctx.targetProvinceCount;
    if (ctx.targetIsGreatPower) {
      if (regimentCountForPlayer(ctx.game, ctx.nationId) == 0 &&
          isBelowObserverConquestQuota(attackerOw)) {
        return 0;
      }
      if (ctx.targetNotAlreadyAtWar &&
          isMutualBelowQuotaPlateauPeer(
            ownOw: attackerOw,
            partnerOw: targetOw,
          ) &&
          targetOw <= attackerOw + 1) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          isBelowObserverConquestQuota(attackerOw) &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar &&
          attackerOw >= kObserverDefaultStartOldWorldProvincesPerGp &&
          targetOw <= attackerOw) {
        return 0;
      }
      final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
        game: ctx.game,
        snapshot: ctx.snapshot,
        provinceOwner: ctx.provinceOwner,
      );
      if (minorsOwnInvadable &&
          isBelowObserverConquestQuota(attackerOw) &&
          isBelowObserverConquestQuota(targetOw) &&
          (targetOw - attackerOw).abs() <= 2 &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (attackerOw >= kObserverDefaultStartOldWorldProvincesPerGp &&
          isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1 &&
          !ctx.invadableGpBlocker) {
        return 0;
      }
      if (isBelowObserverConquestQuota(attackerOw) &&
          pendingDeclareWarFrom(
            sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
            declarerFactionId: ctx.order.targetFactionId,
            targetFactionId: ctx.nationId,
          )) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kFewOldWorldProvincesDefendThreshold &&
          !isBelowObserverConquestQuota(attackerOw) &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (!ctx.invadableGpBlocker &&
          isBelowObserverConquestQuota(targetOw) &&
          regimentCountForPlayer(ctx.game, ctx.order.targetFactionId) == 0 &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar &&
          ((!isBelowObserverConquestQuota(attackerOw)) ||
              (ctx.currentTurn <= kDeclareWarEarlyAntiDogpileMaxTurn &&
                  attackerOw > targetOw))) {
        return 0;
      }
      final belowQuotaSuppressLead =
          targetOw <= kFewOldWorldProvincesDefendThreshold
          ? 1
          : kUnwinnableSoleGpMinProvinceDeficit;
      if (isBelowObserverConquestQuota(targetOw) &&
          !ctx.invadableGpBlocker &&
          attackerOw >= targetOw + belowQuotaSuppressLead) {
        return 0;
      }
      if (targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          attackerOw > targetOw &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          attackerOw >= kObserverDefaultStartOldWorldProvincesPerGp + 1 &&
          !ctx.invadableGpBlocker) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          !isBelowObserverConquestQuota(attackerOw) &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          attackerOw > targetOw &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (!isBelowObserverConquestQuota(attackerOw) &&
          isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kStalledOldWorldProvinceThreshold &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (isBelowObserverConquestQuota(attackerOw) &&
          targetOw >= attackerOw + kUnwinnableSoleGpMinProvinceDeficit) {
        return 0;
      }
      if (isBelowObserverConquestQuota(attackerOw) &&
          attackerOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1 &&
          ctx.isAdjacentGp &&
          !ctx.invadableGpBlocker &&
          ctx.targetIsInvadableOwner &&
          targetOw > attackerOw) {
        return 0;
      }
    }
    if (!ctx.invadableGpBlocker &&
        attackerOw <= kFewOldWorldProvincesDefendThreshold &&
        targetOw > attackerOw) {
      return 0;
    }
    if (!ctx.invadableGpBlocker &&
        attackerOw <= kFewOldWorldProvincesDefendThreshold &&
        ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
        ctx.targetNotAlreadyAtWar) {
      return 0;
    }
  }
  if (ctx.order.type == DiplomaticOrderType.declareWar &&
      ctx.isAdjacentGp &&
      ctx.targetIsGreatPower &&
      ctx.stalledOwExpansion) {
    final targetOw = ctx.targetProvinceCount;
    if (!ctx.invadableGpBlocker &&
        targetOw <= kFewOldWorldProvincesDefendThreshold &&
        ctx.snapshot.conquest.oldWorldProvincesOwned >=
            targetOw + kDeclareWarAggressorSuppressWeakGpLeadThreshold) {
      return 0;
    }
  }
  return null;
}

int? _declareWarSuppressedWarConcentrationScore(
  _DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final atWarWithGp = isAtWarWithAnyGreatPower(ctx.game, ctx.snapshot);
  if (ctx.stalledOwExpansion &&
      atWarWithGp &&
      ctx.isAdjacentGp &&
      ctx.targetIsGreatPower &&
      ctx.targetNotAlreadyAtWar) {
    return 0;
  }
  if (ctx.isAdjacentGp &&
      ctx.targetIsGreatPower &&
      ctx.targetNotAlreadyAtWar) {
    final attackerGpWarCount =
        gpFactionIdsAtWarWith(ctx.game, ctx.snapshot).length;
    if (attackerGpWarCount >= 2) {
      return 0;
    }
    final targetGpId = ctx.order.targetFactionId;
    final targetOw = ctx.targetProvinceCount;
    final targetGpWarCount = greatPowerWarCountOnTarget(
      game: ctx.game,
      targetGpId: targetGpId,
      sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
    );
    if (targetGpWarCount >= 2) {
      return 0;
    }
    final attackerOw = ctx.snapshot.conquest.oldWorldProvincesOwned;
    if (isBelowObserverConquestQuota(targetOw) && targetGpWarCount >= 1) {
      return 0;
    }
    if (isBelowObserverConquestQuota(targetOw) &&
        attackerOw >= targetOw + 2 &&
        !ctx.invadableGpBlocker) {
      return 0;
    }
  }
  // While an invadable OW frontier has a GP blocker, do not open (or stack)
  // wars on other adjacent GPs — applies above the stalled OW band (seed-42 gp4).
  if (atWarWithGp &&
      ctx.isAdjacentGp &&
      ctx.targetIsGreatPower &&
      ctx.targetNotAlreadyAtWar &&
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      ctx.invadableGpBlocker != null &&
      ctx.order.targetFactionId != ctx.invadableGpBlocker) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableGpBlocker &&
      ctx.targetProvinceCount > ctx.snapshot.conquest.oldWorldProvincesOwned &&
      ctx.hasInvadableMinorOwner) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.isTribeTarget &&
      !ctx.tribeOwnsOwInvadable &&
      !(ctx.colonialPressure && ctx.ownsInvadableNw) &&
      (ctx.behindVictoryPace ||
          ctx.hasInvadableMinorOwner ||
          ctx.atWarInvadableOwMinor)) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (ctx.suppressGpDeclareWar &&
      ctx.isAdjacentGp &&
      !ctx.invadableGpBlocker &&
      !(ctx.stalledOwExpansion && ctx.invadableGpBlockerWeaker)) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (ctx.suppressGpDeclareWar &&
      ctx.isAdjacentGp &&
      ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.hasInvadableMinorOwner &&
      !ctx.invadableGpBlocker &&
      !ctx.invadableGpBlockerWeaker &&
      ctx.lowWarLikelihood) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  return null;
}

int? _declareWarSuppressedRelationAndCooldownScore(
  _DeclareWarTargetContext ctx,
) {
  final effectiveMaxRelation = ctx.behindVictoryPace && ctx.isMinorTarget
      ? kDeclareWarMinorMaxRelationWhenFarFromVictory
      : ctx.behindVictoryPace && ctx.isAdjacentGp
      ? kDeclareWarGpMaxRelationWhenFarFromVictory
      : ctx.maxRelationForDeclareWar;
  if (ctx.relationScore > effectiveMaxRelation) {
    return 0;
  }
  if (_isDecisionOnCooldown(
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
