part of 'expand_phase_planner.dart';

/// Maximum OW province gap a below-quota peer war is peaced across when an
/// uninvaded OW minor pivot remains on the map (Refs #2509).
///
/// While at least one OW minor still owns provinces and is not already at
/// war with the active player, the EXPAND-phase peer-stalled peace decider
/// [belowQuotaPeerGpPeaceTargets] is allowed to peace below-quota Great
/// Power peers within this OW deficit so the planner can pivot off mutual
/// gp5/gp6 distraction wars and chase the minor frontier instead. Once the
/// last uninvaded minor has been declared on, the gap collapses to
/// [_kMaxPeerOwGapWithoutMinors] (1) to keep the below-quota peer-stalled
/// pivot tight (no arbitrary GP-war dumps on far-apart peers).
///
/// Equivalent to the legacy magic value `3` in
/// `colonial_pressure.dart::belowQuotaPeerGpPeaceTargets`; named here as a
/// private constant so the canonical move documents the SPEC contract
/// (`SPEC/ai/ai-architecture.md` § Observer goal phases EXPAND
/// "While uninvaded OW minors remain, also peace below-quota GP peers
/// within three provinces") without changing the runtime value.
const int _kMaxPeerOwGapWithMinors = 3;

/// Maximum OW province gap a below-quota peer war is peaced across when no
/// uninvaded OW minor pivot remains (Refs #2509).
///
/// Companion to [_kMaxPeerOwGapWithMinors]: once every on-map minor is
/// already at war with the active player (or no minors remain at all), the
/// EXPAND-phase peer-stalled peace decider [belowQuotaPeerGpPeaceTargets]
/// only peaces below-quota Great Power peers within one OW province of the
/// active player. Equivalent to the legacy magic value `1` in
/// `colonial_pressure.dart::belowQuotaPeerGpPeaceTargets`.
const int _kMaxPeerOwGapWithoutMinors = 1;

