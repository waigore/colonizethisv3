part of 'colonial_phase_planner.dart';

/// Method by which a COLONIAL acquisition target should be pursued
/// (issue #2509 § COLONIAL phase planner § planColonialAcquisition).
///
/// Three methods are defined by the spec — Join Empire is the cheapest
/// path and always preferred first when available; `purchase_land`
/// applies when an idle Merchant and a valid purchase tile are present;
/// `declareWar` applies when treasury / regiments support the conquest
/// path and the target is sea-reachable. All three methods are emitted
/// by [planColonialAcquisition]; the structural priority Method 1 → 2 →
/// 3 mirrors the spec's "always preferred first" Join Empire framing
/// and the "deprioritize war behind Join Empire and purchase_land"
/// turn-110 guidance.
enum AcquisitionMethod {
  /// `establishOverture` advancing the chain to `joinEmpire`. The
  /// fastest, cheapest acquisition path (issue #2509 § Acquisition
  /// method 1).
  joinEmpire,

  /// `purchase_land` work order for an idle Merchant unit (issue
  /// #2509 § Acquisition method 2).
  purchaseLand,

  /// `declareWar` + NW army move toward a sea-reachable tribe / minor
  /// (issue #2509 § Acquisition method 3). Emitted by
  /// [planColonialAcquisition] only when Join Empire and
  /// `purchase_land` both yielded no target this turn and the active
  /// player can afford the cheapest regiment build with at least one
  /// standing regiment already in service.
  declareWar,
}

/// Deterministic acquisition target picked by [planColonialAcquisition].
///
/// Pairs the faction id owning the chosen NW province with the
/// [AcquisitionMethod] the orchestrator should use this turn. The pair
/// is stable: identical inputs always yield identical targets (Refs
/// #2509 Must-have #7). The pair is materialized as a small value
/// class (not a record) to keep value-equality semantics explicit for
/// tests and to mirror the shape of other phase-planner return types
/// under construction in this file.
class ColonialAcquisitionTarget {
  const ColonialAcquisitionTarget({
    required this.targetFactionId,
    required this.method,
  });

  /// Faction id of the tribe or minor that currently owns the chosen
  /// NW province. Never a Great Power — Join Empire toward a GP is
  /// gated by Empire Building tech and the "nearly defeated" check in
  /// the join-empire validator (see
  /// `join_empire_validator.dart`), neither of which fits the COLONIAL
  /// phase's "acquire tribe / minor NW" objective. The planner skips
  /// GP-owned NW provinces structurally.
  final String targetFactionId;

  /// Resolution path the orchestrator should use. The planner can
  /// return any of [AcquisitionMethod.joinEmpire] (Acquisition method
  /// 1), [AcquisitionMethod.purchaseLand] (Acquisition method 2), or
  /// [AcquisitionMethod.declareWar] (Acquisition method 3) per the
  /// structural Method 1 → 2 → 3 priority documented on
  /// [planColonialAcquisition].
  final AcquisitionMethod method;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColonialAcquisitionTarget &&
          targetFactionId == other.targetFactionId &&
          method == other.method;

  @override
  int get hashCode => Object.hash(targetFactionId, method);

  @override
  String toString() =>
      'ColonialAcquisitionTarget('
      'targetFactionId: $targetFactionId, method: $method)';
}

