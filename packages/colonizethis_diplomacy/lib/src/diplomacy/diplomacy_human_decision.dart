/// Identity and pending-human-decision helpers for diplomacy resolution
/// (Refs #4341). Extracted from [diplomacy_shared_helpers.dart] so the gated
/// SoT file can keep treasury debit and overture-clear helpers under the
/// existing checker-pinned path.
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

/// Routes a single human-gated diplomacy decision through the canonical
/// pending-human-decision flow documented on [findHumanDecision], removing the
/// duplicated branch tail from the overture, FTP, intervention, and
/// call-to-arms resolvers (Refs #3715).
///
/// Exactly one callback runs, synchronously, mirroring the prior hand-written
/// shape per resolver:
/// * [onAiResolve] when [isHumanControlled] is false — the AI decider resolves
///   by rule immediately;
/// * [onPending] when the decider is human but no supplied decision matches —
///   no human input yet, so the caller enqueues a pending prompt and stops
///   processing this decider;
/// * [onHumanDecision], with the first matching decision, when the decider is
///   human and a decision is present — the caller applies it.
///
/// The human-control branch is always evaluated **before** any decision lookup,
/// so [decisions] is only consulted for human deciders — preserving the
/// evaluation order each resolver relied on. Callers choose [isHumanControlled]
/// per their rule: the overture/FTP/intervention resolvers pass the result of
/// [isTargetHumanGp]; the call-to-arms resolver passes the override-aware
/// `!isAiControlled` so its AI-vs-human split still honours
/// `game.aiControlByGpId` exactly as before.
R resolveHumanGatedDecision<TDecision, R>({
  required bool isHumanControlled,
  required List<TDecision>? decisions,
  required bool Function(TDecision) matches,
  required R Function() onAiResolve,
  required R Function() onPending,
  required R Function(TDecision decision) onHumanDecision,
}) {
  if (!isHumanControlled) return onAiResolve();
  final decision = findHumanDecision<TDecision>(decisions, matches);
  if (decision == null) return onPending();
  return onHumanDecision(decision);
}
