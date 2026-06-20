part of 'expand_phase_planner.dart';

// EXPAND-phase sole-GP / quota / critical-hold `offerPeace` target deciders,
// extracted from `expand_phase_planner.dart` for maintainability
// (Refs #3278 file-split). Behaviour-preserving move: same library scope
// (this is a `part of` the EXPAND planner library), so imports, shared
// helpers, and visibility are unchanged. The shared frontier predicates and
// the four `planExpand*` entry points remain in the parent library file.

/// Whether peacing a below-quota sole-GP war leaves the EXPAND-phase
/// player a pivot path back to active OW expansion (a remaining
/// uninvaded minor or a minor-owned invadable frontier province).
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `canPivotFromSoleGpWarAfterPeace` predicate previously hosted in
/// `colonial_pressure.dart`. Used by [unwinnableSoleGpFrontierPeaceTarget]
/// in `colonial_pressure.dart` to gate the "peace the lone GP foe when
/// clearly outgunned" decision — peacing is only worthwhile if the
/// active GP can immediately resume EXPAND against a minor rather than
/// idle while the lone GP rebuilds.
///
/// Returns `true` exactly when **any** of these hold:
///   1. The active player is at or above
///      [kObserverConquestMinOwProvincesPerGp] OW provinces (no longer
///      in EXPAND territory; the EXPAND-trap pivot guard is irrelevant
///      so we always allow peace).
///   2. A minor nation still owns at least one Old World province
///      anywhere on the map (the GP can attempt to formalize a new
///      minor war after peacing).
///   3. The active player's [ConquestSummary.invadableProvinceIdsSorted]
///      contains a province whose current owner is a minor nation (the
///      planner can immediately declare on that minor after peacing
///      the lone GP, since the invadable frontier already has a minor
///      pivot).
///
/// All three arms are short-circuited (`||` semantics): the function
/// returns on the first true arm without walking the remaining checks.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_can_pivot_from_sole_gp_war_branches_test.dart`
/// fixture and the existing `unwinnableSoleGpFrontierPeaceTarget` caller
/// within `colonial_pressure.dart` itself) so the now-completed S1 deletion of
/// that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in the smaller of
/// [WorldState.oldWorld] provinces (minors-on-map scan) and
/// [ConquestSummary.invadableProvinceIdsSorted] (minor-owned invadable
/// scan); short-circuited at the quota arm when above quota.
bool canPivotFromSoleGpWarAfterPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.oldWorldProvincesOwned >=
      kObserverConquestMinOwProvincesPerGp) {
    return true;
  }
  final minorsOnMap = _anyMinorOwnsOldWorldProvince(game);
  if (minorsOnMap) {
    return true;
  }
  return snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
    final owner = getProvinceOwnerMap(game)[pid];
    return owner != null && game.minorNations.any((m) => m.id == owner);
  });
}

