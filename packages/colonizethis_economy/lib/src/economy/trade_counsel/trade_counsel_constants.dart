/// Shared constants for trade counsel emission (neutral treasury path).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show cheapestRegimentBuildTreasuryCost;

import '../industry_counsel/industry_counsel_constants.dart'
    show kIndustryCounselShortageThreshold;

/// Bid priority tiers (1 = highest). Mirrors AI treasury planner F4.
const int kTradeCounselBidPriorityEssentialInput = 1;
const int kTradeCounselBidPriorityLuxury = 2;
const int kTradeCounselBidPriorityRawMaterial = 3;
const int kTradeCounselBidPriorityFood = 4;

/// Default offer priority when treasury is comfortable.
const int kTradeCounselOfferPriorityModerate = 5;

/// Aggressive sell priority when treasury forecast is below regiment threshold.
const int kTradeCounselOfferPriorityUrgent = 2;

const int kTradeCounselAffluenceThresholdMultiplier = 1;

const int kTradeCounselSpeculativeBidStockpileTarget =
    kIndustryCounselShortageThreshold;

int tradeCounselTreasuryAffluenceThreshold() =>
    kTradeCounselAffluenceThresholdMultiplier *
    cheapestRegimentBuildTreasuryCost();
