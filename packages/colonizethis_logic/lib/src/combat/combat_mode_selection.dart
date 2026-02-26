import 'package:colonizethis_models/colonizethis_models.dart';

import 'conflict_detection.dart';

/// Combat mode selection. SPEC/program/quick-battle-resolution.
///
/// Capital sieges always use Quick Battle. Otherwise use per-battle override or
/// game-settings default. Default Auto-Resolve.

/// Returns true if this battle is a siege of a Great Power capital.
/// Capital sieges must use Quick Battle (no auto-resolve).
bool isCapitalSiege(Game game, BattleContext ctx) {
  if (!ctx.isSiege) return false;
  for (final p in game.players) {
    if (p.capitalProvinceId == ctx.provinceId) return true;
  }
  return false;
}

/// Resolves combat mode for a battle. SPEC: capital sieges force Quick Battle;
/// else per-battle override or default. Key: provinceId (one battle per province).
CombatMode resolveCombatModeForBattle(
  Game game,
  BattleContext ctx, {
  CombatMode defaultMode = CombatMode.autoResolve,
  Map<String, CombatMode>? perBattleOverrides,
}) {
  if (isCapitalSiege(game, ctx)) return CombatMode.quickBattle;
  final override = perBattleOverrides?[ctx.provinceId];
  return override ?? defaultMode;
}