/// Returns the lone Great Power foe's `factionId` when an EXPAND-phase
/// player should peace it as unwinnable, or `null` when the forced
/// sole-GP-frontier peace path does not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `unwinnableSoleGpFrontierPeaceTarget` peace decider previously hosted
/// in `colonial_pressure.dart`. The decider is the below-quota EXPAND
/// shortcut that surrenders an unwinnable sole-GP war so the planner
/// can pivot back to a minor frontier; it composes the already-canonical
/// helpers [soleAtWarGreatPowerId] and [canPivotFromSoleGpWarAfterPeace]
/// with the deficit-band table from `SPEC/ai/ai-architecture.md`
/// § Diplomacy targeting — "Forced offerPeace toward the sole at-war
/// Great Power...".
///
/// Returns `null` for any of the following short-circuits (in order):
///   1. [soleAtWarGreatPowerId] returns `null` — no sole GP foe (zero
///      GP wars after the [Game.playerById] filter, or two or more GP
///      wars). Multi-front peace selection (`nearQuotaHoldPeaceTargets`,
///      `belowQuotaPeerGpPeaceTargets`) owns the decision in that
///      shape, not this shortcut.
///   2. [isBelowObserverConquestQuota] is `false` for the active
///      player's [ConquestSummary.oldWorldProvincesOwned] — at or
///      above the observer OW quota the consolidate-gains decider
///      ([consolidateGainsSoleGpPeaceTarget]) and the quota-met
///      futile-peace collectors take over.
///   3. [canPivotFromSoleGpWarAfterPeace] is `false` — peacing the
///      lone GP would leave no SPEC-legal minor pivot, so the planner
///      must keep the war open and defer to the critical-weak survival
///      peace path instead.
///   4. The OW lead deficit `enemyOw - ownOw` is strictly less than the
///      band's `minDeficit`:
///        * `kUnwinnableSoleGpMinProvinceDeficit` (today: 2) on the
///          8–9 OW GP-only invadable frontier band — preserves
///          near-quota GP-only wars when the partner only narrowly
///          leads (lead 1) so the planner does not surrender the
///          near-peer blocker;
///        * `1` everywhere else (default-start band `own ≤
///          kObserverDefaultStartOldWorldProvincesPerGp`; 8–9 OW
///          non-GP-only band) — minimum +1 OW lead suffices.
///
/// When all four gates pass, returns the [soleAtWarGreatPowerId] result
/// (the sole GP foe).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `diplomacy_planner_peace_targets.dart` consumer chain
/// and the
/// `colonial_pressure_unwinnable_sole_gp_branches_test.dart` fixture)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in
/// [ConquestSummary.invadableProvinceIdsSorted] via the GP-only-frontier
/// composite; constant-time on all other arms (short-circuited by the
/// sole-GP and quota guards above the band table).
String? unwinnableSoleGpFrontierPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final enemy = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  if (enemy == null) {
    return null;
  }
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  if (!canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot)) {
    return null;
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  final enemyOw = provinceCountOwnedBy(game, enemy);
  final minDeficit = own <= kObserverDefaultStartOldWorldProvincesPerGp
      ? 1
      : own >= kObserverConquestMinOwProvincesPerGp - 2 &&
            !isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)
      ? 1
      : kUnwinnableSoleGpMinProvinceDeficit;
  if (enemyOw < own + minDeficit) {
    return null;
  }
  return enemy;
}

/// Returns the lone Great Power foe's `factionId` when a quota-met
/// EXPAND/COLONIAL player should peace it to lock in observer gains,
/// or `null` when the consolidate-gains shortcut does not apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `consolidateGainsSoleGpPeaceTarget` peace decider previously hosted
/// in `colonial_pressure.dart`. The decider is the quota-met companion
/// of [unwinnableSoleGpFrontierPeaceTarget]: once the active player has
/// secured a comfortable OW buffer above the observer quota and leads
/// the lone GP enemy by at least
/// [kConsolidateGainsSoleGpProvinceLead] OW provinces, peacing locks
/// the conquest gains in before a counter-offensive can erase them
/// (`SPEC/ai/ai-architecture.md` § Diplomacy targeting —
/// "when this GP holds at least
/// `kObserverConquestConsolidateMinOwProvinces` and leads the sole
/// enemy by `kConsolidateGainsSoleGpProvinceLead` or more (lock
/// observer gains before a counter-offensive)").
///
/// Returns `null` for any of the following short-circuits (in order):
///   1. [soleAtWarGreatPowerId] returns `null` — no sole GP foe (zero
///      or two-plus GP wars). The consolidate shortcut is sole-GP-only
///      so a multi-front context defers to the standard collectors.
///   2. [ConquestSummary.oldWorldProvincesOwned] is strictly below
///      [kObserverConquestConsolidateMinOwProvinces] — the active
///      player has not yet built the OW buffer SPEC requires before
///      locking in via peace (otherwise a marginal lead could be
///      reversed before the consolidate decision pays off).
///   3. The OW lead `own - enemyOw` is strictly below
///      [kConsolidateGainsSoleGpProvinceLead] — the consolidate
///      shortcut requires a clear lead, not just any positive gap.
///
/// When all three gates pass, returns the [soleAtWarGreatPowerId]
/// result (the sole GP foe).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the
/// `colonial_pressure_consolidate_gains_sole_gp_peace_branches_test.dart`
/// fixture and the
/// `diplomatic_candidate_scoring_offer_peace.dart` consumer chain) so
/// the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in the total province
/// count via [provinceCountOwnedBy] for the enemy lookup; otherwise
/// constant-time.
String? consolidateGainsSoleGpPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final enemy = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  if (enemy == null) {
    return null;
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  if (own < kObserverConquestConsolidateMinOwProvinces) {
    return null;
  }
  final enemyOw = provinceCountOwnedBy(game, enemy);
  if (own < enemyOw + kConsolidateGainsSoleGpProvinceLead) {
    return null;
  }
  return enemy;
}

