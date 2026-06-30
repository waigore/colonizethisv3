/// Shared planning-layer helpers (Refs #3278 dedup).
///
/// Canonical home for small pure functions that were previously copy-pasted
/// inline across the phase-planner / filter modules:
///
///   - [gpFactionIdsAtWarWith] — the GP-only at-war filter that replaces the
///     `[for (final f in snapshot.threats.atWarWith) if (game.playerById(f)
///     != null) f]` comprehension repeated across the planners.
///   - [isAtWarWithAnyGreatPower] — the boolean "are we at war with any Great
///     Power?" presence check that replaces the inline
///     `snapshot.threats.atWarWith.any((id) => game.playerById(id) != null)`
///     short-circuit predicate repeated across the planners / scoring families.
///   - [isOwnOldWorldExpansionStalled] / [isOwnOldWorldBelowConquestQuota] —
///     the snapshot-keyed
///     `isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)`
///     and `isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)`
///     own-OW projections repeated across the diplomatic-scoring and
///     expand-peace planner families.
///   - [mutualExhaustedGpStalemateSideQualifies] — the per-side
///     "mutual-exhausted below-quota Great Power stalemate" qualification
///     (min-OW + below-quota + stalled + treasury/regiment exhaustion) shared
///     by the offer-peace bonus gate and the EXPAND mutual-exhausted peace
///     collector for both the active player and the enemy Great Power.
///   - [scaleWeightedBonus] — the `<= 0.0 → 0`, clamp-to-`1.0`, `round()`
///     weight-scaling idiom shared by the soft-phase bonus/floor resolvers.
///   - [clampPhaseWeightUpperUnit] — the `weight > 1.0 ? 1.0 : weight`
///     upper-clamp idiom shared by the soft-phase weight-scaling sites
///     ([scaleWeightedBonus], the conquest OW army-move scaled bonus, and the
///     economy colonial-pressure threshold-cap resolvers) once each has
///     guarded its own `<= 0.0` lower bound.
///   - [resolvePhaseColonialPressureActive] /
///     [resolvePhaseExpandOrColonialLiteActive] — the structural phase
///     predicates shared by the conquest / economy / diplomacy / goal filters.
///   - [resolvePhaseNewWorldAcquisitionWeight] /
///     [resolvePhaseOldWorldConquestWeight] /
///     [resolvePhaseOldWorldCivilianWeight] /
///     [resolvePhaseNewWorldCivilianWeight] — the soft-phase
///     `PhasePlanOutcome` → `priorityWeights.<slot>` projections shared by the
///     conquest / naval / diplomacy / economy phase filters.
///   - [resolveFromPhasePlan] — the "project a non-default resolution from the
///     active `PhasePlanOutcome`, otherwise fall back to the family's
///     `defaultResolution`" skeleton shared by the phase-filter Resolution
///     families (naval directive, conquest invadable).
///   - [hasRecentDiplomaticEventWithinCooldown] — the "scan
///     `Game.diplomaticHistoryEvents` newest-first, let the first matching
///     event decide whether it falls inside a cooldown window" skeleton shared
///     by the declare-war / improve-relations scoring cooldowns and the EXPAND
///     peer-war peace cooldown.
///   - [atWarPeaceTargetBonus] / [atWarGreatPowerOrderTarget] — the offer-peace
///     "at-war Great Power peace candidate" eligibility gate and flat-bonus
///     emitter shared across the offer-peace scoring adjustments.
///
/// Keeping these in one place removes the duplication flagged by the
/// `repo.ai_dedup_gp_wars_filter` and `repo.ai_dedup_weight_scale_clamp`
/// repo-lint rules and preserves the existing deterministic behaviour exactly.
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show
        isBelowObserverConquestQuota,
        isCivilianBuildSpyTechStealPosture,
        isStalledOldWorldExpansion,
        kMutualExhaustedGpRegimentMax,
        kMutualExhaustedGpStalemateMinOw,
        kMutualExhaustedGpTreasuryMax;
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns every Great Power the active player is currently at war with as a
/// new ascending-sorted `List<String>` of `factionId`s.
///
/// Filters [ThreatSummary.atWarWith] down to factions for which
/// [Game.playerById] returns a non-null [Player] — tribes and minor nations
/// are not [Player] entries and are therefore excluded. The result is sorted
/// ascending so callers see a stable order regardless of the iteration order
/// of [ThreatSummary.atWarWith] (the inline comprehensions this helper
/// replaces either sorted their output or used it only for
/// length / membership checks, so the sort is behaviour-preserving).
///
/// Pure and deterministic — identical inputs always yield identical lists
/// (Refs #2509 Must-have #7).
List<String> gpFactionIdsAtWarWith(Game game, AIWorldSnapshot snapshot) {
  return <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
}

