part of 'expand_phase_planner.dart';

/// Returns the `factionId` of the strongest at-war Great Power (by OW
/// province lead over the active player) that owns invadable OW
/// provinces while this GP is stalled, excluding the primary OW
/// frontier blocker, or `null` when the stronger-blocker shortcut does
/// not apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledStrongerGpBlockerPeaceTarget` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. The decider
/// implements the EXPAND-phase "peace the stronger non-blocker GP that
/// owns invadable OW land while stalled with minors still on the map"
/// pivot so the planner can pivot off unwinnable GP fronts and chase
/// the minor frontier (seed-42 gp-blocker-focus shapes).
///
/// Returns `null` for any outer guard (in order):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned].
///   2. [ConquestSummary.invadableProvinceIdsSorted] is empty.
///   3. Neither `minorsOwnInvadable` nor [isStalledOldWorldGpBlockerFocus]
///      is true — no minor-on-frontier pivot and no GP-blocker-focus
///      band.
///   4. [isStalledOldWorldGpBlockerFocus] is true but no OW minor still
///      owns any province on the map (`anyMinorOwnsOw` is false) — the
///      stronger-blocker shortcut is suppressed when the minor pivot
///      is exhausted.
///
/// When the guards pass, scans [ThreatSummary.atWarWith] for Great
/// Powers (via [Game.playerById]) that own at least one invadable OW
/// province, skips [primaryInvadableOldWorldGpBlocker], and returns the
/// GP with the largest positive OW lead
/// (`provinceCountOwnedBy - oldWorldProvincesOwned`). Returns `null`
/// when no GP satisfies `lead > 0`.
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `diplomacy_planner_stalled_peace_test.dart`
/// fixtures and the in-file `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains until the
/// now-completed S1 deletion of that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7).
String? stalledStrongerGpBlockerPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
  );
  final gpBlockerFocus = isStalledOldWorldGpBlockerFocus(
    game: game,
    snapshot: snapshot,
  );
  if (!minorsOwnInvadable && !gpBlockerFocus) {
    return null;
  }
  if (gpBlockerFocus) {
    final anyMinorOwnsOw = _anyMinorOwnsOldWorldProvince(game);
    if (!anyMinorOwnsOw) {
      return null;
    }
  }
  final primaryBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  String? bestFactionId;
  var bestLead = 0;
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    if (factionId == primaryBlocker) continue;
    final ownsInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == factionId,
    );
    if (!ownsInvadable) continue;
    final lead =
        provinceCountOwnedBy(game, factionId) -
        snapshot.conquest.oldWorldProvincesOwned;
    if (lead <= 0) continue;
    if (lead > bestLead) {
      bestLead = lead;
      bestFactionId = factionId;
    }
  }
  return bestFactionId;
}

/// Returns the deterministic ascending-sorted list of at-war Great
/// Power `factionId`s to peace while a single GP owns the invadable OW
/// frontier (minors, tribes, and other GPs are distractions; Refs
/// #2509), or `const []` when the GP-blocker-focus pivot does not apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledGpBlockerFocusPeaceTargets` peace decider previously hosted
/// in `diplomacy_planner_peace_targets.dart`. The decider implements
/// the EXPAND-phase "peace every non-blocker GP war on a GP-only
/// invadable frontier" pivot (seed-42 gp4/gp5 vs gp3 blocker) plus the
/// mixed-frontier variant that still drops non-blocker GP wars when
/// minors own invadable land.
///
/// Returns `const []` when [isOldWorldGpOnlyInvadableFrontier] is
/// `false` — the invadable frontier is not GP-only so this collector
/// does not own the decision ([stalledFutileGpPeaceTargets] and
/// [stalledStrongerGpBlockerPeaceTarget] handle other shapes).
///
/// When the GP-only-frontier guard passes:
///   * Resolves [primaryInvadableOldWorldGpBlocker]; returns `const []`
///     when `null`.
///   * **Sole GP war on mixed frontier** (`minorsOwnInvadable` &&
///     `gpWars.length <= 1`): if exactly one GP is at war and it is not
///     the blocker, returns `[thatGp]` (drop the sole non-blocker front);
///     otherwise `const []`.
///   * **Mixed frontier with multiple GP wars** (`minorsOwnInvadable`):
///     peaces every GP in `gpWars` except the blocker, sorted ascending.
///   * **GP-only frontier**: peaces every at-war faction except the
///     blocker (includes minors/tribes in the scan — legacy behavior
///     preserved byte-for-byte), sorted ascending.
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `colonial_pressure_test.dart` §
/// `stalledGpBlockerFocusPeaceTargets` fixture and the in-file
/// `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains until the
/// now-completed S1 deletion of that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7).
List<String> stalledGpBlockerFocusPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
  );
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null) {
    return const [];
  }
  if (minorsOwnInvadable && gpWars.length <= 1) {
    // Sole GP war on a mixed frontier must still drop non-blocker fronts
    // (seed-42 gp4/gp5 vs gp3 blocker; Refs #2509).
    if (gpWars.length == 1 && gpWars.single != blocker) {
      return [gpWars.single];
    }
    return const [];
  }
  if (minorsOwnInvadable) {
    final targets = <String>[
      for (final factionId in gpWars)
        if (factionId != blocker) factionId,
    ]..sort();
    return targets;
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (factionId != blocker) factionId,
  ]..sort();
  return targets;
}

