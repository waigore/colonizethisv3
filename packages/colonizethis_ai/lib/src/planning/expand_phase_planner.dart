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
/// In-module contracts shipped in this slice (see issue #2509 § EXPAND phase
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
/// Functions left for follow-up slices on this issue:
///   - `planExpandDeclareWar` — adjacent / already-at-war minor priority
///     scan, then sole-GP frontier blocker fallback (#2509 S2).
///   - `planExpandEconomy` — force-regiment-rebuild trap and treasury-
///     recovery cargo boost (#2509 S2).
///   - `planExpandMilitary` — OW-only conquest army moves toward the
///     declare-war target (#2509 S2).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

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
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) {
      final owner = provinceOwner[pid];
      return owner != null && game.minorNations.any((m) => m.id == owner);
    },
  );
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