/// Returns the deterministic ascending-sorted list of at-war below-quota
/// Great Power `factionId`s the active player should `offerPeace` toward
/// in EXPAND when the peer-stalled peace pivot applies, or `const []`
/// when the pivot does not fire this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `belowQuotaPeerGpPeaceTargets` peace decider previously hosted in
/// `colonial_pressure.dart`. The decider implements the EXPAND-phase
/// "peace other below-quota Great Powers in peer-stalled wars while
/// minors remain on the map" pivot for seed-42 gp5/gp6 (mutual gp5/gp6
/// distraction wars). It composes the canonical helpers
/// [isOldWorldGpOnlyInvadableFrontier], [soleAtWarGreatPowerId],
/// [isMutualBelowQuotaPlateauPeer], and [hasUninvadedOldWorldMinor] with
/// the below-quota peer-gap band table from `SPEC/ai/ai-architecture.md`
/// § Observer goal phases (EXPAND) "While uninvaded OW minors remain,
/// also peace below-quota GP peers within three provinces".
///
/// Returns `const []` for the outer guard:
///   * [isBelowObserverConquestQuota] is `false` for
///     [ConquestSummary.oldWorldProvincesOwned] — at or above the
///     observer OW quota the quota-met futile-peace collectors
///     ([quotaMetFutileBelowQuotaGpPeaceTargets] et al, still in
///     `colonial_pressure.dart` at this slice) take over.
///
/// When the outer guard passes, the function iterates
/// [ThreatSummary.atWarWith] and selects below-quota Great Power peers
/// (filtered via [Game.playerById]; partners passing
/// [isBelowObserverConquestQuota] only) per the two-arm contract:
///
///   * **Mutual-plateau GP-only-frontier carve-out** — when the peer
///     war is a mutual-plateau sole-GP stalemate
///     ([isMutualBelowQuotaPlateauPeer] is `true`) on a GP-only
///     invadable frontier ([isOldWorldGpOnlyInvadableFrontier] is
///     `true`) with no uninvaded OW minors remaining
///     ([hasUninvadedOldWorldMinor] is `false`), peace the lone GP
///     partner so the planner can exit the stalemate even when the
///     standard peer-gap / stronger-self guards would otherwise hold
///     the war open. This carve-out fires unconditionally — the peer
///     stays in the result regardless of the OW gap.
///
///   * **Standard peer-gap arm** — every other shape. The arm fires
///     only when at least one minor still owns OW provinces (the
///     `minorsOnMap` precondition; not the same as
///     `hasUninvadedOldWorldMinor` because an on-map minor already at
///     war with the active player still satisfies `minorsOnMap` but
///     not `hasUninvadedOldWorldMinor`) or when the mutual-plateau
///     guard fires above. The arm then enforces three gates in order:
///       1. **Symmetric OW-gap cap** — `(partnerOw - ownOw).abs()` must
///          be within `[_kMaxPeerOwGapWithMinors]` (`3`) when an
///          uninvaded minor pivot remains, otherwise within
///          `[_kMaxPeerOwGapWithoutMinors]` (`1`). The cap prevents
///          the weaker peer from dumping below-quota GP wars at
///          arbitrary OW gaps.
///       2. **Stronger-self symmetry guard** — when the peer war is
///          not a mutual-plateau and the active player holds more OW
///          provinces than the partner (`ownOw > partnerOw`), the
///          partner is **not** peaced; only the weaker peer pivots
///          off the distraction war (the spec is symmetric around the
///          mutual-plateau equality band).
///       3. **Sole-GP-blocker hold-open** — when the GP-only-frontier
///          arm fires ([isOldWorldGpOnlyInvadableFrontier] is `true`)
///          and the partner is the sole at-war GP
///          ([soleAtWarGreatPowerId] returns the partner's id) with
///          an uninvaded minor pivot still missing
///          ([hasUninvadedOldWorldMinor] is `false`), the war is held
///          open (the partner is skipped) so the planner keeps
///          fighting the lone GP blocker. The mutual-plateau
///          carve-out above intentionally short-circuits before this
///          guard so a mutual-plateau sole-GP stalemate still peaces
///          out even on a GP-only frontier.
///
/// The returned list is sorted ascending by `factionId` for
/// deterministic ordering (Must-have #7). Tribes, minors, and at-war
/// GPs that fail [isBelowObserverConquestQuota] are dropped silently.
///
/// `colonial_pressure.dart` retains a thin delegating stub for legacy
/// callers (the existing `expand_phase_planner_peer_peace_basic_test.dart` and
/// `expand_phase_planner_peer_gap_boundary_test.dart` fixtures, the
/// `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` /
/// `diplomatic_candidate_scoring_offer_peace.dart` consumer chain, and
/// the related `colonial_pressure_*` branch-coverage fixtures that
/// reference the peer-gap helper) so the planned S1 deletion of that
/// file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// with one [provinceCountOwnedBy] scan per at-war faction; the
/// composed [isOldWorldGpOnlyInvadableFrontier],
/// [soleAtWarGreatPowerId], [isMutualBelowQuotaPlateauPeer], and
/// [hasUninvadedOldWorldMinor] helpers are themselves linear in the
/// OW invadable / minor sets, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc` (no global province /
/// tile scans introduced by the move).
List<String> belowQuotaPeerGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw)) {
    return const [];
  }
  final minorsOnMap = game.worldState.oldWorld.provinces.any(
    (p) =>
        p.ownerId != null &&
        p.ownerId!.isNotEmpty &&
        game.minorNations.any((m) => m.id == p.ownerId),
  );
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  final soleGpWar = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  final targets = <String>[];
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) {
      continue;
    }
    final partnerOw = provinceCountOwnedBy(game, factionId);
    if (!isBelowObserverConquestQuota(partnerOw)) {
      continue;
    }
    final mutualPlateau = isMutualBelowQuotaPlateauPeer(
      ownOw: ownOw,
      partnerOw: partnerOw,
    );
    if (!minorsOnMap && !mutualPlateau) {
      continue;
    }
    if (mutualPlateau &&
        gpOnlyFrontier &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      targets.add(factionId);
      continue;
    }
    final maxPeerOwGap =
        hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)
        ? _kMaxPeerOwGapWithMinors
        : _kMaxPeerOwGapWithoutMinors;
    if ((partnerOw - ownOw).abs() > maxPeerOwGap) {
      continue;
    }
    if (!mutualPlateau && ownOw > partnerOw) {
      continue;
    }
    if (gpOnlyFrontier &&
        soleGpWar == factionId &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      continue;
    }
    targets.add(factionId);
  }
  targets.sort();
  return targets;
}

