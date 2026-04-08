import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Debt rules for labour/economy techs (Money Lending, Banking).
///
/// SPEC/game/tech-tree-labour-economy.md

/// Maximum allowed debt (negative treasury) in ducats for a player based on
/// unlocked labour/economy techs.
///
/// A value of 0 means the player may not go below 0 treasury.
int maxDebtForPlayer(Player player) {
  final unlocked = player.techUnlocked ?? const <String, bool>{};
  // Money Lending: allow moderate research debt. Banking may extend this in a
  // future change.
  if (unlocked[kTechIdMoneyLending] == true) {
    return 500;
  }
  return 0;
}
