/// Full-AI research-planning tunables for multi-slot fill and treasury-aware
/// balanced funding. SPEC/ai/ai-architecture.md § Research, SPEC/ai/
/// ai-parameter-registry.md. Refs #3472.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Funding floor applied per assigned slot when `primaryGoal == tech` and the
/// uniform balanced tier is affordable. SPEC/game/tech-tree.md funding presets.
const ResearchFundingLevel kResearchMinFundingWhenPrimaryGoalTech =
    ResearchFundingLevel.high;

/// Funding cap applied to every assigned slot when treasury is at or below 0.
const ResearchFundingLevel kResearchMaxFundingWhenBroke =
    ResearchFundingLevel.none;

/// Maximum number of **new** research-slot assignments the Full-AI planner makes
/// in a turn while the player has any active war. Applied after all other
/// slot-fill scaling (including the `primaryGoal == tech` fill-all path).
/// SPEC/ai/ai-architecture.md § Research planner (At-war cap). Refs #3472.
const int kResearchSlotFillCapWhenAtWar = 2;

/// Greedy-vs-category-diversified blend (0–100) for free research slots `>= 1`.
///
/// `0` disables diversification (pure greedy `era → cost → id`, the default for
/// human / simple-AI / tooling callers of `suggestResearchOrders`); `100` always
/// applies the highest-weight-unrepresented-bucket pick; intermediate values are
/// the per-slot probability (deterministic, keyed by `researchSeed + slotIndex`)
/// of taking the diversified pick instead of greedy-cheapest.
/// SPEC/program/order-suggestions.md § Research orders. Refs #3472.
const int kResearchCategoryDiversifyWeight = 40;
