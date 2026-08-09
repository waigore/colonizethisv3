/// Cost tier == era bucket (1..4). Rebalanced so a slot at Medium funding
/// (300 RP/turn) completes a tier-1 tech in 6 turns and a tier-4 tech in 12.
/// SPEC/game/tech-tree.md § Research Model (Research point costs).
int techCatalogCostForTier(int tier) => 1800 + (tier - 1) * 600;