/// Returns the deterministic list of at-war Great Powers the active
/// player should `offerPeace` toward this turn when below the observer
/// OW quota and a GP enemy leads by at least the band-selected minimum
/// province deficit.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledBelowQuotaGpLeadPeaceTargets` peace decider previously hosted
/// in `colonial_pressure.dart`. Implements the EXPAND-phase "peace the
/// leaders, hold the blocker" arm from
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — peace at-war
/// Great Powers that lead by [kUnwinnableSoleGpMinProvinceDeficit] (the
/// default-start band) or **1** (post-default band) OW provinces or
/// more while strictly below [kObserverConquestMinOwProvincesPerGp].
///
/// Contract:
///
///   1. **Quota guard.** When
///      [ConquestSummary.oldWorldProvincesOwned] is at or above
///      [kObserverConquestMinOwProvincesPerGp] return `const []` —
///      the caller falls through to quota-met deciders
///      ([quotaMetBelowQuotaAtWarPeaceTargets] / [consolidateGainsSoleGpPeaceTarget])
///      instead of the below-quota lead-peace family.
///   2. **Min-lead-deficit band.** With `own <=
///      kObserverDefaultStartOldWorldProvincesPerGp` the lead threshold
///      is [kUnwinnableSoleGpMinProvinceDeficit] (default-start row);
///      above default start (8–9 OW) the threshold relaxes to **1**
///      (post-default row).
///   3. **GP-only invadable blocker carve-out.** When
///      [isOldWorldGpOnlyInvadableFrontier] is true the
///      [primaryInvadableOldWorldGpBlocker] is excluded from the peace
///      list so the active player keeps fighting the canonical OW
///      frontier blocker even if it leads by the band-selected
///      deficit. Non-blocker GP enemies that still satisfy the
///      deficit remain in the list.
///   4. **At-war filter.** Tribes and minors in [ThreatSummary.atWarWith]
///      are skipped (`game.playerById(...) != null`); only GP factions
///      survive the filter.
///   5. **Lead filter.** Only GP factions whose
///      [provinceCountOwnedBy] is at least `own + minLeadDeficit`
///      survive the deficit gate.
///   6. **Sort determinism.** The returned list is sorted ascending
///      on `factionId` so the downstream offer-peace pass observes a
///      stable order regardless of `atWarWith` iteration order.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `colonial_pressure_stalled_below_quota_gp_lead_branches_test.dart`
/// fixture and the
/// `diplomatic_candidate_scoring_offer_peace.dart` / `diplomacy_planner.dart`
/// / `diplomacy_planner_peace_targets.dart` consumer chains) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] (each at-war faction is inspected once)
/// and in [ConquestSummary.invadableProvinceIdsSorted] via the
/// GP-only-frontier composite that gates the blocker carve-out.
List<String> stalledBelowQuotaGpLeadPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  final minLeadDeficit = own <= kObserverDefaultStartOldWorldProvincesPerGp
      ? kUnwinnableSoleGpMinProvinceDeficit
      : 1;
  final invadableBlocker =
      isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final targets = <String>[
    for (final factionId in gpFactionIdsAtWarWith(game, snapshot))
      if (factionId != invadableBlocker &&
          provinceCountOwnedBy(game, factionId) >= own + minLeadDeficit)
        factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic list of below-quota at-war Great Power
/// factionIds the active quota-met player should `offerPeace` toward this
/// turn — the "stop bullying below-quota peers" arm of the EXPAND-phase
/// peace family.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `quotaMetBelowQuotaAtWarPeaceTargets` peace decider previously hosted
/// in `colonial_pressure.dart`. The decider is the broadest quota-met
/// futile-war exit: once the active player has crossed the observer OW
/// quota ([kObserverConquestMinOwProvincesPerGp] today), every below-
/// quota Great Power still at war is offered peace so the planner stops
/// dragging on mop-up wars after the frontier is cleared
/// (`SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when this GP
/// already meets the observer quota and a below-quota Great Power at
/// war ... exit futile bullying wars; observer seed-42 gp4/gp3").
///
/// The companion [quotaMetFutileBelowQuotaGpPeaceTargets] narrows the
/// same family by also requiring the active player to still hold an
/// invadable OW frontier — used by the offer-peace scoring layer
/// (`diplomatic_candidate_scoring_offer_peace.dart`) so only the
/// narrower set carries the futile-bullying score bonus. The broader
/// helper here covers the post-cleanup state where no invadable OW
/// frontier remains and the planner just wants to release the residual
/// below-quota wars.
///
/// Returns `const []` for either of the outer guards:
///   1. [isBelowObserverConquestQuota] is `true` for the active player's
///      [ConquestSummary.oldWorldProvincesOwned] — quota-met peace
///      targets only fire after this GP has already crossed the
///      observer quota; below-quota GPs are still pressing war and
///      must defer to the EXPAND-phase peace deciders
///      ([defaultStartFutileMinorPeaceTargets],
///      [unwinnableSoleGpFrontierPeaceTarget], the in-file
///      `colonial_pressure` peace collectors that have not yet been
///      relocated).
///   2. [ThreatSummary.atWarWith] contains no Great Power below the
///      observer quota — the active player has only quota-met peers
///      (or no GP foes at all), so the consolidate-gains decider
///      ([consolidateGainsSoleGpPeaceTarget]) and the broader
///      multi-front peace collectors own the decision.
///
/// Per-enemy filters (each `continue`s without short-circuiting):
///   * Skip [ThreatSummary.atWarWith] entries that are not Great
///     Powers ([Game.playerById] returns `null`); minors and tribes
///     belong to the [defaultStartFutileMinorPeaceTargets] family.
///   * Skip Great Power enemies whose own
///     [provinceCountOwnedBy] is at or above the observer quota;
///     consolidate-gains owns those wars.
///
/// The returned list is sorted ascending by `factionId` so the
/// downstream offer-peace consumer (`diplomacy_planner_peace_targets.dart`,
/// `diplomatic_candidate_scoring_offer_peace.dart`) sees a stable
/// order regardless of the iteration order of
/// [ThreatSummary.atWarWith] (Refs #2509 Must-have #7).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the
/// `colonial_pressure_quota_met_below_quota_at_war_peace_branches_test.dart`
/// fixture and the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` consumer chain) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] × [provinceCountOwnedBy] (one full
/// province scan per at-war faction).
List<String> quotaMetBelowQuotaAtWarPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in gpFactionIdsAtWarWith(game, snapshot))
      if (isBelowObserverConquestQuota(provinceCountOwnedBy(game, factionId)))
        factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic list of at-war Great Powers the active
