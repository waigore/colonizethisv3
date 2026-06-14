import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'conflict_detection.dart';

/// Base treasury cost per land battle for each Great Power attacker side.
/// Reduced by military tech modifiers. SPEC/game/tech-tree-military.md.
const int kLandBattleAttackTreasuryCostBase = 100;

/// Multiplier (0–1] applied to [kLandBattleAttackTreasuryCostBase] for [player].
double militaryAttackTreasuryCostMultiplier(Player player) {
  final u = player.techUnlocked ?? const <String, bool>{};
  var m = 1.0;
  if (u[kTechIdIndustrialMachinery] == true) {
    m *= 0.75;
  }
  if (u[kTechIdModernMilitaryFunding] == true) {
    m *= 0.85;
  }
  return m;
}

int landBattleAttackTreasuryCostForPlayer(Player player) {
  final raw =
      kLandBattleAttackTreasuryCostBase *
      militaryAttackTreasuryCostMultiplier(player);
  return math.max(0, raw.ceil());
}

/// Deducts attack treasury costs from each Great Power attacker in [ctx].
Game applyLandBattleAttackTreasuryCosts(Game game, BattleContext ctx) {
  final ids = <String>{for (final a in ctx.attackers) a.factionId};
  var players = game.players;
  final factionMembership = DiplomacyFactionMembership.from(game);
  // O(1) player row lookup per attacker instead of O(P) indexWhere each time.
  // First index wins for duplicate ids (matches [List.indexWhere]) — Refs #2394.
  final playerIndexById = <String, int>{};
  for (var i = 0; i < players.length; i++) {
    playerIndexById.putIfAbsent(players[i].id, () => i);
  }
  for (final id in ids) {
    if (!isGreatPower(game, id, factionMembership: factionMembership)) continue;
    final p = game.playerById(id);
    if (p == null) continue;
    final cost = landBattleAttackTreasuryCostForPlayer(p);
    if (cost <= 0) continue;
    final idx = playerIndexById[id];
    if (idx == null) continue;
    final nextTreasury = math.max(0, players[idx].treasury - cost);
    // Keep (copy-disposition, Refs #3448 AC5): copy-on-write to isolate the
    // caller-owned players list before the single-index treasury update; not a
    // ship/unit clone, so it is intentionally outside copyNavalShips(...).
    players = List<Player>.from(players);
    players[idx] = players[idx].copyWith(treasury: nextTreasury);
  }
  return game.withPlayers(players);
}