/// Returns the deterministic acquisition target for the active
/// COLONIAL player this turn, or `null` when no method is achievable.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialAcquisition,
/// Acquisition methods 1, 2, and 3):
///
///   "1. Join Empire
///      → Conditions: embassy with owning tribe, treasury ≥ cost.
///      → Generate establishOverture(tribe) targeting Join Empire chain.
///      → This is the cheapest, fastest path — always preferred first.
///    2. purchase_land
///      → Conditions: idle Merchant unit, tile has resource (prospected
///        if mineral), treasury ≥ purchase cost.
///      → Generate purchase_land work order for Merchant.
///    3. declareWar + invade
///      → Conditions: treasury ≥ regiment build cost, regiments
///        available, tribe/minor is sea-reachable.
///      → Generate declareWar(tribe) + NW army move.
///      → From turn 110: deprioritize war behind Join Empire and
///        purchase_land (fewer turns to complete)."
///
/// **Method 1 — Join Empire.** The "embassy with owning tribe" phrasing
/// in the issue body is tightened here to align with the order-engine
/// validator in
/// `packages/colonizethis_logic/lib/src/orders/validators/diplomatic/`
/// `join_empire_validator.dart`: Join Empire requires the active
/// player's overture toward the tribe / minor target to already be at
/// [OvertureStage.nap], plus a Friendly+ relation score, plus treasury
/// covering [joinEmpireCostForMinorOrTribe]. Suggesting `joinEmpire`
/// from a lower overture stage would be rejected by the validator and
/// produce no order, so the planner gates on the same `nap` precondition
/// the validator enforces. Advancing the chain through earlier stages
/// (`consulate`, `embassy`) is the responsibility of sibling overture
/// planners (`planColonialLiteOvertures` and the legacy overture
/// helpers) — Join Empire kicks in only on the terminal
/// `nap → joinEmpire` step.
///
/// **Method 2 — `purchase_land`.** Mirrors the validator-side gates in
/// `precheckPurchaseLand` (`work_order_target_prechecks.dart`) so the
/// planner never suggests a target the engine would reject:
///
///   - active player must hold at least one idle Merchant
///     ([Unit.type] == [kUnitTypeMerchant], [Unit.status] ==
///     [UnitStatus.idle]) anywhere in the world; the orchestrator and
///     resolver handle the staging movement on follow-up turns;
///   - target province owner must be a tribe / minor (not a Great
///     Power; not the active player itself);
///   - active player must not be at war with that owner
///     ([DiplomacyRelation.atWar] == false);
///   - active player must have at least an embassy-stage overture with
///     that owner ([OvertureState.hasEmbassy] == true, i.e. stage in
///     `{embassy, nap, joinEmpire}`);
///   - the province must contain at least one tile that is itself a
///     valid `purchase_land` candidate: non-empty resource id, not
///     already purchased by any GP, treasury covering
///     [purchaseLandCost], and — for mineral resource ids in
///     [kMineralResourceIds] — already in the active player's
///     prospected-tile set ([WorldState.playerProspectedTiles]).
///
/// **Method 3 — `declareWar`.** Mirrors the validator-side gate in
/// `declareWarSubValidator` (`declare_war_validator.dart`) plus the
/// spec's outer "treasury ≥ regiment build cost, regiments available"
/// preconditions:
///
///   - outer: active player must hold at least one standing regiment
///     across Home + field armies ([regimentCountForPlayer] > 0) so
///     the spec's "Generate declareWar(tribe) + NW army move"
///     follow-up has at least one unit available; without any
///     regiments the order pair cannot be fulfilled and the planner
///     would emit a target the conquest army-move pass could not
///     follow up on;
///   - outer: treasury must cover the cheapest [RegimentEconomyCatalog]
///     build cost ([_cheapestRegimentBuildTreasuryCost]) so the
///     declare-war target can be reinforced this turn or next via the
///     economy build pass (matches the symmetric gate in
///     `planExpandDeclareWar` for the EXPAND below-quota declare-war
///     path);
///   - per-province: owner must be a tribe / minor (GPs structurally
///     excluded via `game.playerById(ownerId) != null`, same skip as
///     Methods 1 and 2; declareWar against a GP is COLONIAL's
///     `planColonialMilitary` declared-target arm, not an acquisition
///     decision);
///   - per-province: active player must not already be at war with
///     that owner — the order-engine validator rejects with "Already
///     at war with that faction" when [RelationState.atWar]. The
///     planner matches the validator's `atPeace` framing by
///     accepting a `null` relation row (no prior diplomatic record)
///     while skipping any row with [DiplomacyRelation.atWar] true.
///     Already-at-war tribes / minors are pursued by
///     [planColonialMilitary]'s declared-target / at-war fallback
///     arms instead.
///
/// Sea reachability is enforced **structurally** by the per-province
/// iteration: every candidate appears in
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted], which the
/// perception-snapshot builder restricts to provinces reachable from
/// owned anchors via [reachableNonOwnedProvinceIdsViaSeas]. A tribe /
/// minor that owns no sea-reachable NW invadable province therefore
/// never enters the iteration and cannot become a declareWar target;
/// no separate topology probe is required at the planner level.
///
/// The Method 1 pass scans every NW invadable province first; if no
/// Join Empire target is reachable, the Method 2 pass scans the same
/// list with the `purchase_land` gate set; if neither pass yields a
/// target, the Method 3 pass scans the same list with the declareWar
/// gate set. This implements the spec "Join Empire is always
/// preferred first" plus "deprioritize war behind Join Empire and
/// purchase_land" by structural priority — the cheaper paths always
/// run before the costlier conquest path. The turn-110 inversion the
/// spec mentions is therefore a no-op for today's planner: declareWar
/// is already last-resort across every turn.
///
/// Iteration ordering:
///   - Walks [ColonialSummary.invadableNewWorldProvinceIdsByDistance]
///     in BFS-distance order (nearest invadable NW province to the
///     active player's territory first, ascending province id as a
///     deterministic tiebreaker among equal-distance candidates).
///     This matches the spec wording "sorted by adjacency distance
///     to owned territory" (Refs #2509 § planColonialAcquisition).
///     Distance is measured as topology edges (province <-> province
///     borders count as 1; province <-> seaZone <-> province via the
///     canonical NW colonial route counts as 2). The
///     perception-snapshot builder derives this list from
///     [reachableNonOwnedProvinceDistancesViaSeas]; when the snapshot
///     was built without a [MapTopology] (e.g. synthetic unit-test
///     fixtures) the planner falls back to
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (lex
///     order) so legacy fixtures stay deterministic without
///     re-plumbing topology through every test setup.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard, looks up the province-owner map
///     ([getProvinceOwnerMap]) to find each NW province's current
///     owner, queries [getOverture] / [getRelation] for the gate
///     evaluation, and computes [joinEmpireCostForMinorOrTribe] /
///     [purchaseLandCost] for the treasury check. The Method 2 pass
///     also reads [WorldState.playerProspectedTiles],
///     [WorldState.purchasedTilesByTileKey], and
///     [WorldState.resourceByTileKey] to validate per-tile gates.
///     The Method 3 pass reads
///     [WorldState.armies] (via [regimentCountForPlayer]) for the
///     standing-regiment gate and scans [RegimentEconomyCatalog] for
///     the cheapest build cost.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (the
///     candidate NW province pool) and [EconomySummary.treasury] (the
///     active player's spendable cash for the acquisition payment).
///
/// Output:
///   - [ColonialAcquisitionTarget] with [AcquisitionMethod.joinEmpire]
///     when the first NW province in
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] whose
///     owner satisfies the four Join-Empire gates (overture stage =
///     [OvertureStage.nap], relation score ≥ [relationScoreMinFriendly],
///     treasury ≥ [joinEmpireCostForMinorOrTribe], owner is a
///     tribe / minor and not a Great Power).
///   - [ColonialAcquisitionTarget] with
///     [AcquisitionMethod.purchaseLand] when no Join-Empire target is
///     reachable but the active player has at least one idle Merchant
///     and the first NW province in the sorted list whose owner
///     satisfies the embassy + non-war gates also contains at least
///     one tile satisfying the per-tile `purchase_land` gates.
///   - [ColonialAcquisitionTarget] with [AcquisitionMethod.declareWar]
///     when neither Join Empire nor `purchase_land` yields a target,
///     the active player holds at least one standing regiment and
///     treasury covering [_cheapestRegimentBuildTreasuryCost], and
///     the first NW province in the sorted list is owned by a
///     tribe / minor the active player is not yet at war with.
///   - `null` when no NW province satisfies any acquisition method,
///     or when the outer guards trip (missing active player record,
///     empty NW invadable list). Consumers should treat `null` as
///     "no acquisition order this turn" rather than "acquisition
///     path impossible".
///
/// **Personality bias (Must-have #4 / `SPEC/ai/phase-planner-architecture.md`
/// § Personality bias):** when [personalityId] resolves to a personality
/// whose `warLikelihood > allianceTendency` (currently `napoleon`,
/// `isabella`, `frederick`, `gustavus`; see `personalityThresholds` in
/// `ai_personality_config.dart`), the planner prefers
/// [AcquisitionMethod.declareWar] over [AcquisitionMethod.joinEmpire] for
/// the same tribe within the structural priority order — concretely, the
/// declareWar pass runs **before** the Join Empire pass. The
/// `purchase_land` pass position is unchanged. Diplomatic / neutral
/// personalities (and the default `personalityId == null` legacy
/// behaviour) keep `Join Empire > purchase_land > declareWar`.
/// Outer declareWar gates (regiments ≥ 1, treasury ≥ cheapest regiment
/// cost) and per-province non-war gates still apply identically in both
/// orderings, so a militaristic personality with no regiments still
/// falls through to Join Empire / purchase_land. The function remains
/// pure: the personality input enters only as a deterministic
/// comparison between two integer threshold fields.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ColonialAcquisitionTarget]s (Refs #2509
/// Must-have #7).
ColonialAcquisitionTarget? planColonialAcquisition({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? personalityId,
  expand_phase_planner.ExpandEconomyPlan expandEconomyPlan =
      expand_phase_planner.ExpandEconomyPlan.defaultPlan,
}) {
  if (game.playerById(snapshot.playerId) == null) {
    return null;
  }
  final invadable = _acquisitionIterationOrder(snapshot.colonial);
  if (invadable.isEmpty) {
    return null;
  }

  final provinceOwner = getProvinceOwnerMap(game);
  final treasury = snapshot.economy.treasury;
  // Own-colony exclusion (Refs #3758 R4 / S3; SPEC/ai/phase-planner-architecture.md
  // § Own-colony exclusion): tribes that are already this player's colony stay
  // in the game and keep owning NW provinces, so they remain in the invadable
  // list. Skip them across every acquisition arm so the planner never
  // re-targets, re-buys land in, or declares war on its own colony.
  final ownColonyTribeIds = _ownColonyTribeIds(game, snapshot.playerId);
  final preferDeclareWarOverJoinEmpire = _personalityPrefersWarOverAlliance(
    personalityId,
  );

  ColonialAcquisitionTarget? tryJoinEmpire() => _findJoinEmpireTarget(
    game: game,
    snapshot: snapshot,
    invadable: invadable,
    provinceOwner: provinceOwner,
    treasury: treasury,
    ownColonyTribeIds: ownColonyTribeIds,
  );
  ColonialAcquisitionTarget? tryPurchaseLand() => _findPurchaseLandTarget(
    game: game,
    snapshot: snapshot,
    invadable: invadable,
    provinceOwner: provinceOwner,
    treasury: treasury,
    ownColonyTribeIds: ownColonyTribeIds,
  );
  final waiveDeclareWarTreasuryGate = isNwLockRecoveryPathEActive(
    snapshot: snapshot,
    expandEconomyPlan: expandEconomyPlan,
  );
  ColonialAcquisitionTarget? tryDeclareWar() => _findDeclareWarTarget(
    game: game,
    snapshot: snapshot,
    invadable: invadable,
    provinceOwner: provinceOwner,
    treasury: treasury,
    waiveTreasuryGate: waiveDeclareWarTreasuryGate,
    ownColonyTribeIds: ownColonyTribeIds,
  );

  if (preferDeclareWarOverJoinEmpire) {
    return tryDeclareWar() ?? tryJoinEmpire() ?? tryPurchaseLand();
  }
  return tryJoinEmpire() ?? tryPurchaseLand() ?? tryDeclareWar();
}

