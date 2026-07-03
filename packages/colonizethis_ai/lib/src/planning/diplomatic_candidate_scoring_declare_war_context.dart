part of 'diplomatic_candidate_scoring.dart';

/// Context builder for the declare-war scoring family.
///
/// Holds [_DeclareWarTargetContext], the precomputed per-target projection
/// consumed by the declare-war score ladder in
/// `diplomatic_candidate_scoring_declare_war.dart` and the bonus addends in
/// `diplomatic_candidate_scoring_declare_war_bonuses.dart`. Split out of the
/// score-ladder module so the context-builder and score-ladder concerns live
/// in separate files (Refs #3749). All members stay library-private `part`
/// declarations of `diplomatic_candidate_scoring.dart`; behaviour is unchanged.
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
  final int Function(String targetFactionId, num relationScore)
  warDesireForTarget;
  final DiplomacyRelation? relation;
  final num relationScore;
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
    required int Function(String targetFactionId, num relationScore)
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
