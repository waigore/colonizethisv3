// Shared treasury-planner constants (Refs #4079 Slice B).
// Extracted to break import cycles between treasury_planner.dart and its
// concern modules.

import 'expand_phase_planner_economy.dart' show cheapestRegimentBuildTreasuryCost;
import 'recipe_scoring.dart' show kShortageThreshold;

/// Bid priority tiers (1 = highest). Refs #2994 F4.
const int kTreasuryBidPriorityEssentialInput = 1;
const int kTreasuryBidPriorityLuxury = 2;
const int kTreasuryBidPriorityRawMaterial = 3;
const int kTreasuryBidPriorityFood = 4;

/// Default offer priority when treasury is comfortable.
const int kTreasuryOfferPriorityModerate = 5;

/// Aggressive sell priority when treasury is below the regiment threshold.
const int kTreasuryOfferPriorityUrgent = 2;

/// Multiplier on `cheapestRegimentBuildTreasuryCost()` that defines the
/// "affluent" treasury band where speculative bidding activates.
const int kTreasuryAffluenceThresholdMultiplier = 1;

/// Target stockpile quantity per non-riches commodity the affluent
/// speculative-bid pass tries to lift the GP toward when no F1–F5 deficit
/// already covers that commodity.
const int kSpeculativeBidStockpileTarget = kShortageThreshold;

/// Treasury band at which speculative bidding activates. Refs #2924 F10.
int treasuryAffluenceThreshold() =>
    kTreasuryAffluenceThresholdMultiplier * cheapestRegimentBuildTreasuryCost();
