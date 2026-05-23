/// EXPAND-phase planner (Refs #2509 S2 / S10).
///
/// Phase planner module from the single-goal architecture in
/// [GitHub issue #2509](https://github.com/waigore/colonizethisv3/issues/2509)
/// and `SPEC/ai/ai-architecture.md` § Observer goal phases. The planner is a
/// pure-function module that makes one primary decision per domain with no
/// cross-phase score aggregation.
///
/// EXPAND phase goal: reach `kObserverConquestMinOwProvincesPerGp` Old World
/// provinces. All NW code is structurally bypassed — the EXPAND planner never
/// imports `colonial_phase_planner.dart`, never queries [ColonialSummary],
/// never generates NW `declareWar` / `establishOverture` /
/// `purchase_land` / `build_improvement`, and never queues NW conquest army
/// moves. Suppression is an architectural property of the module, not a
/// runtime predicate check (Refs #2509 § EXPAND phase planner Suppressions).
///
/// Callers are expected to dispatch to this module **only** when
/// `observerGoalPhaseFor` resolves to `ObserverGoalPhase.expand`; the planner
/// functions themselves do not re-check the phase, matching the convention
/// established by `develop_phase_planner.dart` (Refs #2509 S4).
///
/// Wiring this module into the orchestrator and removing the legacy
/// `expandPhaseGpPeaceTargets` helper from `observer_goal_phase.dart` are
/// out of scope for this slice (tracked under S5 / S1 of #2509). Both the
/// legacy `expandPhaseGpPeaceTargets` helper and the new `planExpandPeace`
/// function remain pinned at the function-unit level until the orchestrator
/// rewrite reconciles them, so this slice carries **zero behavior change**
/// and **zero regression risk** for live AI play.
///
/// In-module contracts shipped to date (see issue #2509 § EXPAND phase
/// planner for the full set):
///
///   `planExpandPeace(game, snapshot) → List<String>`
///     Returns the deterministic list of at-war Great Powers the active
///     player should `offerPeace` toward in EXPAND. Defaults to peacing
///     **all** at-war GPs except the GP owning the primary invadable Old
///     World frontier (`primaryInvadableOldWorldGpBlocker`). The lone GP
///     blocker is also peaced when the war is a mutual-plateau sole-GP
///     stalemate on a GP-only invadable frontier with no uninvaded OW
///     minors remaining (Refs #2509 § EXPAND phase planner § planExpandPeace
///     "peace to exit stalemate").
///
///   `planExpandDeclareWar(game, snapshot) → String?`
///     Returns the deterministic factionId of the next declare-war target
///     for the active EXPAND player, scanning [ConquestSummary]
///     `invadableProvinceIdsSorted` in priority order: (1) adjacent
///     minor not yet at war, (2) already-at-war minor (formalize war so
///     conquest army-move pass fires), (3) sole GP frontier blocker on a
///     GP-only mutual-plateau frontier when our regiment count and
///     treasury cover engagement. Returns `null` when no priority arm
///     applies (Refs #2509 § EXPAND phase planner § planExpandDeclareWar).
///     The "suggestDeclareWarOrders rejects" runtime gate noted in the
///     spec is enforced at the orchestrator layer (#2509 S5) so this
///     module remains a pure-function planner.
///
///   `planExpandEconomy(game, snapshot) → ExpandEconomyPlan`
///     Returns the EXPAND-phase economy directive for the active player:
///     `forceCheapestRegimentBuild` (set the orchestrator build threshold
///     to zero and pick the cheapest regiment in
///     [RegimentEconomyCatalog]) and / or `boostTreasuryRecoveryCargo`
///     (raise economy weight for overseas cargo so riches deliver to
///     stockpile before the next build pass). Implements the
///     three-arm decision tree from issue #2509 § EXPAND phase planner
///     § planExpandEconomy (zero-regiment rebuild, insufficient-regiment
///     rebuild with affordable treasury, treasury-recovery cargo boost).
///     Effective treasury is `Player.treasury` plus
///     [pendingRichesTreasuryDelta] so the planner aligns with build
///     validation that already credits same-turn `richesToTreasury`
///     phase income (Refs #2509 § Observer goal phases § EXPAND
///     "Pending riches treasury").
///
///   `planExpandMilitary(game, snapshot, declaredWarTargetFactionId)
///                                                  → ExpandMilitaryPlan`
///     Returns the deterministic OW-only conquest destination filter for
///     the active EXPAND player. The plan carries the priority subset of
///     [ConquestSummary.invadableProvinceIdsSorted] (always OW by
///     construction — see `_invadableOldWorldProvinceIds` in the
///     perception snapshot builder) that conquest army moves should
///     target this turn: provinces owned by the declare-war target when
///     one was chosen, otherwise provinces owned by any at-war faction.
///     Returns [ExpandMilitaryPlan.defaultPlan] (no constraint) for the
///     outer EXPAND guards (at quota, missing player, empty invadable
///     frontier) and for the priority arms that resolve to an empty
///     province set; the orchestrator (#2509 S5) treats `defaultPlan`
///     as "free choice within OW invadable" and a non-default plan as
///     "restrict conquest army moves to this subset" (Refs #2509 §
///     EXPAND phase planner § planExpandMilitary "Use existing
///     runConquestArmyMovePlanner with EXPAND-only destination filter").
///     Structural NW suppression: the planner never reads
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] so a New
///     World invadable province cannot appear in the plan even if the
///     snapshot exposes one.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;