/// Returns the deterministic ascending-sorted list of at-war Great Power
/// `factionId`s the active player should `offerPeace` toward in EXPAND
/// when stalled below the observer quota and minors still hold
/// invadable Old World land — the legacy "stalled futile GP" peace
/// pivot — or `const []` when the pivot does not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledFutileGpPeaceTargets` peace decider previously hosted in
/// `diplomacy_planner_peace_targets.dart`. The decider implements the
/// EXPAND-phase "while stalled with a minor still on the invadable
/// frontier, peace every at-war Great Power that owns none of the
/// invadable OW provinces" pivot — distracting GP wars are dropped so
/// the planner can focus regiments on the invadable minor frontier.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — the planner is
///      not in the stalled OW band so the futile-GP shortcut does
///      not apply (above-quota collectors take over).
///   2. [ConquestSummary.invadableProvinceIdsSorted] is empty — no
///      OW invasion target exists so a futile-GP diagnosis is not
///      possible this turn.
///   3. No minor owns any province in
///      [ConquestSummary.invadableProvinceIdsSorted] — the frontier
///      is GP-only / unowned, so the "stalled with minors still
///      holding invadable land" precondition is missing and the
///      `stalledGpBlockerFocusPeaceTargets` collector owns the
///      decision instead.
///
/// When the guards pass, the function peaces every at-war Great
/// Power (filtered via [Game.playerById]) that does **not** own any
/// province in [ConquestSummary.invadableProvinceIdsSorted] — GPs
/// that own at least one invadable OW province are kept at war
/// (active blockers that
/// `stalledGpBlockerFocusPeaceTargets` / `stalledStrongerGpBlockerPeaceTarget`
/// will route through their own arms). The output is sorted
/// ascending by `factionId` for deterministic ordering.
///
/// `diplomacy_planner_peace_targets.dart` retains a thin delegating
/// stub for legacy callers (the existing
/// `diplomacy_planner_stalled_peace_test.dart` § `stalledFutileGpPeaceTargets`
/// fixture and the `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains within
/// `diplomacy_planner_peace_targets.dart` itself) so the planned S1
/// deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith], plus a single [getProvinceOwnerMap]
/// pass shared with the `minorsOwnInvadable` precondition scan,
/// matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc` (no global province /
/// tile scans introduced by the move).
List<String> stalledFutileGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any((
    pid,
  ) {
    final owner = provinceOwner[pid];
    return owner != null && game.minorNations.any((m) => m.id == owner);
  });
  if (!minorsOwnInvadable) {
    return const [];
  }
  final targets = <String>[];
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    final ownsInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == factionId,
    );
    if (ownsInvadable) continue;
    targets.add(factionId);
  }
  targets.sort();
  return targets;
}