/// True when [personalityId] resolves to a personality whose
/// `warLikelihood` strictly exceeds its `allianceTendency` per
/// `personalityThresholds` in `ai_personality_config.dart` — the
/// militaristic-leader bias defined in
/// `SPEC/ai/phase-planner-architecture.md` § Personality bias.
///
/// Returns `false` when [personalityId] is `null`, unknown, or
/// resolves to a personality whose thresholds are equal or
/// alliance-leaning (`warLikelihood <= allianceTendency`). The
/// resolution uses [personalityLookupKeyForAi] so leader-key aliases
/// (e.g. `france_leader` → `napoleon`) map to canonical thresholds
/// before the comparison, matching the rest of `colonizethis_ai`.
///
/// Pure: depends only on the static `personalityThresholds` map in
/// `colonizethis_data` and the input string, so the comparison is
/// deterministic for fixed inputs (Refs #2509 Must-have #7).
bool _personalityPrefersWarOverAlliance(String? personalityId) {
  if (personalityId == null) return false;
  final thresholds = getThresholdsForLeader(personalityId);
  return thresholds.warLikelihood > thresholds.allianceTendency;
}

/// Iterates [invadable] in distance order and returns the first
/// [AcquisitionMethod.joinEmpire] candidate satisfying the four
/// Join-Empire gates (non-GP owner, overture stage `nap`, relation
/// score ≥ Friendly, treasury ≥ `joinEmpireCostForMinorOrTribe`).
ColonialAcquisitionTarget? _findJoinEmpireTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
  required List<String> invadable,
  required Map<String, String> provinceOwner,
  required int treasury,
  required Set<String> ownColonyTribeIds,
}) {
  for (final provinceId in invadable) {
    final ownerId = provinceOwner[provinceId];
    if (ownerId == null) continue;
    if (game.playerById(ownerId) != null) continue;
    if (ownColonyTribeIds.contains(ownerId)) continue;

    final overture = getOverture(game, snapshot.playerId, ownerId);
    if (overture == null) continue;
    if (overture.stage != OvertureStage.nap) continue;

    final relation = getRelation(game, snapshot.playerId, ownerId);
    if (relation == null || relation.score < relationScoreMinFriendly) {
      continue;
    }

    final cost = joinEmpireCostForMinorOrTribe(game, ownerId);
    if (treasury < cost) continue;

    return ColonialAcquisitionTarget(
      targetFactionId: ownerId,
      method: AcquisitionMethod.joinEmpire,
    );
  }
  return null;
}