/// Returns the deterministic list of at-war Great Powers the active player
/// should `offerPeace` toward this turn while in EXPAND phase.
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandPeace):
///
///   "Peace ALL at-war Great Powers, with ONE exception:
///    → Keep fighting the GP that owns the primary invadable OW frontier
///      blocker (primaryInvadableOldWorldGpBlocker), UNLESS:
///      - It's a mutual-plateau sole GP war on a GP-only cleared frontier
///        with no uninvaded minors (peace to exit stalemate)."
///
/// Inputs:
///   - [game]: used to (a) filter [ThreatSummary.atWarWith] down to Great
///     Power factions via [Game.playerById]; (b) compute the primary OW
///     frontier blocker by mapping invadable OW provinces to current
///     owners; (c) detect uninvaded OW minors still in play; (d) check
///     whether the invadable OW frontier is held only by GPs (no minor
///     border).
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith], [ConquestSummary.invadableProvinceIdsSorted],
///     and [ConquestSummary.oldWorldProvincesOwned] for the mutual-plateau
///     comparison.
///
/// Output:
///   - Empty list when no Great Powers are at war with the active player.
///   - Empty list when the sole at-war GP **is** the primary OW invadable
///     blocker and the mutual-plateau sole-GP carve-out does **not** apply
///     (keep fighting the blocker; default EXPAND posture).
///   - All GPs sorted ascending when the primary blocker is `null` or not
///     among the at-war GPs (peace ALL: the legacy "no exception applies"
///     case).
///   - All GPs except the blocker sorted ascending when the blocker is
///     among the at-war GPs and the carve-out does not fire (peace ALL
///     except the blocker).
///   - The single GP (still sorted as a 1-element list) when the
///     mutual-plateau sole-GP carve-out fires: exactly one GP at war,
///     that GP owns the primary OW invadable blocker, both sides are in
///     the stalled below-quota plateau band
///     ([_isMutualBelowQuotaPlateauPeer]), the invadable frontier is
///     GP-only ([_isOldWorldGpOnlyInvadableFrontier]), and no uninvaded
///     OW minors remain ([_hasUninvadedOldWorldMinor] is false).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<String> planExpandPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.isEmpty) {
    return const [];
  }

  final blocker = _primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null || !gpWars.contains(blocker)) {
    return gpWars..sort();
  }

  if (gpWars.length == 1 &&
      _isMutualBelowQuotaPlateauPeer(
        ownOw: snapshot.conquest.oldWorldProvincesOwned,
        partnerOw: provinceCountOwnedBy(game, blocker),
      ) &&
      _isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot) &&
      !_hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
    return List<String>.unmodifiable(gpWars);
  }

  return <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
}

