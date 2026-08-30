/// EXPAND declare-war peer-war peace cooldown (Refs #4079 / #2847 § H2; #4365).
library;

import 'planning_imports.dart';
import 'planning_helpers.dart' show hasRecentDiplomaticEventWithinCooldown;

/// Peer-war peace cooldown turns used by [expandRecentlyPeacedWithGreatPower]
/// and [planExpandDeclareWar] arm 3 (Refs #2847 § H2).
const int kExpandPeerWarPeaceCooldownTurns = 4;

/// Whether the active player and [peerGpId] completed a peace event within
/// the last [cooldownTurns] turns (Refs #2847 § H2).
bool expandRecentlyPeacedWithGreatPower({
  required Game game,
  required String activePlayerId,
  required String peerGpId,
  required int currentTurn,
  int cooldownTurns = kExpandPeerWarPeaceCooldownTurns,
}) {
  if (cooldownTurns <= 0) return false;
  return hasRecentDiplomaticEventWithinCooldown(
    game: game,
    currentTurn: currentTurn,
    cooldownTurns: cooldownTurns,
    matches: (event) =>
        event.type == DiplomaticEventType.peace &&
        event.participants.contains(activePlayerId) &&
        event.participants.contains(peerGpId),
  );
}