/// Returns the deterministic ascending-sorted list of at-war Great Power
/// `factionId`s that satisfy the caller-supplied [keep] predicate.
///
/// Single source of truth for the repeated EXPAND-phase peace-target collector
/// skeleton
/// `<String>[for (final id in gpFactionIdsAtWarWith(game, snapshot)) if (<keep>) id]..sort()`
/// duplicated across the expand-peace deciders (`defaultStartGpPeaceTargets`,
/// `stalledBelowQuotaGpLeadPeaceTargets`, `quotaMetBelowQuotaAtWarPeaceTargets`,
/// `quotaMetFutileBelowQuotaGpPeaceTargets`,
/// `criticalWeakGpSurvivalPeaceTargets`, `stalledFutileGpPeaceTargets`,
/// `belowQuotaPeerGpPeaceTargets`). Each caller now supplies only its
/// per-faction [keep] predicate; the GP at-war filter (via
/// [gpFactionIdsAtWarWith]) and the ascending `factionId` sort are applied
/// once here.
///
/// Behaviour-preserving against the replaced comprehensions:
/// [gpFactionIdsAtWarWith] already returns an ascending-sorted GP id list and
/// the comprehension preserves that order, so the trailing `..sort()` is
/// retained verbatim (a no-op on already-sorted input) to keep results
/// byte-identical. [keep] is evaluated once per at-war GP in ascending
/// `factionId` order.
///
/// Pure and deterministic — identical inputs (and a pure [keep]) always yield
/// identical lists (Refs #2509 Must-have #7).
List<String> gpAtWarPeaceTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  required bool Function(String factionId) keep,
}) {
  return <String>[
    for (final factionId in gpFactionIdsAtWarWith(game, snapshot))
      if (keep(factionId)) factionId,
  ]..sort();
}

/// Returns the deterministic ascending-sorted list of at-war minor-nation
/// `factionId`s that satisfy the optional caller-supplied [keep] predicate.
///
/// Minor-nation analogue of [gpAtWarPeaceTargetsWhere] and single source of
/// truth for the repeated minor at-war peace-target collector skeleton
/// `<String>[for (final id in snapshot.threats.atWarWith) if (isMinorFaction(game, id) && <keep>) id]..sort()`
/// duplicated across the EXPAND default-start futile-minor / multi-minor
/// distraction deciders (`defaultStartFutileMinorPeaceTargets`,
/// `belowQuotaMultiMinorDistractionPeaceTargets`) and the conquest planner's
/// below-quota active-minor pick (`conquest_planner.dart`). Each caller now
/// supplies only its own per-faction [keep] predicate; the
/// [isMinorFaction] at-war filter (over [ThreatSummary.atWarWith]) and the
/// ascending `factionId` sort are applied once here.
///
/// When [keep] is `null` every at-war minor is kept, matching the inline
/// comprehensions that applied no extra per-faction filter beyond
/// [isMinorFaction]. Tribes and Great Powers in [ThreatSummary.atWarWith] are
/// never returned (they are not [Game.minorNations] entries).
///
/// Behaviour-preserving against the replaced comprehensions: the
/// [isMinorFaction] membership filter, the optional [keep] conjunct, and the
/// trailing ascending `..sort()` are retained verbatim, so results are
/// byte-identical. [keep] (when non-`null`) is evaluated once per at-war minor.
///
/// Pure and deterministic — identical inputs (and a pure [keep]) always yield
/// identical lists (Refs #3717 expand-peace scoring-skeleton dedup).
List<String> minorAtWarPeaceTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  bool Function(String factionId)? keep,
}) {
  return <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (isMinorFaction(game, factionId) && (keep == null || keep(factionId)))
        factionId,
  ]..sort();
}

/// Returns the deterministic ascending-sorted list of at-war tribe
/// `factionId`s that satisfy the optional caller-supplied [keep] predicate.
///
/// Tribe analogue of [gpAtWarPeaceTargetsWhere] / [minorAtWarPeaceTargetsWhere]
/// and single source of truth for the repeated tribe at-war peace-target
/// collector skeleton
/// `<String>[for (final id in snapshot.threats.atWarWith) if (isTribeFaction(game, id) && <keep>) id]..sort()`
/// duplicated across the EXPAND tribe-distraction deciders
/// (`atWarGpDistractionTribePeaceTargets`,
/// `belowQuotaRegimentThinTribeDistractionPeaceTargets`). Each caller now
/// supplies only its own per-faction [keep] predicate; the [isTribeFaction]
/// at-war filter (over [ThreatSummary.atWarWith]) and the ascending
/// `factionId` sort are applied once here.
///
/// When [keep] is `null` every at-war tribe is kept, matching the inline
/// comprehension that applied no extra per-faction filter beyond
/// [isTribeFaction]. Minors and Great Powers in [ThreatSummary.atWarWith] are
/// never returned (they are not [Game.tribes] entries).
///
/// Behaviour-preserving against the replaced comprehensions: the
/// [isTribeFaction] membership filter, the optional [keep] conjunct, and the
/// trailing ascending `..sort()` are retained verbatim, so results are
/// byte-identical. [keep] (when non-`null`) is evaluated once per at-war tribe.
///
/// Pure and deterministic — identical inputs (and a pure [keep]) always yield
/// identical lists (Refs #3717 expand-peace scoring-skeleton dedup).
List<String> tribeAtWarPeaceTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  bool Function(String factionId)? keep,
}) {
  return <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (isTribeFaction(game, factionId) && (keep == null || keep(factionId)))
        factionId,
  ]..sort();
}