/// GP owning the most invadable Old World provinces (frontier blocker).
///
/// Mirrors the existing `primaryInvadableOldWorldGpBlocker` algorithm in
/// `colonial_pressure.dart` so the new planner stays self-contained
/// against the S1 deletion of that file (Refs #2509 § EXPAND phase
/// planner). Behavior is byte-identical to the legacy helper:
///
///   1. Tally GP ownership across [ConquestSummary.invadableProvinceIdsSorted]
///      using [getProvinceOwnerMap], skipping unowned and non-GP entries.
///   2. Resolve the plurality winner with a second linear pass that
///      preserves the first-iterated-province tiebreak (deterministic
///      against the snapshot's already-sorted invadable list).
///
/// Returns `null` when the invadable list is empty or none of the
/// invadable provinces are owned by a Great Power. Linear in the
/// invadable-OW set, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
String? _primaryInvadableOldWorldGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final invadable = snapshot.conquest.invadableProvinceIdsSorted;
  if (invadable.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final counts = <String, int>{};
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null || game.playerById(owner) == null) continue;
    counts[owner] = (counts[owner] ?? 0) + 1;
  }
  if (counts.isEmpty) {
    return null;
  }
  String? bestGpId;
  var bestCount = 0;
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null) continue;
    final count = counts[owner];
    if (count == null) continue;
    if (count > bestCount) {
      bestCount = count;
      bestGpId = owner;
    }
  }
  return bestGpId;
}

/// Whether the invadable Old World frontier is held only by Great Powers
/// (no minor nation owns any invadable OW province).
///
/// Mirrors `isOldWorldGpOnlyInvadableFrontier` from `colonial_pressure.dart`.
/// The mutual-plateau sole-GP carve-out in [planExpandPeace] requires this
/// gate so we only peace the lone GP blocker when no minor pivot remains.
bool _isOldWorldGpOnlyInvadableFrontier({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return false;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any((
    pid,
  ) {
    final owner = provinceOwner[pid];
    return owner != null && game.minorNations.any((m) => m.id == owner);
  });
  if (minorsOwnInvadable) {
    return false;
  }
  return snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) => game.playerById(provinceOwner[pid] ?? '') != null,
  );
}