/// Returns the deterministic ascending-sorted list of at-war tribe
/// `factionId`s the active player should `offerPeace` toward in
/// EXPAND when stalled below the observer quota and at least one
/// at-war Great Power is on the same map — the legacy "GP-distraction
/// tribe peace" pivot — or `const []` when the pivot does not apply
/// this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `atWarGpDistractionTribePeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. The decider
/// implements the EXPAND-phase "while OW-stalled and at war with at
/// least one Great Power, peace every at-war tribe so regiments
/// concentrate on the OW consolidation push" pivot. Tribes are
/// distractions during a GP war regardless of which province they
/// own — they do not block OW invadable progress and their wars
/// drain regiments / treasury away from the GP front. (Tribes are
/// non-Great-Power, non-Minor factions registered under
/// [Game.tribes]; see `colonizethis-data` faction taxonomy.)
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — the planner is
///      not in the stalled OW band so the GP-distraction tribe
///      shortcut does not apply.
///   2. No at-war Great Power is present in
///      [ThreatSummary.atWarWith] (filtered via [Game.playerById])
///      — without an active GP front there is no OW consolidation
///      pressure to justify peacing tribes.
///
/// When the guards pass, the function emits every at-war tribe
/// (membership tested via [Game.tribes]) sorted ascending by
/// `factionId` for deterministic ordering. Minors and at-war Great
/// Powers in [ThreatSummary.atWarWith] are filtered out — minors
/// are routed through the focus / futile minor collectors and GPs
/// through the GP-blocker / consolidate collectors.
///
/// `diplomacy_planner_peace_targets.dart` retains a thin delegating
/// stub for legacy callers (the
/// `_expandRatchetGreatPowerPeaceTargets` / `collectStalledGreatPowerPeaceTargets`
/// consumer chains within `diplomacy_planner_peace_targets.dart`
/// itself, the `stalledOwExpansionNeedsPeacePass` predicate, and any
/// COLONIAL-phase tribe-peace flag consumers via
/// `collectStalledGreatPowerPeaceTargets`) so the planned S1 deletion
/// of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] across both filter passes, no global
/// province / tile scans introduced by the move, matching the
/// budget-rule note in `colonizethis-turn-resolution-budget.mdc`.
List<String> atWarGpDistractionTribePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final atWarWithGp = snapshot.threats.atWarWith.any(
    (id) => game.playerById(id) != null,
  );
  if (!atWarWithGp) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.tribes.any((t) => t.id == factionId)) factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic ascending-sorted list of at-war Great Power
