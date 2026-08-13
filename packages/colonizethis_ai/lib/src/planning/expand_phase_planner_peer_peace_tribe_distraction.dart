/// EXPAND below-quota regiment-thin tribe distraction peace (Refs #3967; #4365).
library;

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'planning_helpers.dart'
    show isOwnOldWorldBelowConquestQuota, tribeAtWarPeaceTargetsWhere;
import 'planning_imports.dart';

/// Returns the deterministic ascending-sorted list of at-war tribe
/// `factionId`s the active player should `offerPeace` toward in EXPAND
/// while below the observer OW quota with a regiment count too small to
/// split across multiple fronts, or `const []` when the
/// distraction-peace pivot does not apply.
///
/// Tribe analogue of [belowQuotaMultiMinorDistractionPeaceTargets]
/// (Refs #2847 § H5). The minor decider concentrates a regiment-thin
/// below-quota GP on its focused OW minor by peacing every *other*
/// at-war minor; this decider drops the parallel *tribe* distraction
/// fronts the minor decider deliberately ignores (its guard keeps only
/// [Game.minorNations] members).
///
/// Distinct from [atWarGpDistractionTribePeaceTargets], which fires only
/// when an at-war Great Power front is present (the COLONIAL-phase
/// consolidation pivot). The seed-42 gp4 stall is a below-quota EXPAND
/// GP at peace with every Great Power yet diluted across several
/// simultaneous tribe wars, so the GP-front guard never admits it; this
/// decider supplies the missing below-quota tribe-distraction pivot.
///
/// **Old-World-conquest-value preservation:** only *pure distraction*
/// tribes are peaced — a tribe that owns **zero** Old World provinces
/// (`oldWorldProvinceCountOwnedBy(game, tribeId) == 0`). Such a tribe
/// offers no OW conquest value, so its war only drains the thin regiment
/// pool. A tribe that owns **any** OW province is kept at war: it is
/// either the immediately invadable frontier, a next-hop multi-turn
/// march target (Refs #2847 § H4-b minor-transit frontier march), or a
/// distant-but-real slow conquest the EXPAND ratchet would still
/// complete. Peacing it would forfeit OW gain. This keeps the pivot
/// surgical: it releases the regiment pool from value-less tribe fronts
/// (seed-42 gp4) while protecting the productive / en-route tribe wars
/// the EXPAND ratchet is winning (seed-42 gp3 / gp6 OW-tribe baselines).
///
/// Returns `const []` for any of the outer guards (in order), mirroring
/// [belowQuotaMultiMinorDistractionPeaceTargets]:
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned].
///   2. `regimentCount <= 0` — the zero-regiment survival deciders own
///      the peace decision below the affordability gate.
///   3. `regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
///      — a force able to project across multiple fronts can sustain
///      the tribe wars while it walks the EXPAND ratchet.
///   4. [ConquestSummary.invadableProvinceIdsSorted] is empty — no OW
///      frontier means no consolidation push to concentrate on.
///
/// When the guards pass it peaces every at-war tribe (membership tested
/// via [Game.tribes]) that owns zero Old World provinces
/// (`oldWorldProvinceCountOwnedBy(game, tribeId) == 0`), sorted ascending
/// for deterministic ordering.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// with one [oldWorldProvinceCountOwnedBy] lookup per at-war tribe
/// (itself bounded by the per-faction province index); no new global
/// province / tile scans introduced, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
List<String> belowQuotaRegimentThinTribeDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return const [];
  }
  final regimentCount = regimentCountForPlayer(game, snapshot.playerId);
  if (regimentCount <= 0 ||
      regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  // Route the at-war-tribe filter + ascending sort through the shared
  // [tribeAtWarPeaceTargetsWhere] collector (Refs #3717 expand-peace
  // scoring-skeleton dedup); only the zero-OW-province distraction exclusion
  // remains caller-specific. Byte-identical to the inline `isTribeFaction` +
  // zero-OW predicate + sort.
  return tribeAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) => oldWorldProvinceCountOwnedBy(game, factionId) == 0,
  );
}