/// Returns the deterministic ascending-sorted list of at-war
/// **non-Great-Power** `factionId`s (minors *and* tribes) that satisfy the
/// optional caller-supplied [keep] predicate.
///
/// Non-GP analogue of [gpAtWarPeaceTargetsWhere] and the combined-faction
/// companion of [minorAtWarPeaceTargetsWhere] / [tribeAtWarPeaceTargetsWhere];
/// single source of truth for the repeated non-GP at-war peace-target
/// collector skeleton
/// `<String>[for (final id in snapshot.threats.atWarWith) if (game.playerById(id) == null && <keep>) id]..sort()`
/// hosted by the EXPAND zero-regiment survival decider
/// (`stalledZeroRegimentAllFactionPeaceTargets`). The caller supplies only its
/// own per-faction [keep] predicate; the non-GP at-war filter (over
/// [ThreatSummary.atWarWith]) and the ascending `factionId` sort are applied
/// once here.
///
/// The non-GP membership test is [Game.playerById] `== null` — **not** the
/// [isMinorFaction] / [isTribeFaction] membership predicates used by the
/// minor- and tribe-only collectors. This is deliberate and
/// behaviour-preserving: the replaced inline comprehension peaced every at-war
/// faction that is not a current Great Power, including an at-war id that is no
/// longer a registered minor or tribe (for example an absorbed faction still
/// present in [ThreatSummary.atWarWith]). Routing through [isMinorFaction] /
/// [isTribeFaction] instead would silently drop such ids and change the
/// emitted peace set, so the bare `playerById == null` filter is retained
/// verbatim. Great Powers in [ThreatSummary.atWarWith] are never returned.
///
/// When [keep] is `null` every at-war non-GP faction is kept, matching the
/// inline comprehension that applied no extra per-faction filter beyond the
/// non-GP membership test.
///
/// Pure and deterministic — identical inputs (and a pure [keep]) always yield
/// identical lists (Refs #3749 step 5 expand-peace collector dedup).
List<String> nonGreatPowerAtWarPeaceTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  bool Function(String factionId)? keep,
}) {
  return <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) == null &&
          (keep == null || keep(factionId)))
        factionId,
  ]..sort();
}

/// Returns [factionIds] with [blocker] removed, sorted ascending by
/// `factionId`.
///
/// Single source of truth for the repeated "drop the primary OW frontier
/// blocker from an at-war faction list, then sort ascending" peace-target
/// skeleton
/// `<String>[for (final id in factionIds) if (id != blocker) id]..sort()`
/// duplicated across the EXPAND / observer GP peace collectors
/// ([planExpandPeace], `stalledGpBlockerFocusPeaceTargets`,
/// `nearQuotaHoldPeaceTargets`, the peer-peace ratchet collector,
/// `expandPhaseGpPeaceTargets`, `colonialPhaseGpPeaceTargets`). Each caller
/// resolves its own [factionIds] (already-GP-filtered `gpWars`, or the raw
/// [ThreatSummary.atWarWith] set on the GP-only-frontier arm) and its own
/// [blocker]; the exclude filter and ascending `factionId` sort are applied
/// once here.
///
/// Behaviour-preserving against the replaced comprehensions: the
/// `id != blocker` exclude filter (a `null` [blocker] keeps every id, matching
/// the inline always-true `factionId != null` behaviour) and the trailing
/// ascending `..sort()` are retained verbatim, so results are byte-identical.
///
/// Pure and deterministic — identical inputs always yield identical lists
/// (Refs #3717 expand-peace scoring-skeleton dedup).
List<String> peaceTargetsExcludingBlocker({
  required Iterable<String> factionIds,
  required String? blocker,
}) => <String>[
  for (final factionId in factionIds)
    if (factionId != blocker) factionId,
]..sort();

/// Whether the active player is currently at war with **any** Great Power.
///
/// Single source of truth for the boolean
/// `snapshot.threats.atWarWith.any((id) => game.playerById(id) != null)`
/// presence check that was duplicated inline across the planner / scoring
/// families (conquest, economy, diplomacy, expand-peace, declare-war scoring,
/// orchestrator economy build). Returns `true` as soon as the first
/// [ThreatSummary.atWarWith] entry resolves to a [Player] Great Power via
/// [Game.playerById]; tribes and minor nations are not [Player] entries and so
/// never satisfy the check.
///
/// Behaviour-preserving against the replaced inline predicates: this helper
/// retains the original [Iterable.any] short-circuit (no list is materialised
/// and no sort is performed), so it is strictly cheaper than
/// `gpFactionIdsAtWarWith(game, snapshot).isNotEmpty` for the pure presence
/// case — consistent with `colonizethis-turn-resolution-budget.mdc`. Use
/// [gpFactionIdsAtWarWith] when the caller needs the GP id list or its length.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool isAtWarWithAnyGreatPower(Game game, AIWorldSnapshot snapshot) =>
    snapshot.threats.atWarWith.any((id) => game.playerById(id) != null);

/// Number of techs [player] has unlocked — the count of `true` flags in
/// [Player.techUnlocked]. A `null` or empty map yields `0`.
///
/// Pure and deterministic for fixed inputs.
int unlockedTechCount(Player player) {
  final techs = player.techUnlocked;
  if (techs == null) return 0;
  var count = 0;
  for (final unlocked in techs.values) {
    if (unlocked) count++;
  }
  return count;
}