/// Iterates [invadable] in distance order and returns the first
/// [AcquisitionMethod.purchaseLand] candidate satisfying the Method 2
/// gates (idle Merchant, embassy with owner, not at war, per-tile
/// resource + treasury gates).
ColonialAcquisitionTarget? _findPurchaseLandTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
  required List<String> invadable,
  required Map<String, String> provinceOwner,
  required int treasury,
  required Set<String> ownColonyTribeIds,
}) {
  if (!_hasIdleMerchant(game.worldState, snapshot.playerId)) {
    return null;
  }
  final prospected =
      game.worldState.playerProspectedTiles[snapshot.playerId] ??
      const <String>{};
  final purchasedByTile = game.worldState.purchasedTilesByTileKey;

  for (final provinceId in invadable) {
    final ownerId = provinceOwner[provinceId];
    if (ownerId == null) continue;
    if (game.playerById(ownerId) != null) continue;
    if (ownColonyTribeIds.contains(ownerId)) continue;

    final relation = getRelation(game, snapshot.playerId, ownerId);
    if (relation != null && relation.atWar) continue;

    final overture = getOverture(game, snapshot.playerId, ownerId);
    if (overture == null || !overture.hasEmbassy) continue;

    if (!_provinceHasValidPurchaseLandTile(
      world: game.worldState,
      provinceId: provinceId,
      treasury: treasury,
      prospected: prospected,
      purchasedByTile: purchasedByTile,
    )) {
      continue;
    }

    return ColonialAcquisitionTarget(
      targetFactionId: ownerId,
      method: AcquisitionMethod.purchaseLand,
    );
  }
  return null;
}