/// Returns `[blocker]` (single-element list) when the active player
/// should peace the primary OW frontier blocker because it is
/// critically weak and outmatched, or `const []` when this pivot does
/// not apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `weakHoldingsInvadableBlockerPeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. The decider
/// implements the EXPAND-phase "pivot to minors/tribes instead of
/// unwinnable GP wars when critically weak" pivot: when the active
/// player holds few OW provinces and the OW frontier blocker has a
/// large lead, peace the blocker so the planner can chase weaker
/// minor / tribe targets instead.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. The active player is **not** in a critical-weak band: above
///      [kFewOldWorldProvincesDefendThreshold], not below quota, and
///      not (zero regiments + stalled OW band) — none of the three
///      "critically weak" rows applies.
///   2. The invadable OW frontier is GP-only
///      ([isOldWorldGpOnlyInvadableFrontier] is `true`) — the
///      `stalledGpBlockerFocusPeaceTargets` collector owns the
///      decision instead.
///   3. [primaryInvadableOldWorldGpBlocker] is `null`, the blocker is
///      not in [ThreatSummary.atWarWith], or the blocker is not a
///      Great Power ([Game.playerById] returns `null`).
///   4. The blocker's OW lead falls below the band-dependent
///      `minLead` table:
///        * Below quota at default-start + 2 OW or fewer: `1`.
///        * Below quota above default-start + 2: `kUnwinnableSoleGpMinProvinceDeficit`.
///        * Above quota (defensive zero-regiment / stalled
///          critical-weak entry path): `kDeclareWarAggressorSuppressWeakGpLeadThreshold`.
///
/// When all guards pass, returns the single-element list `[blocker]`
/// — the planner peaces only the OW frontier blocker so the player
/// can pivot to minor / tribe wars without dropping every other GP
/// war.
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `diplomacy_planner_below_quota_peace_test.dart`
/// and `diplomacy_planner_below_quota_peace_part3_test.dart` fixtures
/// and the in-file `_expandRatchetGreatPowerPeaceTargets` /
/// `collectStalledGreatPowerPeaceTargets` `preserveBlockerPeace` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains until the
/// now-completed S1 deletion of that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] for the blocker membership check plus a
/// single [provinceCountOwnedBy] scan; matches the budget-rule note
/// in `colonizethis-turn-resolution-budget.mdc` (no global province /
/// tile scans introduced by the move).
List<String> weakHoldingsInvadableBlockerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final zeroRegiments = regimentCountForPlayer(game, snapshot.playerId) == 0;
  final belowQuota = isBelowObserverConquestQuota(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  if (snapshot.conquest.oldWorldProvincesOwned >
          kFewOldWorldProvincesDefendThreshold &&
      !belowQuota &&
      !(zeroRegiments &&
          isStalledOldWorldExpansion(
            snapshot.conquest.oldWorldProvincesOwned,
          ))) {
    return const [];
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null ||
      !snapshot.threats.atWarWith.contains(blocker) ||
      game.playerById(blocker) == null) {
    return const [];
  }
  final lead =
      provinceCountOwnedBy(game, blocker) -
      snapshot.conquest.oldWorldProvincesOwned;
  final minLead = belowQuota
      ? (snapshot.conquest.oldWorldProvincesOwned <=
                kObserverDefaultStartOldWorldProvincesPerGp + 2
            ? 1
            : kUnwinnableSoleGpMinProvinceDeficit)
      : kDeclareWarAggressorSuppressWeakGpLeadThreshold;
  if (lead < minLead) {
    return const [];
  }
  return [blocker];
}

