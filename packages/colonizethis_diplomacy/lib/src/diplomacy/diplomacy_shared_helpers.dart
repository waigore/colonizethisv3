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

/// Returns the first decision in [decisions] for which [matches] is true, or
/// null when [decisions] is null or no entry matches.
///
/// Generalises the per-resolver `_find*Decision` lookups (overture, FTP,
/// intervention, call-to-arms) into a single deterministic linear scan.
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
List<Player> debitPlayerTreasury(
  List<Player> players,
  int index,
  int amount,
) {
  if (amount <= 0 || index < 0 || index >= players.length) return players;
  final next = List<Player>.from(players);
  next[index] = next[index].copyWith(treasury: next[index].treasury - amount);
  return next;
}