/// player should `offerPeace` toward this turn when OW holdings are
/// critically low (at or below [kFewOldWorldProvincesDefendThreshold])
/// and the player is still below the observer OW quota — the
/// EXPAND-phase critical-hold peace arm that peaces every GP war
/// regardless of frontier shape so the GP can rebuild without losing
/// the few OW provinces it still holds.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `criticalOwHoldPeaceTargets` peace decider previously hosted in
/// `colonial_pressure.dart`. Implements
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when OW
/// holdings are at or below `kFewOldWorldProvincesDefendThreshold` and
/// any OW minor remains (peace all GP wars)".
///
/// Contract:
///
///   1. **At-war filter.** [ThreatSummary.atWarWith] is filtered to
///      Great Power factions via [Game.playerById]; tribes and minors
///      are skipped. The returned list is sorted ascending on
///      `factionId` before any short-circuit so the empty-after-filter
///      branch and the firing branch share the same sort order.
///   2. **Empty-after-filter short-circuit.** When no GP factions
///      remain in the filtered list the function returns `const []`
///      immediately even if the OW critical band would otherwise fire.
///   3. **Own-OW critical band.** The peace list is emitted only when
///      [isBelowObserverConquestQuota] holds and
///      [ConquestSummary.oldWorldProvincesOwned] is at or below
///      [kFewOldWorldProvincesDefendThreshold]. Outside this band — at
///      or above the observer quota, or below the quota but strictly
///      above the defend threshold — the function returns `const []`.
///   4. **Below-quota AND-gate.** Both gates must hold: at-quota holdings
///      below the defend threshold still return `const []` because
///      `isBelowObserverConquestQuota` is `false` (defensive against a
///      future quota change that drops the quota below the defend
///      threshold).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `colonial_pressure_critical_ow_hold_branches_test.dart`
/// and `colonial_pressure_test.dart` fixtures and the
/// `diplomacy_planner.dart` / `diplomacy_planner_peace_targets.dart`
/// consumer chains) so the now-completed S1 deletion of that file leaves no
/// orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// (each at-war faction is inspected once); constant-time on every
/// other arm.
List<String> criticalOwHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  final targets = gpFactionIdsAtWarWith(game, snapshot);
  if (targets.isEmpty) {
    return const [];
  }
  if (isBelowObserverConquestQuota(ownOw) &&
      ownOw <= kFewOldWorldProvincesDefendThreshold) {
    return targets;
  }
  return const [];
}

