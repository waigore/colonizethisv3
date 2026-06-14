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