/// Whether any Old World minor nation still holds provinces and is not
/// already at war with the active player (uninvaded minor pivot remaining).
///
/// Mirrors `hasUninvadedOldWorldMinor` from `colonial_pressure.dart`. The
/// mutual-plateau sole-GP carve-out in [planExpandPeace] holds the GP war
/// while uninvaded minors remain (we should expand against minors first).
bool _hasUninvadedOldWorldMinor({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  for (final minor in game.minorNations) {
    if (snapshot.threats.atWarWith.contains(minor.id)) {
      continue;
    }
    if (game.worldState.oldWorld.provinces.any((p) => p.ownerId == minor.id)) {
      return true;
    }
  }
  return false;
}

/// Whether [ownOw] and [partnerOw] are both in the stalled below-quota
/// plateau band with similar holdings (within one province of each other).
///
/// Mirrors `isMutualBelowQuotaPlateauPeer` from `colonial_pressure.dart`.
/// Stall threshold ([kStalledOldWorldProvinceThreshold]) and quota
/// ([kObserverConquestMinOwProvincesPerGp]) are the same authoritative
/// constants used by the legacy helper.
bool _isMutualBelowQuotaPlateauPeer({
  required int ownOw,
  required int partnerOw,
}) =>
    isStalledOldWorldExpansion(ownOw) &&
    isStalledOldWorldExpansion(partnerOw) &&
    isBelowObserverConquestQuota(ownOw) &&
    isBelowObserverConquestQuota(partnerOw) &&
    (partnerOw - ownOw).abs() <= 1;

/// Returns the deterministic factionId of the next declare-war target for
/// the active EXPAND player, or `null` when no priority arm applies.
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandDeclareWar):
///
///   "Priority-ordered scan of `invadableProvinceIdsSorted` (OW only).
///    Pick the first valid candidate:
///      1. Adjacent minor with uninvaded OW province
///      2. Already-at-war minor with uninvaded OW province
///      3. Sole GP frontier blocker (GP-only frontiers only, mutual
///         plateau, our regiments ≥ partner's, treasury ≥ regiment cost)
///      4. null — skip declaring."
///
/// The function is pure and deterministic — identical inputs always yield
/// identical results (Refs #2509 Must-have #7). Tiebreaks are
/// lexicographic ascending across factionIds within each priority arm.
///
/// Inputs:
///   - [game]: used to (a) resolve the active player via
///     [Game.playerById] for treasury and regiment-count gating; (b) walk
///     the province-owner map for minor-vs-GP partitioning of
///     [ConquestSummary.invadableProvinceIdsSorted]; (c) compute the lone
///     GP blocker's holdings for mutual-plateau and regiment comparisons.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith], [ConquestSummary.invadableProvinceIdsSorted],
///     [ConquestSummary.adjacentOwnerFactionIdsSorted], and
///     [ConquestSummary.oldWorldProvincesOwned].
///
/// Returns:
///   - `null` when [ConquestSummary.invadableProvinceIdsSorted] is empty
///     (no OW frontier to expand into) or when treasury is below
///     `_cheapestRegimentBuildTreasuryCost()` (the player cannot afford a
///     regiment to follow up the declaration; the spec
///     "skip if treasury < cheapestRegimentBuildTreasuryCost" arm).
///   - The lowest-id minor faction owning an invadable OW province and
///     present in [ConquestSummary.adjacentOwnerFactionIdsSorted] but not
///     in [ThreatSummary.atWarWith] (priority 1: adjacent minor scan).
///   - The lowest-id minor faction owning an invadable OW province and
///     already in [ThreatSummary.atWarWith] (priority 2: formalize the
///     existing war so the conquest army-move pass fires).
///   - The single GP whose ownership covers the entire invadable OW
///     frontier (priority 3) when: the frontier is GP-only (no minor
///     holds an invadable OW tile), exactly one GP owns invadable
///     provinces, both sides are mutual-plateau peers
///     ([_isMutualBelowQuotaPlateauPeer]), and the active player's
///     regiment count is ≥ that GP's regiment count.
///   - `null` when none of the priority arms qualify.
///
/// The runtime "suggestDeclareWarOrders rejects" gate noted in the issue
/// spec is enforced at the orchestrator layer (#2509 S5) so this pure
/// function remains free of the order-suggestion API dispatch.
String? planExpandDeclareWar({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final invadable = snapshot.conquest.invadableProvinceIdsSorted;
  if (invadable.isEmpty) return null;
  final player = game.playerById(snapshot.playerId);
  if (player == null) return null;
  if (player.treasury < _cheapestRegimentBuildTreasuryCost()) {
    return null;
  }

  final atWarWith = snapshot.threats.atWarWith.toSet();
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted
      .toSet();
  final minorIds = <String>{for (final m in game.minorNations) m.id};
  final provinceOwner = getProvinceOwnerMap(game);

  // Priority 1: adjacent minor not yet at war.
  final adjacentNewWarMinors = <String>{};
  // Priority 2: already-at-war minor with invadable OW province.
  final atWarMinors = <String>{};
  // Priority 3 prep: tally GP ownership across invadable provinces.
  final gpInvadableCounts = <String, int>{};
  var anyMinorOnInvadable = false;
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!minorIds.contains(owner)) {
      if (game.playerById(owner) != null) {
        gpInvadableCounts[owner] = (gpInvadableCounts[owner] ?? 0) + 1;
      }
      continue;
    }
    anyMinorOnInvadable = true;
    if (atWarWith.contains(owner)) {
      atWarMinors.add(owner);
      continue;
    }
    if (adjacentOwners.contains(owner)) {
      adjacentNewWarMinors.add(owner);
    }
  }

  if (adjacentNewWarMinors.isNotEmpty) {
    final sorted = adjacentNewWarMinors.toList()..sort();
    return sorted.first;
  }
  if (atWarMinors.isNotEmpty) {
    final sorted = atWarMinors.toList()..sort();
    return sorted.first;
  }

  // Priority 3: sole GP frontier blocker on GP-only mutual-plateau front.
  if (anyMinorOnInvadable) return null;
  if (gpInvadableCounts.length != 1) return null;
  final blockerId = gpInvadableCounts.keys.single;
  if (atWarWith.contains(blockerId)) {
    // Already at war — formalize is a no-op for GPs at this layer; the
    // declare-war target is `null` so we do not re-issue declareWar.
    return null;
  }
  final blockerOw = provinceCountOwnedBy(game, blockerId);
  if (!_isMutualBelowQuotaPlateauPeer(
    ownOw: snapshot.conquest.oldWorldProvincesOwned,
    partnerOw: blockerOw,
  )) {
    return null;
  }
  final ownRegiments = regimentCountForPlayer(game, snapshot.playerId);
  final partnerRegiments = regimentCountForPlayer(game, blockerId);
  if (ownRegiments < partnerRegiments) return null;
  return blockerId;
}