/// Returns the deterministic list of below-quota at-war Great Power
/// factionIds the active quota-met player should `offerPeace` toward
/// this turn — the "stop bullying below-quota peers that are not
/// blocking my remaining OW frontier" arm of the EXPAND-phase peace
/// family.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `quotaMetFutileBelowQuotaGpPeaceTargets` peace decider previously
/// hosted in `colonial_pressure.dart`. The decider narrows the broader
/// [quotaMetBelowQuotaAtWarPeaceTargets] family by additionally requiring
/// the active player to still hold an invadable OW frontier and by
/// excluding any below-quota enemy GP that owns one of those invadable
/// OW provinces (peace there would forfeit the residual OW acquisition
/// path) plus the primary invadable OW blocker
/// ([primaryInvadableOldWorldGpBlocker]; defensive backstop). The
/// consumer (`diplomatic_candidate_scoring_offer_peace.dart`) applies a
/// stronger offer-peace score bonus to this narrower set so the
/// futile-bullying signal is concentrated on the truly off-frontier
/// below-quota peers (`SPEC/ai/ai-architecture.md` § Diplomacy
/// targeting — "when this GP already meets the observer quota and a
/// below-quota Great Power at war is not on the remaining invadable OW
/// frontier ... exit futile bullying wars").
///
/// Returns `const []` for any of the three outer guards:
///   1. [isBelowObserverConquestQuota] is `true` for the active
///      player's [ConquestSummary.oldWorldProvincesOwned] — quota-met
///      peace targets only fire after this GP has already crossed the
///      observer quota.
///   2. [ConquestSummary.invadableProvinceIdsSorted] is empty — without
///      a remaining invadable OW frontier the frontier-ownership
///      filter is meaningless and the broader
///      [quotaMetBelowQuotaAtWarPeaceTargets] / consolidate-gains
///      deciders take over.
///
/// Per-enemy filters (each `continue`s without short-circuiting):
///   * Skip [ThreatSummary.atWarWith] entries that are not Great
///     Powers ([Game.playerById] returns `null`); minors and tribes
///     belong to the [defaultStartFutileMinorPeaceTargets] family.
///   * Skip Great Power enemies whose own
///     [provinceCountOwnedBy] is at or above the observer quota;
///     consolidate-gains owns those wars.
///   * Skip Great Power enemies that own at least one province in
///     [ConquestSummary.invadableProvinceIdsSorted] (peace would
///     forfeit the residual OW acquisition path).
///   * Skip the primary invadable OW blocker
///     ([primaryInvadableOldWorldGpBlocker]) defensively — by
///     construction the blocker also satisfies the invadable-owning
///     filter above, so the equality skip is a backstop against a
///     future blocker-resolution refactor that could decouple blocker
///     identity from invadable ownership.
///
/// The returned list is sorted ascending by `factionId` so the
/// downstream offer-peace consumer
/// (`diplomatic_candidate_scoring_offer_peace.dart`) sees a stable
/// order regardless of the iteration order of
/// [ThreatSummary.atWarWith] (Refs #2509 Must-have #7).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the
/// `colonial_pressure_quota_met_futile_below_quota_gp_peace_branches_test.dart`
/// fixture, the `diplomacy_planner_stalled_peace_test.dart` sole
/// positive-case fixture, and the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` /
/// `diplomatic_candidate_scoring_offer_peace.dart` consumer chains)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] × ([provinceCountOwnedBy] +
/// [ConquestSummary.invadableProvinceIdsSorted]) for the per-enemy
/// frontier-ownership scan.
List<String> quotaMetFutileBelowQuotaGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  final targets = <String>[];
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    if (!isBelowObserverConquestQuota(provinceCountOwnedBy(game, factionId))) {
      continue;
    }
    final ownsInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == factionId,
    );
    if (ownsInvadable || factionId == blocker) continue;
    targets.add(factionId);
  }
  targets.sort();
  return targets;
}
