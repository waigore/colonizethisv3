/// Great Power power-score helpers. SPEC/game/diplomacy.md § Great Power power
/// score; SPEC/game/victory.md § Calendar campaign end. Split out of
/// diplomacy_relation_lookup.dart to keep that core lookup file within the
/// domain-package source-file size budget (SPEC/program/repo-lint.md).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_combat/src/combat/military_strength.dart';

import 'diplomacy_relation_lookup.dart' show provinceCountOwnedBy;

/// Default weights for Great Power power score. SPEC/game/diplomacy.md § Great Power power score.
const int powerScoreProvinceWeight = 10;
const int powerScoreRegimentWeight = 1;
const int powerScoreShipWeight = 5;

/// Total number of ships (sum of shipTypeIds.length) over all fleets owned by [factionId].
int shipCountForFaction(Game game, String factionId) {
  var count = 0;
  for (final f in game.worldState.fleets) {
    if (f.ownerId == factionId) count += f.shipTypeIds.length;
  }
  return count;
}

/// Absolute power score for a Great Power. SPEC/game/diplomacy.md § Great Power power score.
/// Formula: provinceCount×W_province + round(regimentStrength)×W_regiment + shipCount×W_ship.
int greatPowerPowerScore(Game game, String factionId) {
  final provinces = provinceCountOwnedBy(game, factionId);
  final regimentStrength = aggregateMilitaryStrengthForPlayer(game, factionId);
  final ships = shipCountForFaction(game, factionId);
  return provinces * powerScoreProvinceWeight +
      regimentStrength.round() * powerScoreRegimentWeight +
      ships * powerScoreShipWeight;
}

/// Great Power with strictly highest [greatPowerPowerScore], or `null` when tied
/// or there are no players. SPEC/game/victory.md § Calendar campaign end.
String? pickUniqueGreatPowerLeaderByPowerScore(Game game) {
  if (game.players.isEmpty) return null;
  final scores = <String, int>{
    for (final p in game.players) p.id: greatPowerPowerScore(game, p.id),
  };
  var bestScore = -1;
  for (final s in scores.values) {
    if (s > bestScore) bestScore = s;
  }
  final leaders =
      scores.entries
          .where((e) => e.value == bestScore)
          .map((e) => e.key)
          .toList()
        ..sort();
  if (leaders.length != 1) return null;
  return leaders.single;
}
