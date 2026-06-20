/// Shared faction-membership predicates for AI planning code (Refs #2509
/// duplication cleanup).
///
/// Several planning and scoring modules previously held private copies of
/// the same predicate — checking whether a faction id belongs to a
/// [Game.minorNations] entry, a [Game.tribes] entry, or either. The
/// duplicates drifted over time (one site missed the `tribes` arm; another
/// inlined the same `any(...)` pair against `targetFactionId`). The
/// helpers below give callers one canonical implementation:
///
///   - [isMinorFaction] — the faction id matches a [MinorNation.id].
///   - [isTribeFaction] — the faction id matches a [Tribe.id].
///   - [isMinorOrTribeFaction] — the faction id matches either roster.
///
/// All three are pure, deterministic functions over [Game] state and
/// perform no logging or I/O. They are linear scans of the matching
/// roster: minor-nation and tribe lists are small (a handful of entries
/// per region) so the linear scan dominates over any allocation cost a
/// per-call `Set` lookup would incur and keeps the helpers safe to call
/// from hot scoring paths. Determinism is preserved trivially because
/// the underlying rosters are deterministic for a given [Game].
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Returns `true` when [factionId] matches any entry in
/// [Game.minorNations].
bool isMinorFaction(Game game, String factionId) =>
    game.minorNations.any((m) => m.id == factionId);

/// Returns `true` when [factionId] matches any entry in [Game.tribes].
bool isTribeFaction(Game game, String factionId) =>
    game.tribes.any((t) => t.id == factionId);

/// Returns `true` when [factionId] matches any entry in either
/// [Game.minorNations] or [Game.tribes].
///
/// Canonical replacement (Refs #2509) for the previously duplicated
/// private predicates in `conquest_planner.dart`,
/// `diplomatic_candidate_scoring.dart`, and the inline pair-of-`any`
/// pattern in `war_desire_calculator.dart`.
bool isMinorOrTribeFaction(Game game, String factionId) =>
    isMinorFaction(game, factionId) || isTribeFaction(game, factionId);