/// Whether the Great Power [activePlayerId] is **pursuing a tech-steal posture**
/// (decision #10, SPEC/ai/civilian-build-planner.md § Live economy wiring): it
/// has unlocked fewer techs than the most-advanced rival Great Power by at
/// least [kCivilianBuildSpyTechStealDeficit], so a `steal_tech` target exists
/// and the civilian Spy build receives the demand boost even at peace.
///
/// Iterates [Game.players] (Great Powers only — minor nations and tribes are not
/// [Player] entries; the list is small and bounded) to find the maximum rival
/// unlocked-tech count, then delegates the threshold comparison to the pure
/// data helper [isCivilianBuildSpyTechStealPosture]. Returns `false` when
/// [activePlayerId] is unknown or there are no rival Great Powers.
///
/// Pure and deterministic: identical [game] state and [activePlayerId] always
/// yield the same result (no randomness, no ordering dependence).
bool isPursuingTechStealPosture(Game game, String activePlayerId) {
  final active = game.playerById(activePlayerId);
  if (active == null) return false;
  var maxRivalCount = 0;
  var hasRival = false;
  for (final player in game.players) {
    if (player.id == activePlayerId) continue;
    hasRival = true;
    final count = unlockedTechCount(player);
    if (count > maxRivalCount) maxRivalCount = count;
  }
  if (!hasRival) return false;
  return isCivilianBuildSpyTechStealPosture(
    ownUnlockedTechCount: unlockedTechCount(active),
    maxRivalUnlockedTechCount: maxRivalCount,
  );
}

/// Whether the active player's own Old World expansion is stalled.
///
/// Single source of truth for the repeated
/// `isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)`
/// projection that was duplicated inline across the diplomatic-scoring and
/// expand-peace planner families. The active player's own OW holdings always
/// come from [ConquestSummary.oldWorldProvincesOwned]; deciders that test a
/// *different* faction's OW count (via a local `ownOw` / `partnerOw` /
/// `enemyOw` / `provinceCountOwnedBy(...)` value) must keep calling
/// [isStalledOldWorldExpansion] directly with that value.
///
/// Pure delegation — byte-identical to the inline projection it replaces, and
/// deterministic for fixed inputs (Refs #3717 diplomatic-scoring/expand-peace
/// dedup).
bool isOwnOldWorldExpansionStalled(AIWorldSnapshot snapshot) =>
    isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned);

/// Whether the active player's own Old World holdings are below the observer
/// conquest quota.
///
/// Single source of truth for the repeated
/// `isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)`
/// projection that was duplicated inline across the diplomatic-scoring and
/// expand-peace planner families. As with [isOwnOldWorldExpansionStalled],
/// deciders that test a *different* faction's OW count (via a local
/// `ownOw` / `partnerOw` / `enemyOw` / `provinceCountOwnedBy(...)` value)
/// must keep calling [isBelowObserverConquestQuota] directly with that value.
///
/// Pure delegation — byte-identical to the inline projection it replaces, and
/// deterministic for fixed inputs (Refs #3717 diplomatic-scoring/expand-peace
/// dedup).
bool isOwnOldWorldBelowConquestQuota(AIWorldSnapshot snapshot) =>
    isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned);

/// The signed Old World province lead [factionId] holds over the active player.
///
/// Single source of truth for the repeated
/// `provinceCountOwnedBy(game, <factionId>) -
/// snapshot.conquest.oldWorldProvincesOwned` projection — another faction's Old
/// World province count minus the active player's own — duplicated across the
/// conquest army-move stalled-GP-blocker bonus (`conquest_planner.dart`), the
/// orchestrator stalled min-regiment floor (`domain_planner_orchestrator.dart`),
/// and the EXPAND stronger-blocker / weak-holdings blocker peace deciders
/// (`expand_phase_planner_gp_blocker_peace.dart`). The active player's own OW
/// holdings always come from [ConquestSummary.oldWorldProvincesOwned]; a
/// positive result is the other faction's lead, which call sites treat as a
/// `lead` (peace deciders) or `deficit` (own-side regiment/bonus scaling).
///
/// Pure delegation to [provinceCountOwnedBy] — byte-identical to the inline
/// subtraction it replaces (a single O(1) memoised owner-count lookup; no extra
/// province scan, per `colonizethis-turn-resolution-budget.mdc`) and
/// deterministic for fixed inputs (Refs #3717 diplomatic-scoring/expand-peace
/// dedup).
int oldWorldProvinceLeadOver({
  required Game game,
  required AIWorldSnapshot snapshot,
  required String factionId,
}) =>
    provinceCountOwnedBy(game, factionId) -
    snapshot.conquest.oldWorldProvincesOwned;

/// Whether [factionId] (holding [ow] Old World provinces) qualifies as one side
/// of a "mutual-exhausted below-quota Great Power stalemate".
///
/// Single source of truth for the per-side qualification that was duplicated
/// for both the active player and the enemy Great Power across
/// [mutualExhaustedBelowQuotaGpStalematePeaceTargets]
/// (`expand_phase_planner_peer_peace.dart`) and the offer-peace bonus gate
/// `_mutualExhaustedBelowQuotaSoleGpStalemate`
/// (`diplomatic_candidate_scoring_offer_peace.dart`). A side qualifies when it:
///   * holds at least [kMutualExhaustedGpStalemateMinOw] Old World provinces,
///   * is below the observer conquest quota ([isBelowObserverConquestQuota] of
///     [ow]),
///   * has stalled Old World expansion ([isStalledOldWorldExpansion] of [ow]),
///   * resolves to a known [Player] ([Game.playerById]), and
///   * is materially exhausted: treasury `<=` [kMutualExhaustedGpTreasuryMax]
///     and standing regiments `<=` [kMutualExhaustedGpRegimentMax].
///
/// Callers pass the side's already-resolved Old World count
/// ([ConquestSummary.oldWorldProvincesOwned] for the active player,
/// [provinceCountOwnedBy] for the enemy) so no extra province scan is added; the
/// inter-side `(enemyOw - ownOw).abs()` proximity gate stays at the call site.
///
/// Pure projection over [game] — byte-identical to the inline per-side guards it
/// replaces (every operand is a side-effect-free read, so the guard evaluation
/// order is immaterial to the result) and deterministic for fixed inputs
/// (Refs #3717 offer-peace / expand-peace scoring-skeleton dedup).
bool mutualExhaustedGpStalemateSideQualifies({
  required Game game,
  required String factionId,
  required int ow,
}) {
  if (ow < kMutualExhaustedGpStalemateMinOw) {
    return false;
  }
  if (!isBelowObserverConquestQuota(ow)) {
    return false;
  }
  if (!isStalledOldWorldExpansion(ow)) {
    return false;
  }
  final player = game.playerById(factionId);
  if (player == null) {
    return false;
  }
  if (player.treasury > kMutualExhaustedGpTreasuryMax) {
    return false;
  }
  if (regimentCountForPlayer(game, factionId) > kMutualExhaustedGpRegimentMax) {
    return false;
  }
  return true;
}

