// World-market trade / treasury threshold counters for S7-D rollup
// (Refs #2924 / #4079 Slice D). Mixed into [Seed42S7dCampaignRollup].
library;

/// Trade-order and regiment-threshold diagnostic counters.
mixin Seed42S7dCampaignRollupTradeCounters {
  List<String> get gpIds;


  // Refs #2924 Step 0 — world-market lock-recovery diagnostics:
  // per-GP rollups capturing (a) trade orders the AI submits each
  // turn (offer/bid counts plus urgent-priority offer counts at
  // [kTreasuryOfferPriorityUrgent]), (b) deals matched in the
  // world-market phase counted by seller/buyer GP plus treasury
  // credited/debited per side, and (c) whether/when the post-turn
  // treasury crosses [cheapestRegimentBuildTreasuryCost]. These
  // surfaces are issue-2924 specific and live alongside the
  // existing #2847 S7-D fields so a single run produces both
  // diagnostic blocks.
  late final tradeOfferCount = <String, int>{for (final gpId in gpIds) gpId: 0};
  late final tradeUrgentOfferCount = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final tradeBidCount = <String, int>{for (final gpId in gpIds) gpId: 0};
  late final dealsAsSeller = <String, int>{for (final gpId in gpIds) gpId: 0};
  late final dealsAsBuyer = <String, int>{for (final gpId in gpIds) gpId: 0};
  late final treasuryCredited = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final treasuryDebited = <String, int>{for (final gpId in gpIds) gpId: 0};
  late final regimentThresholdCrossingsUp = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final regimentThresholdFirstReachTurn = <String, int?>{
    for (final gpId in gpIds) gpId: null,
  };
  late final treasuryAtTurn99 = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Treasury immediately after the previous turn resolved (seeded
  // from turn-0 pre-resolution treasury so the first crossing
  // detection compares against game start rather than zero).
  late final treasuryPrevTurn = <String, int>{};
}
