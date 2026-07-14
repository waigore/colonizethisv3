// Thin contract for seed42 S7-D feedstock helper pin suite (Refs #3997 Phase 8).
// Case bodies live in sibling `*_cases.dart` modules.

import 'seed42_s7d_feedstock_afford_ownership_cases.dart';
import 'seed42_s7d_feedstock_labour_measure_cases.dart';
import 'seed42_s7d_feedstock_market_offer_cases.dart';

void main() {
  registerSeed42S7dFeedstockAffordOwnershipCases();
  registerSeed42S7dFeedstockLabourMeasureCases();
  registerSeed42S7dFeedstockMarketOfferCases();
}