/// Scales [baseConstant] by [weight] clamped to `[0.0, 1.0]`, returning the
/// rounded integer result.
///
/// Shared body of the soft-phase weight-scaling resolvers (Refs #2847 Phase 3
/// consumer wiring). Matches the prior inline idiom exactly:
///
///   - `weight <= 0.0` returns `0` (no bonus / floor applied).
///   - `weight >= 1.0` is clamped to `1.0`, returning `baseConstant` exactly.
///   - Intermediate weights return `round(baseConstant × weight)`.
///
/// The `<= 0.0` guard and `> 1.0` clamp boundaries are preserved verbatim from
/// the call sites so rounding semantics are identical.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
int scaleWeightedBonus(double weight, int baseConstant) {
  if (weight <= 0.0) {
    return 0;
  }
  final clamped = clampPhaseWeightUpperUnit(weight);
  return (baseConstant * clamped).round();
}

/// Upper-clamps a soft-phase priority [weight] to the unit ceiling `1.0`,
/// returning [weight] unchanged when it is already `<= 1.0`.
///
/// Single source of truth for the `weight > 1.0 ? 1.0 : weight` upper-clamp
/// idiom duplicated across the soft-phase weight-scaling sites (Refs #3717
/// phase weight-clamp dedup): [scaleWeightedBonus] above,
/// `conquestOldWorldArmyMoveScaledBonus` (`conquest_planner.dart`), and the
/// economy threshold-cap resolvers
/// `economyColonialPressureCivilianWorkThresholdCap` /
/// `economyColonialPressureBuildOrderThresholdCap`
/// (`phase_planner_economy_filter.dart`). Each call site already guards the
/// lower bound with its own `weight <= 0.0` early-out, so this helper only
/// caps the ceiling — byte-identical to the inline ternary it replaces. It
/// deliberately keeps the `> 1.0 ? 1.0 :` ternary rather than substituting
/// `weight.clamp(0.0, 1.0)`, which would alter results for the negative
/// inputs the callers' guards exclude.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
double clampPhaseWeightUpperUnit(double weight) => weight > 1.0 ? 1.0 : weight;

/// Structural predicate: `true` only under [ObserverGoalPhase.colonial].
///
/// Single source of truth for the colonial-pressure "active" gate shared by
/// the conquest, economy, diplomacy, and goal phase filters. Each filter's
/// public resolver delegates here so the `phase == ObserverGoalPhase.colonial`
/// comparison lives once.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
bool resolvePhaseColonialPressureActive(ObserverGoalPhase phase) =>
    phase == ObserverGoalPhase.colonial;