/// EXPAND-phase economy directive returned by [planExpandEconomy].
///
/// Two independent booleans describe the orchestrator overrides for the
/// active player this turn. The planner stays a pure function: the
/// orchestrator (Refs #2509 S5) translates these flags into the actual
/// build-threshold reset and economy-weight cargo boost when wiring the
/// EXPAND dispatch.
///
/// The flags compose — a GP can both be told to force a regiment build
/// and to raise cargo preference in the same turn (canonical "rebuild
/// fast while overseas riches keep arriving" arm when reg = 0 and
/// effective treasury is still under the cheapest regiment cost).
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path.
class ExpandEconomyPlan {
  const ExpandEconomyPlan({
    required this.forceCheapestRegimentBuild,
    required this.boostTreasuryRecoveryCargo,
  });

  /// Reusable "no override" plan returned for non-EXPAND callers, GPs
  /// at quota, defensive guards, and the priority-arm fall-through.
  static const ExpandEconomyPlan defaultPlan = ExpandEconomyPlan(
    forceCheapestRegimentBuild: false,
    boostTreasuryRecoveryCargo: false,
  );

  /// True when the orchestrator should drop the build-pass economy
  /// threshold to zero and pick the cheapest entry in
  /// [RegimentEconomyCatalog] (military rebuild crisis).
  ///
  /// Set under either of the two regiment-rebuild arms in issue #2509
  /// § EXPAND phase planner § planExpandEconomy:
  /// (a) `regimentCount == 0` with a non-empty
  ///     [ConquestSummary.invadableProvinceIdsSorted] (the
  ///     `brokeBelowQuotaAtPeace` / `needRegimentsToExpand` legacy
  ///     condition collapsed into the phase planner); or
  /// (b) the trap condition
  ///     `0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
  ///     with non-empty invadable OW frontier and effective treasury
  ///     (cash + [pendingRichesTreasuryDelta]) at or above
  ///     `_cheapestRegimentBuildTreasuryCost()`.
  final bool forceCheapestRegimentBuild;

  /// True when the orchestrator should add
  /// [kBelowQuotaPeaceTreasuryRecoveryCargoBoost] to economy weight so
  /// overseas cargo preference rises (deliver NW riches to stockpile)
  /// even in EXPAND.
  ///
  /// Set when below quota AND effective treasury (cash +
  /// [pendingRichesTreasuryDelta]) is strictly below
  /// `_cheapestRegimentBuildTreasuryCost()` (issue #2509 § EXPAND phase
  /// planner § planExpandEconomy "treasury < cheapest" arm). The
  /// boost composes with [forceCheapestRegimentBuild] so a GP that is
  /// told to force a build AND cannot currently afford one still gets
  /// the cargo signal to chase incoming riches.
  final bool boostTreasuryRecoveryCargo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpandEconomyPlan &&
          other.forceCheapestRegimentBuild == forceCheapestRegimentBuild &&
          other.boostTreasuryRecoveryCargo == boostTreasuryRecoveryCargo;

  @override
  int get hashCode =>
      Object.hash(forceCheapestRegimentBuild, boostTreasuryRecoveryCargo);

  @override
  String toString() =>
      'ExpandEconomyPlan('
      'forceCheapestRegimentBuild: $forceCheapestRegimentBuild, '
      'boostTreasuryRecoveryCargo: $boostTreasuryRecoveryCargo)';
}

