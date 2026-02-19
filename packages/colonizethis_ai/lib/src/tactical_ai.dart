import 'dart:math' as math;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'ai_config.dart';

/// Tactical (Quick Battle) decisions for full AI. SPEC/program/ai-systems-impl.md.
///
/// Returns CP-based actions for one round for the AI side. Deterministic given [input] and [tacticalSeed].
QuickBattleRoundActions decideQuickBattleActions({
  required QuickBattleInput input,
  required String nationId,
  required AIConfig config,
  required int tacticalSeed,
}) {
  final rng = math.Random(tacticalSeed);
  // Simple heuristic: choose from a few strategies (1–2 CP total).
  final strategies = [
    [QuickBattleAction.volleyFire],
    [QuickBattleAction.defendEntrench],
    [QuickBattleAction.volleyFire, QuickBattleAction.maneuver],
    [QuickBattleAction.assaultCharge],
  ];
  final idx = rng.nextInt(strategies.length);
  return QuickBattleRoundActions(actions: strategies[idx]);
}