/// Returns the deterministic ascending-sorted list of at-war minor and
/// tribe `factionId`s the active player should `offerPeace` toward in
/// EXPAND while stalled, dropping every "distraction" minor / tribe war
/// except the focused-minor target and the primary OW frontier GP
/// blocker, or `const []` when the distraction-peace pivot does not
/// apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledExpansionDistractionPeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. The decider
/// implements the EXPAND-phase "while stalled in OW expansion, peace
/// every at-war minor / tribe distraction front so the planner can
/// concentrate on the focused minor target and the primary OW frontier
/// GP blocker" pivot. The companion GP-blocker preservation
/// ([primaryInvadableOldWorldGpBlocker]) keeps a single GP war open
/// when [isStalledOldWorldGpBlockerFocus] applies — the focused-minor
/// preservation ([stalledFocusMinorTarget]) keeps a single minor war
/// open when an at-war minor still owns an invadable OW frontier
/// province.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — only the stalled
///      OW band routes through this distraction-peace decider.
///   2. [ThreatSummary.atWarWith] is empty — nothing to peace.
///   3. Neither `minorsOwnInvadable` (any invadable OW province is
///      owned by an OW minor) nor [isStalledOldWorldGpBlockerFocus]
///      is true — no minor-on-frontier pivot and no GP-blocker-focus
///      band so the distraction-peace pivot does not own the decision.
///
/// When the guards pass:
///   * `keepMinor` ← [stalledFocusMinorTarget] when an OW minor still
///     owns at least one invadable OW province (preserve the focused
///     minor war so the planner can finish that frontier); otherwise
///     `null`.
///   * `keepGp` ← [primaryInvadableOldWorldGpBlocker] when the GP-only
///     invadable-frontier band fires ([isStalledOldWorldGpBlockerFocus]
///     is true); otherwise `null`.
///   * Walks [ThreatSummary.atWarWith] in iteration order and keeps
///     every minor / tribe entry that is **not** `keepMinor`, **not**
///     `keepGp`, and is a minor or tribe per the locally-inlined
///     `factionIsMinorOrTribe` check (`Game.minorNations` /
///     `Game.tribes` membership). GPs are dropped because the
///     GP-blocker and peer-GP peace deciders own that decision.
///   * Sorts the result ascending so emission order is deterministic
///     for fixed inputs (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `diplomacy_planner_stalled_peace_test.dart`
/// fixture and the in-file `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains until the
/// now-completed S1 deletion of that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7). Linear in
/// [ConquestSummary.invadableProvinceIdsSorted] for the
/// `minorsOwnInvadable` scan plus a single pass over
/// [ThreatSummary.atWarWith]; matches the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc` (no global province /
/// tile scans introduced by the move).
List<String> stalledExpansionDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (snapshot.threats.atWarWith.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
  );
  final gpBlockerFocus = isStalledOldWorldGpBlockerFocus(
    game: game,
    snapshot: snapshot,
  );
  if (!minorsOwnInvadable && !gpBlockerFocus) {
    return const [];
  }
  final keepMinor = minorsOwnInvadable
      ? stalledFocusMinorTarget(game: game, snapshot: snapshot)
      : null;
  final keepGp = gpBlockerFocus
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (factionId != keepMinor &&
          factionId != keepGp &&
          (game.minorNations.any((m) => m.id == factionId) ||
              game.tribes.any((t) => t.id == factionId)))
        factionId,
  ]..sort();
  return targets;
}