/// Returns the deterministic EXPAND-phase economy directive for the
/// active player as an [ExpandEconomyPlan].
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandEconomy):
///
///   "Force-regiment-rebuild when:
///      ow < 10 AND (
///        regimentCount == 0 AND hasInvadableProvinces
///          → set buildThreshold = 0, force cheapest regiment
///        OR
///        0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar
///          AND treasury >= cheapestRegimentBuildTreasuryCost
///          → set buildThreshold = 0, force cheapest regiment
///        OR
///        treasury < cheapestRegimentBuildTreasuryCost
///          → add cargo preference boost (deliver riches to stockpile)
///      )"
///
/// Effective treasury used by the regiment-affordability and cargo
/// arms is `player.treasury + pendingRichesTreasuryDelta(...)` so the
/// planner agrees with the build pipeline that already credits the
/// same-turn `richesToTreasury` phase income before `buildWork`
/// (Refs #2509 § Observer goal phases § EXPAND "Pending riches
/// treasury"). The OW improvements / NW suppressions arms of the spec
/// are out of scope for this planner contract — those orders are
/// produced by `planDevelopCivilian` (DEVELOP) and the conquest
/// army-move planner (EXPAND military) respectively; the EXPAND
/// economy planner only emits the build/cargo override directive.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) to read
///     [Player.treasury] and [Player.stockpile] (for the pending-riches
///     credit) and walks [WorldState.armies] via [regimentCountForPlayer]
///     for the standing regiment count.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ConquestSummary.oldWorldProvincesOwned] (quota guard) and
///     [ConquestSummary.invadableProvinceIdsSorted] (the "has invadable
///     frontier" arms of the spec).
///
/// Output:
///   - [ExpandEconomyPlan.defaultPlan] when the active player is at or
///     above [kObserverConquestMinOwProvincesPerGp] OW provinces (not
///     in EXPAND territory for this planner) or when
///     [Game.playerById] returns `null` (defensive guard for snapshots
///     pointing at non-existent players; matches the
///     [planExpandDeclareWar] guard).
///   - `forceCheapestRegimentBuild: true` when arm A
///     (`regimentCount == 0` and non-empty invadable OW frontier) holds.
///     Treasury is intentionally **not** part of arm A's gate per the
///     issue spec — the orchestrator's existing build pipeline still
///     handles the case where no regiment is affordable yet, but the
///     phase planner signals intent unconditionally so the rebuild
///     trap cannot stick.
///   - `forceCheapestRegimentBuild: true` when arm B
///     (`0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
///     and non-empty invadable OW frontier and effective treasury
///     ≥ cheapest regiment cost) holds.
///   - `boostTreasuryRecoveryCargo: true` when arm C
///     (effective treasury < cheapest regiment cost) holds. Composes
///     with arm A: a GP with `regimentCount == 0` and effective
///     treasury below the cheapest cost gets **both** flags set, so
///     the orchestrator forces the build attempt and also boosts
///     cargo for the next turn's riches delivery.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ExpandEconomyPlan]s (Refs #2509 Must-have #7).
ExpandEconomyPlan planExpandEconomy({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return ExpandEconomyPlan.defaultPlan;
  }
  final player = game.playerById(snapshot.playerId);
  if (player == null) {
    return ExpandEconomyPlan.defaultPlan;
  }

  final hasInvadable = snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  final regimentCount = regimentCountForPlayer(game, snapshot.playerId);
  final effectiveTreasury =
      player.treasury + pendingRichesTreasuryDelta(stockpile: player.stockpile);
  final cheapest = _cheapestRegimentBuildTreasuryCost();

  // Arm A: regimentCount == 0 AND hasInvadable -> force rebuild
  // (no treasury gate per spec; the build pipeline still applies its
  // own affordability check, but the directive remains so the phase
  // planner cannot be silently overridden by a treasury hiccup).
  final armA = regimentCount == 0 && hasInvadable;

  // Arm B: 0 < regimentCount < min AND hasInvadable AND effective
  // treasury affords the cheapest regiment.
  final armB =
      regimentCount > 0 &&
      regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar &&
      hasInvadable &&
      effectiveTreasury >= cheapest;

  // Arm C: effective treasury below cheapest regiment cost (independent
  // of regimentCount per the spec literal wording — boosts cargo so a
  // GP in EXPAND with low cash always benefits from delivering riches,
  // matching the SPEC/ai/ai-architecture.md "Treasury recovery cargo"
  // intent).
  final armC = effectiveTreasury < cheapest;

  return ExpandEconomyPlan(
    forceCheapestRegimentBuild: armA || armB,
    boostTreasuryRecoveryCargo: armC,
  );
}