/// `factionId`s the active player should `offerPeace` toward this turn
/// when EXPAND-stalled with zero standing regiments — the survival peace
/// arm that releases every GP front so the planner can rebuild a force
/// before any further declare-war or conquest pass.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledZeroRegimentGpPeaceTargets` peace decider previously hosted
/// in `diplomacy_planner_peace_targets.dart`. Implements
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when stalled
/// below quota with zero regiments, peace every at-war Great Power so
/// rebuild is not blocked by futile fronts (seed-42 gp5/gp6)". This
/// helper covers the GP-vs-GP fronts; the parallel minor/tribe arm is
/// [stalledZeroRegimentAllFactionPeaceTargets] (still hosted in
/// `diplomacy_planner_peace_targets.dart` at this slice — separate
/// canonical-home migration).
///
/// Returns `const []` for either of the outer guards (each `continue`s
/// past the firing branch):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — outside the stalled
///      OW band the rebuild-peace arm does not engage and the broader
///      EXPAND peace deciders ([planExpandPeace], the
///      `_expandRatchetGreatPowerPeaceTargets` survival chain) own the
///      decision.
///   2. [regimentCountForPlayer] is strictly greater than zero — when
///      the active player still has at least one standing regiment the
///      planner can press the existing GP wars and the zero-regiment
///      survival shortcut does not apply.
///
/// When both guards pass, the function peaces every at-war Great Power
/// (filtered via [Game.playerById] so minors and tribes route to the
/// companion [stalledZeroRegimentAllFactionPeaceTargets]); the returned
/// list is sorted ascending by `factionId` for deterministic ordering
/// regardless of the iteration order of [ThreatSummary.atWarWith]
/// (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` retains a thin delegating stub
/// for legacy callers (the existing
/// `diplomacy_planner_below_quota_peace_part3_test.dart` § "all GP wars
/// when stalled" fixture and the in-file
/// `_survivalGreatPowerPeaceTargets` / `collectStalledGreatPowerPeaceTargets`
/// `zeroRegimentBlockerPeace` / `stalledOwExpansionNeedsPeacePass`
/// consumer chains) so the planned S1 deletion of that file leaves no
/// orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// (each at-war faction is inspected once); constant-time on the outer
/// guard arms.
List<String> stalledZeroRegimentGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic single-element list with the sole at-war
/// Great Power's `factionId` when both the active player and the lone GP
/// enemy have zero standing regiments — the mutual-stalemate reset arm
/// that exits a regiment-exhausted GP-only frontier.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `mutualZeroRegimentGpStalematePeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. Implements the
/// "zero-regiment mutual stalemate" carve-out from
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — without this
/// arm, two GPs that have driven each other to zero regiments on a
/// GP-only invadable frontier stay locked at war with no armies until
/// one side rebuilds, which the [stalledZeroRegimentGpPeaceTargets]
/// general arm cannot resolve when the partner is the canonical OW
/// frontier blocker (the GP-only-frontier carve-out in
/// `collectStalledGreatPowerPeaceTargets` would otherwise re-add the
/// blocker to the keep-at-war set). The mutually-exhausted variant
/// [mutualExhaustedBelowQuotaGpStalematePeaceTargets] (still hosted in
/// `diplomacy_planner_peace_targets.dart` at this slice — separate
/// canonical-home migration) covers the same stalemate at non-zero but
/// critically low regiment counts.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — outside the stalled
///      OW band the planner is still pressing OW expansion and the
///      mutual-stalemate reset does not apply.
///   2. [regimentCountForPlayer] is strictly greater than zero for the
///      active player — the reset only fires when this GP has already
///      exhausted its standing army.
///   3. The active player has anything other than exactly one Great
///      Power in [ThreatSummary.atWarWith] (filtered via
///      [Game.playerById]). Multi-GP wars are handled by the broader
///      [multiFrontNonBlockerGpPeaceTargets] family; zero-GP wars
///      cannot return a peace target.
///   4. The sole GP enemy still has at least one standing regiment
///      ([regimentCountForPlayer] strictly greater than zero) — the
///      reset requires both sides to be exhausted so neither can press
///      the war forward.
///
/// When every guard passes, the function returns the single-element
/// list containing the lone enemy's `factionId` (one element so sort
/// order is trivial).
///
/// `diplomacy_planner_peace_targets.dart` retains a thin delegating stub
/// for legacy callers (the in-file
/// `_survivalGreatPowerPeaceTargets` / `collectStalledGreatPowerPeaceTargets`
/// `zeroRegimentBlockerPeace` / `stalledOwExpansionNeedsPeacePass`
/// consumer chains) so the planned S1 deletion of that file leaves no
/// orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// for the GP-war filter; constant-time on every other arm.
List<String> mutualZeroRegimentGpStalematePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.length != 1) {
    return const [];
  }
  final enemy = gpWars.single;
  if (regimentCountForPlayer(game, enemy) > 0) {
    return const [];
  }
  return [enemy];
}

/// Returns the deterministic ascending-sorted list of at-war minor and
/// tribe `factionId`s the active player should `offerPeace` toward when
/// below the observer quota, stalled, and holding zero standing regiments.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledZeroRegimentAllFactionPeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. Implements
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — the minor/tribe
/// companion to [stalledZeroRegimentGpPeaceTargets] (GP-vs-GP fronts).
///
/// Returns `const []` when [isBelowObserverConquestQuota] is `false`,
/// [isStalledOldWorldExpansion] is `false`, or the active player still
/// holds at least one standing regiment. When all guards pass, peaces
/// every at-war faction that is not a Great Power ([Game.playerById]
/// is `null`), sorted ascending (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` retains a thin delegating stub
/// for legacy callers until the planned S1 deletion of that file.
List<String> stalledZeroRegimentAllFactionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) == null) factionId,
  ]..sort();
  return targets;
}