/// Iterates [invadable] in distance order and returns the first
/// [AcquisitionMethod.declareWar] candidate satisfying the outer
/// gates (regiments ≥ 1, treasury ≥ cheapest regiment cost) and the
/// per-province gates (non-GP owner, not already at war).
ColonialAcquisitionTarget? _findDeclareWarTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
  required List<String> invadable,
  required Map<String, String> provinceOwner,
  required int treasury,
  required bool waiveTreasuryGate,
  required Set<String> ownColonyTribeIds,
}) {
  if (regimentCountForPlayer(game, snapshot.playerId) <= 0) {
    return null;
  }
  if (!waiveTreasuryGate && treasury < _cheapestRegimentBuildTreasuryCost()) {
    return null;
  }

  for (final provinceId in invadable) {
    final ownerId = provinceOwner[provinceId];
    if (ownerId == null) continue;
    if (game.playerById(ownerId) != null) continue;
    if (ownColonyTribeIds.contains(ownerId)) continue;

    final relation = getRelation(game, snapshot.playerId, ownerId);
    if (relation != null && relation.atWar) continue;

    return ColonialAcquisitionTarget(
      targetFactionId: ownerId,
      method: AcquisitionMethod.declareWar,
    );
  }
  return null;
}

/// Tribe ids that are already [playerId]'s own colony
/// (`ColonyState.colonyOfGpId == playerId`).
///
/// Colony tribes stay in the game and keep owning NW provinces after Tribe
/// Join Empire resolves, so they remain in the invadable list. The acquisition
/// arms exclude these owners so the planner never re-targets its own colony
/// (Refs #3758 R4 / S3; SPEC/ai/phase-planner-architecture.md § Own-colony
/// exclusion; SPEC/game/diplomacy.md § GP–Tribe Join Empire → colony). Colonies
/// of a different GP are intentionally not excluded.
Set<String> _ownColonyTribeIds(Game game, String playerId) => <String>{
  for (final colony in game.colonyStates)
    if (colony.colonyOfGpId == playerId) colony.tribeId,
};