/// Minimum [RegimentEconomyCatalog] build treasury cost (deterministic
/// catalog scan).
///
/// Mirrors `cheapestRegimentBuildTreasuryCost` from `colonial_pressure.dart`
/// so the new planner stays self-contained against the S1 deletion of
/// that file (Refs #2509 § EXPAND phase planner). Linear in the catalog
/// size, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
int _cheapestRegimentBuildTreasuryCost() {
  var min = 999999999;
  for (final econ in RegimentEconomyCatalog.byId.values) {
    if (econ.buildTreasuryCost < min) {
      min = econ.buildTreasuryCost;
    }
  }
  return min;
}

/// EXPAND-phase conquest destination filter returned by [planExpandMilitary].
///
/// Two ascending-sorted lists describe the priority subset of OW
/// invadable provinces (and the owning faction(s)) that conquest army
/// moves should target this turn. The lists never contain New World
/// provinces — structural suppression in [planExpandMilitary] (the
/// planner only reads [ConquestSummary.invadableProvinceIdsSorted],
/// which is OW-only by construction in the perception-snapshot builder).
///
/// The orchestrator (Refs #2509 S5) consumes the plan as a filter on
/// `runConquestArmyMovePlanner`:
///   - [defaultPlan] (`priorityDestinationProvinceIdsSorted` empty) =
///     "no constraint"; the orchestrator chooses freely from the full
///     OW invadable set (legacy behavior).
///   - A non-default plan = "restrict OW conquest destinations to this
///     subset". Empty plans never carry [priorityTargetOwnerFactionIdsSorted]
///     entries; non-empty plans always carry at least one owner.
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path.
class ExpandMilitaryPlan {
  const ExpandMilitaryPlan({
    required this.priorityDestinationProvinceIdsSorted,
    required this.priorityTargetOwnerFactionIdsSorted,
  });

  /// Reusable "no override" plan returned for non-EXPAND callers, GPs
  /// at quota, the empty-invadable guard, and the priority-arm
  /// fall-through (declared-war target owns nothing in OW invadable
  /// and no at-war faction owns OW invadable either).
  static const ExpandMilitaryPlan defaultPlan = ExpandMilitaryPlan(
    priorityDestinationProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ConquestSummary.invadableProvinceIdsSorted] (OW only)
  /// whose owners match the priority-arm filter for this turn. Sorted
  /// ascending so identical inputs yield identical lists (Refs #2509
  /// Must-have #7). Empty for [defaultPlan].
  final List<String> priorityDestinationProvinceIdsSorted;

  /// Faction ids of the owners covered by
  /// [priorityDestinationProvinceIdsSorted]. Sorted ascending and
  /// deduplicated:
  ///   - Single-element list when the declared-war target arm fires
  ///     ([planExpandMilitary] § Priority 1).
  ///   - One or more entries (sorted at-war owners) when the at-war
  ///     fallback arm fires ([planExpandMilitary] § Priority 2).
  ///   - Empty for [defaultPlan].
  final List<String> priorityTargetOwnerFactionIdsSorted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpandMilitaryPlan &&
          _listEquals(
            priorityDestinationProvinceIdsSorted,
            other.priorityDestinationProvinceIdsSorted,
          ) &&
          _listEquals(
            priorityTargetOwnerFactionIdsSorted,
            other.priorityTargetOwnerFactionIdsSorted,
          );

  @override
  int get hashCode => Object.hash(
    Object.hashAll(priorityDestinationProvinceIdsSorted),
    Object.hashAll(priorityTargetOwnerFactionIdsSorted),
  );

