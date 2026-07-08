/// Shared at-war peace collectors and GP-war presence helpers (Refs #3941).
///
/// Extracted from the former monolithic `planning_helpers.dart` so the file
/// stays under the 1000 non-comment-line gate while preserving the
/// `repo.ai_dedup_gp_wars_filter` canonical sites.
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import '../util/ai_validation_exception.dart';
import '../util/faction_query.dart';

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
  return _filterAtWarTargetsWhere(
    game: game,
    snapshot: snapshot,
    kind: _AtWarPeaceTargetKind.greatPower,
    keep: keep,
  );
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
  return _filterAtWarTargetsWhere(
    game: game,
    snapshot: snapshot,
    kind: _AtWarPeaceTargetKind.minorNation,
    keep: keep,
  );
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
  return _filterAtWarTargetsWhere(
    game: game,
    snapshot: snapshot,
    kind: _AtWarPeaceTargetKind.tribe,
    keep: keep,
  );
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
  return _filterAtWarTargetsWhere(
    game: game,
    snapshot: snapshot,
    kind: _AtWarPeaceTargetKind.nonGreatPower,
    keep: keep,
  );
}

enum _AtWarPeaceTargetKind {
  greatPower,
  minorNation,
  tribe,
  nonGreatPower,
}

List<String> _filterAtWarTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  required _AtWarPeaceTargetKind kind,
  bool Function(String factionId)? keep,
}) {
  switch (kind) {
    case _AtWarPeaceTargetKind.greatPower:
      final requiredKeep = keep;
      if (requiredKeep == null) {
        throw AiValidationException.value(
          keep,
          'keep',
          'Great-power at-war peace targets require a keep predicate.',
        );
      }
      return <String>[
        for (final factionId in gpFactionIdsAtWarWith(game, snapshot))
          if (requiredKeep(factionId)) factionId,
      ]..sort();
    case _AtWarPeaceTargetKind.minorNation:
      return <String>[
        for (final factionId in snapshot.threats.atWarWith)
          if (isMinorFaction(game, factionId) &&
              (keep == null || keep(factionId)))
            factionId,
      ]..sort();
    case _AtWarPeaceTargetKind.tribe:
      return <String>[
        for (final factionId in snapshot.threats.atWarWith)
          if (isTribeFaction(game, factionId) &&
              (keep == null || keep(factionId)))
            factionId,
      ]..sort();
    case _AtWarPeaceTargetKind.nonGreatPower:
      return <String>[
        for (final factionId in snapshot.threats.atWarWith)
          if (game.playerById(factionId) == null &&
              (keep == null || keep(factionId)))
            factionId,
      ]..sort();
  }
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
