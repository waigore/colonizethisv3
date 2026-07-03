import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';

/// Deterministic validator/panel rejection when a post-break bilateral cooldown
/// blocks overture-class diplomatic orders toward a Great Power.
/// SPEC/program/orders.md § Diplomatic orders / alliance-break cooldown.
const String kAllianceBreakCooldownRejectionReason =
    'On cooldown after breaking alliance — available next turn';

/// Returns whether a bilateral post-break cooldown is active for [factionA] and
/// [factionB] on [currentTurn] (active only when `sinceTurn == currentTurn`).
bool isAllianceBreakCooldownActive(
  Game game,
  String factionA,
  String factionB,
) {
  final turn = game.worldState.turnState.turnNumber;
  final key = pairKey(factionA, factionB);
  for (final cooldown in game.allianceBreakCooldowns) {
    if (pairKey(cooldown.factionId1, cooldown.factionId2) != key) continue;
    return cooldown.sinceTurn == turn;
  }
  return false;
}

/// Replaces any prior cooldown record for the pair with [sinceTurn].
List<AllianceBreakCooldownState> upsertAllianceBreakCooldown(
  List<AllianceBreakCooldownState> cooldowns,
  String factionA,
  String factionB,
  int sinceTurn,
) {
  final ids = canonicalPairIds(factionA, factionB);
  final key = pairKey(factionA, factionB);
  final kept = cooldowns
      .where((c) => pairKey(c.factionId1, c.factionId2) != key)
      .toList(growable: false);
  return [
    ...kept,
    AllianceBreakCooldownState(
      factionId1: ids.id1,
      factionId2: ids.id2,
      sinceTurn: sinceTurn,
    ),
  ];
}