  @override
  String toString() =>
      'ExpandMilitaryPlan('
      'priorityDestinationProvinceIdsSorted: $priorityDestinationProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Returns the deterministic EXPAND-phase conquest destination filter
/// for the active player as an [ExpandMilitaryPlan].
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandMilitary):
///
///   "Conquest army moves toward OW invadable provinces only.
///      → Source: invadableProvinceIdsSorted, filtered to provinces
///        owned by the declare-war target (or any at-war owner if no
///        target).
///      → Use existing runConquestArmyMovePlanner with EXPAND-only
///        destination filter.
///      → No NW army moves (structural — planner never queries
///        colonial summary)."
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ConquestSummary.invadableProvinceIdsSorted] by owner faction.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ConquestSummary.invadableProvinceIdsSorted] (the OW-only
///     candidate pool),
///     [ConquestSummary.oldWorldProvincesOwned] (the EXPAND outer
///     quota gate), and [ThreatSummary.atWarWith] (the Priority 2
///     fallback when no declare-war target is given).
///   - [declaredWarTargetFactionId]: optional declare-war target from
///     [planExpandDeclareWar] for the same turn; when non-null, the
///     planner restricts conquest destinations to provinces owned by
///     that faction (Priority 1).
///
/// Priority arms (first match wins; each arm produces a sorted-ascending,
/// deduplicated province list):
///   1. **Declared-war target** — when [declaredWarTargetFactionId] is
///      non-null and owns at least one province in
///      [ConquestSummary.invadableProvinceIdsSorted], the plan
///      restricts to those provinces and lists only the target as
///      `priorityTargetOwnerFactionIdsSorted`.
///   2. **At-war owners fallback** — when no declare-war target is given
///      and at least one faction in [ThreatSummary.atWarWith] owns an
///      OW invadable province, the plan restricts to the union of those
///      provinces and lists the at-war owners sorted ascending.
///   3. **Default plan** — when the declare-war target owns nothing in
///      OW invadable, or when no declare-war target is given and no
///      at-war faction owns OW invadable, or for the outer guards (at
///      quota, missing player, empty OW invadable). Empty plan signals
///      the orchestrator to fall back to its existing free-choice
///      conquest behaviour over the full invadable set.
///
/// Structural NW suppression: this function reads only
/// [ConquestSummary.invadableProvinceIdsSorted] (OW-only by builder
/// contract). It never reads [ColonialSummary.invadableNewWorldProvinceIdsSorted],
/// so a New World province cannot appear in the plan even when the
/// snapshot exposes one (Refs #2509 § EXPAND phase planner
/// "Suppressions" / Phase planner unit tests § "EXPAND NW
/// suppression"). The actual order emission and the conquest army-move
/// pass live in `runConquestArmyMovePlanner`; the orchestrator (#2509
/// S5) wires this plan in as a filter on that pass.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ExpandMilitaryPlan]s (Refs #2509 Must-have #7).
ExpandMilitaryPlan planExpandMilitary({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? declaredWarTargetFactionId,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  if (game.playerById(snapshot.playerId) == null) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  final invadable = snapshot.conquest.invadableProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ExpandMilitaryPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);

  if (declaredWarTargetFactionId != null) {
    final destinations = <String>[
      for (final pid in invadable)
        if (provinceOwner[pid] == declaredWarTargetFactionId) pid,
    ];
    if (destinations.isEmpty) {
      return ExpandMilitaryPlan.defaultPlan;
    }
    destinations.sort();
    return ExpandMilitaryPlan(
      priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
        destinations,
      ),
      priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(<String>[
        declaredWarTargetFactionId,
      ]),
    );
  }

  final atWarOwners = <String>{};
  final atWarSet = snapshot.threats.atWarWith.toSet();
  final destinations = <String>[];
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!atWarSet.contains(owner)) continue;
    destinations.add(pid);
    atWarOwners.add(owner);
  }
  if (destinations.isEmpty) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  destinations.sort();
  final owners = atWarOwners.toList()..sort();
  return ExpandMilitaryPlan(
    priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
      destinations,
    ),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}
