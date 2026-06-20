import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Debt rules for labour/economy techs (Money Lending, Banking).
///
/// SPEC/game/tech-tree-labour-economy.md

/// Maximum allowed debt (negative treasury) in ducats for a player based on
/// unlocked labour/economy techs.
///
/// A value of 0 means the player may not go below 0 treasury.
int maxDebtForPlayer(Player player) =>
    // Canonical debt floor lives in `colonizethis_data` (research_funding.dart)
    // so the resolver and Full-AI research planner share one rule. Refs #3472.
    researchMaxDebtForUnlocked(player.techUnlocked);
