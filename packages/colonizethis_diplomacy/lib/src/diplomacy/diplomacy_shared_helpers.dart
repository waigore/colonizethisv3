/// Shared diplomacy-resolution helpers extracted to eliminate copy-paste
/// duplication across the overture, FTP, intervention, call-to-arms, war, and
/// subsidy resolvers (Refs #3419). Behaviour-preserving consolidation only;
/// see SPEC/program/diplomacy-resolution.md and SPEC/game/diplomacy.md.
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// True when [factionId] resolves to a human-controlled faction in [game].
///
/// Used by the overture and FTP resolvers to decide whether an offer must be
/// surfaced to the player instead of resolved by AI rule.
bool isTargetHumanGp(Game game, String factionId) {
  final player = game.playerById(factionId);
  return player != null && player.isHuman;
}

/// Number of Great Powers [gpId] is currently at war with in [game].
///
/// Great-Power membership is determined via [factionMembership] (not by mere
/// player existence), giving a single authoritative count shared by the war
/// resolver and the call-to-arms flow.
int atWarGreatPowerCount(
  Game game,
  String gpId,
  DiplomacyFactionMembership factionMembership,
) {
  var count = 0;
  for (final rel in game.diplomacyRelations) {
    if (rel.state != RelationState.atWar) continue;
    if (rel.factionId1 != gpId && rel.factionId2 != gpId) continue;
    final other = rel.factionId1 == gpId ? rel.factionId2 : rel.factionId1;
    if (factionMembership.isGreatPower(other)) {
      count++;
    }
  }
  return count;
}

/// Builds a `key -> position` index over [items] using [keyOf].
///
/// Single canonical implementation for the per-resolver "build a `String key ->
/// int position` map from a `List<T>`" pattern (Refs #3562). On duplicate keys
/// the later entry wins, matching the previous inline builders which assigned
/// `out[key] = i` while iterating. O(n) single pass.
Map<String, int> indexByKey<T>(List<T> items, String Function(T) keyOf) {
  final out = <String, int>{};
  for (var i = 0; i < items.length; i++) {
    out[keyOf(items[i])] = i;
  }
  return out;
}

/// True if [playerId] is AI-controlled (evidence/dialogue/event metadata only
/// applies to AI subjects).
///
/// Lives in the diplomacy shared helpers — not the dossier evidence layer — so
/// diplomacy resolvers can read the AI-control flag without importing from
/// `../dossier/` (Refs #3562). Named to avoid an export clash with
/// `ai_planner.isAiControlled`. An explicit `aiControlByGpId` override wins;
/// otherwise a non-human player is treated as AI-controlled.
bool isAiControlledForEvidence(Game game, String playerId) {
  final explicit = game.aiControlByGpId[playerId];
  if (explicit != null) return explicit;
  final p = game.playerById(playerId);
  return p != null && !p.isHuman;
}

/// Removes overtures between [gpId] and [factionId] from [game].
///
/// Canonical replacement for the per-resolver inline overture-clearing filter
/// blocks (Refs #3562). By default only the directional overture
/// (`gpId -> factionId`) is cleared, matching the do-nothing intervention path.
/// When [bidirectional] is true the reverse overture (`factionId -> gpId`) is
/// also cleared, matching war-termination clearing.
///
/// Returns the (possibly unchanged) game alongside the overtures that were
/// removed, in their original `game.overtureStates` order. When nothing matches
/// the original [game] instance is returned with an empty `removed` list, so
/// callers can cheaply skip follow-up work (event logging, copy churn). Callers
/// that log per-removed overture should consume `removed` instead of re-deriving
/// the diff.
///
/// Note: this clears a single GP↔faction pair. Full faction teardown (removing
/// every overture that involves an absorbed faction, regardless of counterpart)
/// is a distinct single-faction operation and is intentionally not expressed
/// through this pair-scoped helper.
({Game game, List<OvertureState> removed}) clearOverturesBetweenGpAndFaction(
  Game game,
  String gpId,
  String factionId, {
  bool bidirectional = false,
}) {
  final removed = <OvertureState>[];
  final kept = <OvertureState>[];
  for (final o in game.overtureStates) {
    final directional = o.gpId == gpId && o.targetId == factionId;
    final reverse = bidirectional && o.gpId == factionId && o.targetId == gpId;
    if (directional || reverse) {
      removed.add(o);
    } else {
      kept.add(o);
    }
  }
  if (removed.isEmpty) return (game: game, removed: const <OvertureState>[]);
  return (game: game.copyWith(overtureStates: kept), removed: removed);
}

/// Returns the first decision in [decisions] for which [matches] is true, or
/// null when [decisions] is null or no entry matches.
///
/// Generalises the per-resolver `_find*Decision` lookups (overture, FTP,
/// intervention, call-to-arms) into a single deterministic linear scan.
///
/// ## Canonical pending-human-decision flow (Refs #3562 AC3)
///
/// The overture, FTP, intervention, and call-to-arms resolvers each gate a
/// human-controlled counterpart on a supplied decision using one identical
/// control-flow shape, expressed with the two shared helpers below
/// ([isTargetHumanGp] and [findHumanDecision]) and no per-resolver re-invention:
///
/// ```text
/// final humanControlled = isTargetHumanGp(game, deciderId);
/// if (humanControlled) {
///   final decision = findHumanDecision<T>(decisions, matches);
///   if (decision == null) {
///     // no human input yet -> enqueue a pending prompt and stop processing
///     // this decider so the phase can suspend turn resolution
///   } else {
///     // human input present -> apply the decision
///   }
/// } else {
///   // AI-controlled decider -> resolve by rule immediately
/// }
/// ```
///
/// The human-control branch is always evaluated before any decision lookup, so
/// decisions are only consulted for human deciders. Call-to-arms intentionally
/// substitutes the override-aware `isAiControlled` (negated) for
/// [isTargetHumanGp] so its AI-vs-human split honours `game.aiControlByGpId`
/// exactly as before; the rest of the shape is identical.
T? findHumanDecision<T>(List<T>? decisions, bool Function(T) matches) {
  if (decisions == null) return null;
  for (final decision in decisions) {
    if (matches(decision)) return decision;
  }
  return null;
}

/// Returns a new player list with the player at [index] debited [amount] from
/// its treasury.
///
/// Returns [players] unchanged when [index] is out of range or [amount] is not
/// positive, so callers can pass an unresolved index (`-1`) safely. When a
/// debit is applied the returned list is a fresh copy, preserving the original.
List<Player> debitPlayerTreasury(List<Player> players, int index, int amount) {
  if (amount <= 0 || index < 0 || index >= players.length) return players;
  final next = List<Player>.from(players);
  next[index] = next[index].copyWith(treasury: next[index].treasury - amount);
  return next;
}