/// Structural predicate: `true` under [ObserverGoalPhase.expand] and
/// [ObserverGoalPhase.colonialLite] (the below-quota OW-expansion phases).
///
/// Single source of truth for the `phase == expand || phase == colonialLite`
/// gate shared by the conquest extra-passes resolver and the goal-filter
/// colonial-pressure suppression resolver. Both phases require
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` at entry.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
bool resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase phase) =>
    phase == ObserverGoalPhase.expand ||
    phase == ObserverGoalPhase.colonialLite;

/// Projects the soft-phase New-World-acquisition priority weight from
/// [phasePlan].
///
/// Single source of truth for the
/// `phasePlan.priorityWeights.newWorldAcquisition` projection shared by the
/// conquest, naval, diplomacy, and economy phase filters (Refs #3717
/// phase-filter weight-projection dedup). Each family's public weight resolver
/// delegates here so the `PhasePlanOutcome` → `priorityWeights` slot mapping
/// lives once, mirroring the existing [resolvePhaseColonialPressureActive] /
/// [scaleWeightedBonus] dedup. Reads only `phasePlan.priorityWeights` and never
/// inspects sibling slots.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
double resolvePhaseNewWorldAcquisitionWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.newWorldAcquisition;

/// Projects the soft-phase Old-World-conquest priority weight from [phasePlan].
///
/// Companion of [resolvePhaseNewWorldAcquisitionWeight]; single source of truth
/// for the `phasePlan.priorityWeights.oldWorldConquest` projection shared by the
/// conquest and diplomacy declare-war filters (Refs #3717).
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseOldWorldConquestWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.oldWorldConquest;

/// Projects the soft-phase Old-World-civilian priority weight from [phasePlan].
///
/// Companion of [resolvePhaseNewWorldAcquisitionWeight]; single source of truth
/// for the `phasePlan.priorityWeights.oldWorldCivilian` projection used by the
/// economy filter (Refs #3717).
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseOldWorldCivilianWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.oldWorldCivilian;

/// Projects the soft-phase New-World-civilian priority weight from [phasePlan].
///
/// Companion of [resolvePhaseNewWorldAcquisitionWeight]; single source of truth
/// for the `phasePlan.priorityWeights.newWorldCivilian` projection used by the
/// economy filter (Refs #3717).
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseNewWorldCivilianWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.newWorldCivilian;

/// Resolves a per-family phase-filter resolution from [phasePlan].
///
/// Single source of truth for the "project a non-default resolution from the
/// active [PhasePlanOutcome]; fall back to the family's [defaultResolution]
/// when no arm fires" skeleton repeated across the phase-filter Resolution
/// families ([resolvePhaseNavalDirective] in `phase_planner_naval_filter.dart`
/// and [resolvePhaseConquestInvadable] in `phase_planner_conquest_filter.dart`,
/// Refs #3717 phase-filter resolution-skeleton dedup). Each family supplies
/// only its own [project] callback (returning the populated resolution when a
/// phase / phase-plan arm applies, or `null` to defer) plus its
/// [defaultResolution]; the `project(...) ?? defaultResolution` fallback lives
/// once here.
///
/// Behaviour-preserving against the inline `if (...) return X; ... return
/// default;` chains it replaces: [project] is evaluated exactly once and its
/// non-null result is returned verbatim, otherwise [defaultResolution] is
/// returned, so results are byte-identical for a pure [project]. The generic
/// [T] keeps each family's concrete resolution type (no boxing / shared base
/// type) so callers retain full static typing.
///
/// Pure and deterministic — identical inputs (and a pure [project]) always
/// yield identical resolutions (Refs #2509 Must-have #7). Adds no scan cost
/// beyond the caller's own [project], consistent with
/// `colonizethis-turn-resolution-budget.mdc`.
T resolveFromPhasePlan<T>({
  required PhasePlanOutcome phasePlan,
  required T defaultResolution,
  required T? Function(PhasePlanOutcome phasePlan) project,
}) =>
    project(phasePlan) ?? defaultResolution;

/// Whether the most-recent [Game.diplomaticHistoryEvents] entry satisfying
/// [matches] falls within [cooldownTurns] turns of [currentTurn].
///
/// Single source of truth for the "scan the diplomatic history newest first,
/// let the first matching event decide, and report whether it is inside the
/// cooldown window" skeleton shared by the declare-war / improve-relations
/// scoring cooldowns in `diplomatic_candidate_scoring.dart` and the EXPAND
/// peer-war peace cooldown ([expandRecentlyPeacedWithGreatPower]) in
/// `expand_phase_planner.dart` (Refs #3717 diplomatic-scoring/peace dedup).
/// Each caller supplies only its own [matches] predicate — directional
/// `fromFactionId`/`toFactionId` plus event-type membership for the scoring
/// cooldowns; symmetric `participants` plus the `peace` type for the EXPAND
/// cooldown — while the reversed scan, first-match-wins short-circuit, and the
/// `(currentTurn - event.turn) < cooldownTurns` window comparison live here.
///
/// Behaviour-preserving against the replaced inline loops: history is ordered
/// ascending by turn / intra-turn index, so `.reversed` visits the newest
/// event first and that newest matching event decides. The strict `<` keeps an
/// event exactly [cooldownTurns] turns old *outside* the window, and a missing
/// match returns `false`. This helper applies no non-positive-[cooldownTurns]
/// guard; callers that disable the cooldown that way (the EXPAND caller's
/// `cooldownTurns <= 0` early-out) must guard before calling. For positive
/// [cooldownTurns] the result is identical to the prior per-call-site loops.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7). Linear in the diplomatic-history length in the
/// worst case, matching `colonizethis-turn-resolution-budget.mdc`.
bool hasRecentDiplomaticEventWithinCooldown({
  required Game game,
  required int currentTurn,
  required int cooldownTurns,
  required bool Function(DiplomaticEvent event) matches,
}) {
  for (final event in game.diplomaticHistoryEvents.reversed) {
    if (!matches(event)) continue;
    return (currentTurn - event.turn) < cooldownTurns;
  }
  return false;
}

/// Single source of truth for the "candidate is an at-war Great Power peace
/// target -> add a flat scoring bonus" skeleton repeated across the offer-peace
/// scoring family (`_offerPeacePeaceTargetListAdjustments` in
/// `diplomatic_candidate_scoring_offer_peace.dart`, Refs #3717
/// diplomatic-scoring/peace dedup). Returns [bonus] only when
/// [atWarGreatPowerTarget] holds *and* the lazily-evaluated [isPeaceTarget]
/// predicate matches; otherwise 0.
///
/// Behaviour-preserving against the replaced inline blocks, which each guarded
/// `targetGp != null && snapshot.threats.atWarWith.contains(target) && <peace
/// target match>` before adding a constant. [isPeaceTarget] is a callback so
/// the (potentially non-trivial, pure) peace-target collectors are only
/// consulted for eligible at-war GP candidates — preserving the original `&&`
/// short-circuit so no extra collector work runs for ineligible candidates.
///
/// Pure and deterministic for a given eligibility flag and predicate result
/// (Refs #2509 Must-have #7); the constant-time wrapper adds no scan cost
/// beyond the caller's own predicate, consistent with
/// `colonizethis-turn-resolution-budget.mdc`.
int atWarPeaceTargetBonus({
  required bool atWarGreatPowerTarget,
  required bool Function() isPeaceTarget,
  required int bonus,
}) => atWarGreatPowerTarget && isPeaceTarget() ? bonus : 0;

