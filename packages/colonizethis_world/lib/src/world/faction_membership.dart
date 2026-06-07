/// Faction classification helpers shared by world and diplomacy (Refs #3290 Phase 0).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// O(1) faction classification snapshot for diplomacy hot paths (Refs #2268 AC-6).
/// Rebuild when [Game.players], [Game.minorNations], or [Game.tribes] membership
/// changes in the same phase (for example Join Empire absorption).
final class DiplomacyFactionMembership {
  DiplomacyFactionMembership._(this.greatPowerIds, this.minorOrTribeIds);

  factory DiplomacyFactionMembership.from(Game game) {
    final gp = <String>{};
    for (final p in game.players) {
      gp.add(p.id);
    }
    final minorTribe = <String>{};
    for (final m in game.minorNations) {
      minorTribe.add(m.id);
    }
    for (final t in game.tribes) {
      minorTribe.add(t.id);
    }
    return DiplomacyFactionMembership._(gp, minorTribe);
  }

  final Set<String> greatPowerIds;
  final Set<String> minorOrTribeIds;

  bool isGreatPower(String factionId) => greatPowerIds.contains(factionId);

  bool isMinorOrTribe(String factionId) => minorOrTribeIds.contains(factionId);
}

bool isMinorOrTribe(
  Game game,
  String factionId, {
  DiplomacyFactionMembership? factionMembership,
}) {
  if (factionMembership != null) {
    return factionMembership.isMinorOrTribe(factionId);
  }
  return game.minorNations.any((m) => m.id == factionId) ||
      game.tribes.any((t) => t.id == factionId);
}

bool isGreatPower(
  Game game,
  String factionId, {
  DiplomacyFactionMembership? factionMembership,
}) {
  if (factionMembership != null) {
    return factionMembership.isGreatPower(factionId);
  }
  return game.players.any((p) => p.id == factionId);
}
