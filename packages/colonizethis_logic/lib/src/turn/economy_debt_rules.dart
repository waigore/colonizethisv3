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
  // Money Lending: research spending may drive treasury negative up to this cap.
  // Banking extends the floor when the prerequisite chain includes Money Lending.
  // SPEC/game/tech-tree-labour-economy.md.
  if (unlocked[kTechIdMoneyLending] != true) {
    return 0;
  }
  if (unlocked[kTechIdBanking] == true) {
    return 1000;
  }
  return 500;
}