/// Single source of truth for the offer-peace family's repeated "the order's
/// target is a Great Power we are currently at war with" eligibility
/// projection (Refs #3717 offer-peace scoring-skeleton dedup). Returns `true`
/// only when [targetGp] is non-null (the target faction resolves to a [Player]
/// Great Power, as opposed to a tribe / minor nation) *and*
/// [AIWorldSnapshot.threats]'s `atWarWith` set contains [targetFactionId].
///
/// Behaviour-preserving against the replaced inline guards in
/// `diplomatic_candidate_scoring_offer_peace.dart`, which each spelled out
/// `targetGp != null && snapshot.threats.atWarWith.contains(order
/// .targetFactionId)` before applying an offer-peace adjustment. Callers pass
/// the already-resolved [targetGp] (`game.playerById(order.targetFactionId)`)
/// so no extra player lookup is introduced. Pairs with [atWarPeaceTargetBonus],
/// which consumes this flag as its `atWarGreatPowerTarget` input.
///
/// The original `&&` short-circuited the `atWarWith.contains` membership test
/// when `targetGp == null`; this helper always evaluates that pure, side-effect
/// free set membership, yielding an identical boolean result. Pure and
/// deterministic — identical inputs always yield identical results (Refs #2509
/// Must-have #7).
bool atWarGreatPowerOrderTarget({
  required Player? targetGp,
  required AIWorldSnapshot snapshot,
  required String targetFactionId,
}) => targetGp != null && snapshot.threats.atWarWith.contains(targetFactionId);

/// Single source of truth for the offer-peace family's repeated "the order's
/// target is the at-war primary invadable Old World GP blocker" eligibility
/// projection (Refs #3717 offer-peace scoring-skeleton dedup). Returns `true`
/// only when [targetGp] resolves to a [Player] Great Power, the
/// [primaryInvadableOldWorldGpBlocker] result passed as [invadableBlocker] is
/// non-null, [targetFactionId] equals that blocker, *and*
/// [AIWorldSnapshot.threats]'s `atWarWith` set contains the blocker.
///
/// Behaviour-preserving against the replaced inline guards in
/// `diplomatic_candidate_scoring_offer_peace.dart`, which each spelled out
/// `targetGp != null && blocker != null && order.targetFactionId == blocker &&
/// snapshot.threats.atWarWith.contains(blocker)` before applying a blocker-
/// specific offer-peace adjustment. Callers pass the already-resolved
/// [targetGp] (`game.playerById(order.targetFactionId)`) and the single
/// [primaryInvadableOldWorldGpBlocker] result so no extra player lookup or
/// blocker recomputation is introduced — consistent with
/// `colonizethis-turn-resolution-budget.mdc`.
///
/// The original `&&` short-circuited the later conjuncts when `targetGp` or the
/// blocker was null; this helper always evaluates the pure, side-effect-free
/// equality and set-membership tests, yielding an identical boolean result.
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool orderTargetIsAtWarInvadableBlocker({
  required Player? targetGp,
  required AIWorldSnapshot snapshot,
  required String targetFactionId,
  required String? invadableBlocker,
}) =>
    targetGp != null &&
    invadableBlocker != null &&
    targetFactionId == invadableBlocker &&
    snapshot.threats.atWarWith.contains(invadableBlocker);

/// Whether any invadable Old-World frontier province is currently owned by a
/// minor nation.
///
/// Single source of truth for the `minorsOwnInvadable` scan —
/// `snapshot.conquest.invadableProvinceIdsSorted.any((pid) { final owner =
/// provinceOwner[pid]; return owner != null && game.minorNations.any((m) =>
/// m.id == owner); })` — duplicated across the EXPAND-peace deciders
/// ([stalledStrongerGpBlockerPeaceTarget], [stalledGpBlockerFocusPeaceTargets],
/// [stalledExpansionDistractionPeaceTargets],
/// [expandIsOldWorldGpOnlyInvadableFrontier], the peer-peace ratchet collector)
/// and the declare-war family (the `diplomacy_planner` declare-war tribe-drop
/// filter and the declare-war candidate-scoring near-parity suppression) (Refs
/// #3717 expand-peace scoring-skeleton dedup).
///
/// Callers pass the already-resolved [provinceOwner] map
/// (`getProvinceOwnerMap(game)`) so no extra O(provinces) ownership scan is
/// introduced — consistent with `colonizethis-turn-resolution-budget.mdc`.
/// Walks [ConquestSummary.invadableProvinceIdsSorted] with the original
/// [Iterable.any] short-circuit: returns `true` as soon as an invadable
/// province's owner resolves to a [Game.minorNations] member (via the shared
/// [isMinorFaction] predicate); an unowned (absent / `null`) entry or a
/// Great-Power / tribe owner never matches.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool anyInvadableProvinceOwnedByMinor({
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
}) => snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
  final owner = provinceOwner[pid];
  return owner != null && isMinorFaction(game, owner);
});