/// Iteration order over NW invadable provinces for
/// [planColonialAcquisition], honoring the spec's adjacency-distance
/// requirement (Refs #2509 § COLONIAL phase planner §
/// planColonialAcquisition -- "sorted by adjacency distance to owned
/// territory").
///
/// Returns [ColonialSummary.invadableNewWorldProvinceIdsByDistance]
/// when the snapshot was built with a [MapTopology] (the normal
/// production path; the perception-snapshot builder populates the
/// distance-sorted field via
/// [reachableNonOwnedProvinceDistancesViaSeas]). Falls back to the
/// lex-sorted [ColonialSummary.invadableNewWorldProvinceIdsSorted]
/// for synthetic fixtures that build snapshots without a topology
/// (today: the COLONIAL acquisition unit tests). The fallback
/// preserves backward-compatible behavior for the legacy pin set
/// (sort-by-province-id tiebreaks) while production play uses the
/// distance-sorted iteration the spec mandates.
///
/// The function never throws or returns null: if the snapshot has
/// neither field populated (e.g. an outer COLONIAL guard already
/// short-circuited to an empty invadable set upstream), it returns
/// the empty list and the caller's outer-guard short-circuits as
/// today.
List<String> _acquisitionIterationOrder(ColonialSummary colonial) {
  if (colonial.invadableNewWorldProvinceIdsByDistance.isNotEmpty) {
    return colonial.invadableNewWorldProvinceIdsByDistance;
  }
  return colonial.invadableNewWorldProvinceIdsSorted;
}

/// Minimum [RegimentEconomyCatalog] build treasury cost (deterministic
/// catalog scan).
///
/// Delegates to the canonical
/// [expand_phase_planner.cheapestRegimentBuildTreasuryCost] (Refs #2509
/// S1) so the COLONIAL declare-war arm shares the same affordability
/// gate as `planExpandDeclareWar` / `planExpandEconomy`. The COLONIAL
/// planner intentionally keeps the call site private so it remains
/// self-contained against the now-completed S1 deletion of
/// `colonial_pressure.dart`.
int _cheapestRegimentBuildTreasuryCost() =>
    expand_phase_planner.cheapestRegimentBuildTreasuryCost();

/// True when [playerId] owns at least one [kUnitTypeMerchant] unit
/// with [UnitStatus.idle] in either region. Region of the Merchant is
/// not constrained — the orchestrator and resolver handle staging
/// movement on follow-up turns (mirrors the Builder selection
/// convention in [planColonialCivilian]).
bool _hasIdleMerchant(WorldState world, String playerId) {
  for (final unit in allUnitsFromWorld(world)) {
    if (unit.ownerId == playerId &&
        unit.type == kUnitTypeMerchant &&
        unit.status == UnitStatus.idle) {
      return true;
    }
  }
  return false;
}

/// True when [provinceId] contains at least one tile satisfying every
/// per-tile gate from `precheckPurchaseLand`:
///
///   - non-empty resource id in [WorldState.resourceByTileKey];
///   - not present in [purchasedByTile] (no other GP has bought it,
///     and the active player has not already purchased it either);
///   - mineral resource ids ([kMineralResourceIds]) require the tile
///     to be in [prospected] (the active player's prospected-tile
///     set);
///   - [purchaseLandCost] for the resource must be within [treasury].
///
/// Iteration over [WorldState.resourceByTileKey] is bounded by the
/// total number of tiles with a resource entry (much smaller than the
/// global tile count); per-tile checks are O(1). The function returns
/// the existence answer only — picking a specific tile for the
/// `purchase_land` work order is the orchestrator's job (the planner
/// contract returns the *target faction* and the *method*, not the
/// exact tile, mirroring the [AcquisitionMethod.joinEmpire] return
/// shape).
bool _provinceHasValidPurchaseLandTile({
  required WorldState world,
  required String provinceId,
  required int treasury,
  required Set<String> prospected,
  required Map<String, String> purchasedByTile,
}) {
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    if (Unit.provinceIdFromTileKey(tileKey) != provinceId) continue;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    if (purchasedByTile.containsKey(tileKey)) continue;
    if (kMineralResourceIds.contains(resourceId) &&
        !prospected.contains(tileKey)) {
      continue;
    }
    if (treasury < purchaseLandCost(resourceId)) continue;
    return true;
  }
  return false;
}