/// Returns the sole at-war GP enemy when both sides are mutual-plateau peers
/// below quota and mutually exhausted in regiments and treasury.
///
/// Canonical home (Refs #2509 S1) for
/// `mutualExhaustedBelowQuotaGpStalematePeaceTargets`.
List<String> mutualExhaustedBelowQuotaGpStalematePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (ownOw < kMutualExhaustedGpStalemateMinOw) {
    return const [];
  }
  if (!isBelowObserverConquestQuota(ownOw)) {
    return const [];
  }
  if (!isStalledOldWorldExpansion(ownOw)) {
    return const [];
  }
  final ownPlayer = game.playerById(snapshot.playerId);
  if (ownPlayer == null) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) >
      kMutualExhaustedGpRegimentMax) {
    return const [];
  }
  if (ownPlayer.treasury > kMutualExhaustedGpTreasuryMax) {
    return const [];
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.length != 1) {
    return const [];
  }
  final enemy = gpWars.single;
  final enemyPlayer = game.playerById(enemy);
  if (enemyPlayer == null) {
    return const [];
  }
  final enemyOw = provinceCountOwnedBy(game, enemy);
  if (enemyOw < kMutualExhaustedGpStalemateMinOw) {
    return const [];
  }
  if (!isBelowObserverConquestQuota(enemyOw)) {
    return const [];
  }
  if (!isStalledOldWorldExpansion(enemyOw)) {
    return const [];
  }
  if ((enemyOw - ownOw).abs() > 1) {
    return const [];
  }
  if (regimentCountForPlayer(game, enemy) > kMutualExhaustedGpRegimentMax) {
    return const [];
  }
  if (enemyPlayer.treasury > kMutualExhaustedGpTreasuryMax) {
    return const [];
  }
  return [enemy];
}

/// When fighting 2+ Great Powers, peace every non-blocker GP; also peace a
/// sole non-blocker GP war while invadable OW remains (Refs #2509).
///
/// Canonical home (Refs #2509 S1) for `multiFrontNonBlockerGpPeaceTargets`.
List<String> multiFrontNonBlockerGpPeaceTargets({
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
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  var blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null) {
    var bestOw = 0;
    for (final factionId in gpWars) {
      final ow = provinceCountOwnedBy(game, factionId);
      if (ow > bestOw) {
        bestOw = ow;
        blocker = factionId;
      }
    }
  }
  if (blocker == null) {
    return const [];
  }
  if (gpWars.length == 1 && gpWars.single != blocker) {
    return gpWars;
  }
  if (gpWars.length <= 1) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic list of stronger at-war Great Power
/// factionIds the active player should `offerPeace` toward this turn
/// when OW holdings are critically low — the EXPAND-phase
/// critical-survival peace arm that peaces every stronger GP foe so
/// the active player can rebuild without losing the few OW provinces
/// it still holds.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `criticalWeakGpSurvivalPeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. Implements
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when OW
/// holdings are critically low (`<= kFewOldWorldProvincesDefendThreshold`)
/// peace every stronger at-war Great Power so a multi-front GP collapse
/// cannot eliminate the active player".
///
/// Returns `const []` for the outer guard:
///   * [ConquestSummary.oldWorldProvincesOwned] is strictly above
///     [kFewOldWorldProvincesDefendThreshold] (today: 6). Outside the
///     critical band the broader [criticalOwHoldPeaceTargets] and
///     band-specific deciders own the decision.
///
/// When the guard passes the function iterates [ThreatSummary.atWarWith]
/// and selects every Great Power foe (filtered via [Game.playerById])
/// whose own [provinceCountOwnedBy] satisfies the band-dependent
/// minimum-lead threshold:
///
///   * `ownOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1`
///     (today: 7 + 1 = 8) — default-start critical row: lead `>= 1`
///     is enough (any stronger GP is a critical risk while the player
///     is barely above the observer default start).
///   * Else `isBelowObserverConquestQuota(ownOw)` — below-quota critical
///     row: lead `>= kUnwinnableSoleGpMinProvinceDeficit` (today: 2) so
///     a slightly-stronger below-quota peer does not get peaced away
///     for free.
///   * Else (above-quota critical-band shape, defensive) —
///     lead `>= kDeclareWarAggressorSuppressWeakGpLeadThreshold`
///     (today: 4) so only clearly dominant peers are peaced.
///
/// Tribes and minors are dropped silently ([Game.playerById] returns
/// `null` for those ids); the returned list is sorted ascending by
/// `factionId` so the downstream survival aggregator
/// (`_survivalGreatPowerPeaceTargets`) and the legacy
/// `stalledOwExpansionNeedsPeacePass` consumer see a stable order
/// regardless of [ThreatSummary.atWarWith] iteration order (Refs #2509
/// Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` retains a thin delegating
/// stub for the legacy `diplomacy_planner_mutual_exhausted_peace_test.dart`
/// and `diplomacy_planner_stalled_peace_test.dart` fixtures and the
/// in-file `_survivalGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains so the planned
/// S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// (each at-war faction is inspected once with one [provinceCountOwnedBy]
/// scan); constant-time on every other arm. No global province / tile
/// scans introduced by the move, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
List<String> criticalWeakGpSurvivalPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.oldWorldProvincesOwned >
      kFewOldWorldProvincesDefendThreshold) {
    return const [];
  }
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  final minLead = ownOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1
      ? 1
      : isBelowObserverConquestQuota(ownOw)
      ? kUnwinnableSoleGpMinProvinceDeficit
      : kDeclareWarAggressorSuppressWeakGpLeadThreshold;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null &&
          provinceCountOwnedBy(game, factionId) >= ownOw + minLead)
        factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic list of non-blocker at-war Great Power