/// Whether any invadable Old-World frontier province is currently owned by a
/// Great Power.
///
/// Single source of truth for the `gpOwnsInvadable` scan —
/// `snapshot.conquest.invadableProvinceIdsSorted.any((pid) =>
/// game.playerById(provinceOwner[pid] ?? '') != null)` — duplicated across the
/// EXPAND GP-only-frontier gate ([expandIsOldWorldGpOnlyInvadableFrontier]) and
/// the declare-war candidate-scoring near-parity suppression (the
/// `invadableOwOwnedByGp` projection in `diplomatic_candidate_scoring_declare_
/// war.dart`) (Refs #3717 expand-peace / diplomatic-scoring scoring-skeleton
/// dedup). Companion of [anyInvadableProvinceOwnedByMinor], which answers the
/// minor-owner variant of the same invadable-frontier ownership question.
///
/// Callers pass the already-resolved [provinceOwner] map
/// (`getProvinceOwnerMap(game)`) so no extra O(provinces) ownership scan is
/// introduced — consistent with `colonizethis-turn-resolution-budget.mdc`.
/// Walks [ConquestSummary.invadableProvinceIdsSorted] with the original
/// [Iterable.any] short-circuit: returns `true` as soon as an invadable
/// province's owner resolves to a [Game.playerById] Great Power; an unowned
/// (absent / `null`) entry — normalised to the empty string so `playerById`
/// returns `null` — or a minor / tribe owner never matches.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool anyInvadableProvinceOwnedByGreatPower({
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
}) => snapshot.conquest.invadableProvinceIdsSorted.any(
  (pid) => game.playerById(provinceOwner[pid] ?? '') != null,
);

/// Whether [factionId] owns at least one invadable Old-World frontier province.
///
/// Single source of truth for the
/// `snapshot.conquest.invadableProvinceIdsSorted.any((pid) =>
/// provinceOwner[pid] == <factionId>)` scan duplicated across the conquest /
/// expand-peace planners ([stalledStrongerGpBlockerPeaceTarget]'s sibling
/// peer-peace / peace-target / default-start collectors and the conquest
/// declared-target check) and the declare-war / offer-peace candidate-scoring
/// families (the declare-war target context's `invadableGpBlocker` /
/// `tribeOwnsOwInvadable` projections and the offer-peace stalled-GP-war
/// adjustments) (Refs #3717 diplomatic-scoring / expand-peace scoring-skeleton
/// dedup). Companion of [anyInvadableProvinceOwnedByMinor], which answers the
/// minor-owner variant of the same invadable-frontier ownership question.
///
/// Takes a non-nullable-value [provinceOwner] (`Map<String, String>`), matching
/// the `getProvinceOwnerMap(game)` callers; the structurally-identical
/// move-scoring site that threads a `Map<String, String?>` owner map keeps its
/// inline scan.
///
/// Callers pass the already-resolved [provinceOwner] map
/// (`getProvinceOwnerMap(game)`) so no extra O(provinces) ownership scan is
/// introduced — consistent with `colonizethis-turn-resolution-budget.mdc`.
/// Walks [ConquestSummary.invadableProvinceIdsSorted] with the original
/// [Iterable.any] short-circuit: returns `true` as soon as an invadable
/// province's owner equals [factionId]; an unowned (absent / `null`) entry or a
/// different owner never matches.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool factionOwnsInvadableOldWorldProvince({
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
  required String factionId,
}) => snapshot.conquest.invadableProvinceIdsSorted.any(
  (pid) => provinceOwner[pid] == factionId,
);

/// Adds, into [into], every minor-nation owner of an invadable Old-World
/// frontier province with whom this Great Power is not already at war.
///
/// Single source of truth for the `for (final pid in
/// snapshot.conquest.invadableProvinceIdsSorted) { final owner =
/// provinceOwner[pid]; if (owner == null || !isMinorFaction(game, owner) ||
/// snapshot.threats.atWarWith.contains(owner)) continue; candidates.add(owner);
/// }` collector skeleton duplicated across the legacy colonial-pressure
/// declare-war target deciders in `diplomacy_planner_declare_war_targets.dart`
/// ([criticalWeakUninvadedMinorDeclareTarget], [plateauOwMinorDeclareTarget],
/// [defaultStartOwMinorDeclareTarget]) (Refs #3717 declare-war target collector
/// dedup).
///
/// Callers pass the already-resolved [provinceOwner] map
/// (`getProvinceOwnerMap(game)`) so no extra O(provinces) ownership scan is
/// introduced — consistent with `colonizethis-turn-resolution-budget.mdc` — and
/// supply their own mutable [into] set so a caller may seed it with
/// adjacent-owner candidates first (set membership de-duplicates; final
/// ordering is the caller's `..sort()`). Walks
/// [ConquestSummary.invadableProvinceIdsSorted] in order, skipping unowned
/// (absent / `null`) entries, non-minor (Great-Power / tribe) owners, and minors
/// already in [ThreatSummary.atWarWith].
///
/// Pure and deterministic — identical inputs always yield identical additions
/// (Refs #2509 Must-have #7).
void addInvadableProvinceMinorOwnersNotAtWar({
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
  required Set<String> into,
}) {
  for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
    final owner = provinceOwner[pid];
    if (owner == null ||
        !isMinorFaction(game, owner) ||
        snapshot.threats.atWarWith.contains(owner)) {
      continue;
    }
    into.add(owner);
  }
}