/// factionIds the active player should `offerPeace` toward this turn
/// when fighting two or more Great Powers and still inside the
/// EXPAND-band expansion pressure or at-quota band — the EXPAND-phase
/// critical multi-front peace arm that avoids total collapse from
/// simultaneous GP wars by dropping every non-blocker GP front.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `criticalMultiFrontGpPeaceTargets` peace decider previously hosted
/// in `diplomacy_planner_peace_targets.dart`. Composes the canonical
/// [multiFrontNonBlockerGpPeaceTargets] helper for the actual
/// non-blocker selection; this decider adds the EXPAND-band outer
/// guard and the 2+ GP-fronts precondition that distinguish the
/// critical multi-front signal from the general multi-front pivot.
///
/// Returns `const []` for any of the two outer guards:
///   1. Both [isObserverConquestExpansionPressure] and
///      [isAtObserverConquestQuotaBand] return `false` for the active
///      player's [ConquestSummary.oldWorldProvincesOwned] — outside the
///      EXPAND-band expansion pressure shape and the at-quota band the
///      critical multi-front pivot does not apply (the broader
///      quota-met deciders own the decision instead).
///   2. Fewer than two Great Powers remain in [ThreatSummary.atWarWith]
///      (after the [Game.playerById] filter) — the "multi-front"
///      precondition does not hold so the broader
///      [multiFrontNonBlockerGpPeaceTargets] sole-non-blocker arm and
///      the EXPAND default-start / near-quota collectors own the
///      single-GP cases.
///
/// When the guards pass the function delegates to
/// [multiFrontNonBlockerGpPeaceTargets] for the deterministic
/// non-blocker selection (primary OW frontier blocker is held open;
/// every other GP foe is peaced) sorted ascending by `factionId`
/// (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` retains a thin delegating
/// stub for the legacy `diplomacy_planner_below_quota_peace_part3_test.dart`
/// and `diplomacy_planner_stalled_peace_test.dart` fixtures and the
/// in-file `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains so the planned
/// S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// for the GP filter plus the delegated
/// [multiFrontNonBlockerGpPeaceTargets] body; no new global province /
/// tile scans introduced by the move, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
List<String> criticalMultiFrontGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isObserverConquestExpansionPressure(
        snapshot.conquest.oldWorldProvincesOwned,
      ) &&
      !isAtObserverConquestQuotaBand(
        snapshot.conquest.oldWorldProvincesOwned,
      )) {
    return const [];
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.length < 2) {
    return const [];
  }
  return multiFrontNonBlockerGpPeaceTargets(game: game, snapshot: snapshot);
}
