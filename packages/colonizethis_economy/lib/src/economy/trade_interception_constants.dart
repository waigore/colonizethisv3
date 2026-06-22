/// Tuning constants for trade/transport interception during extraction
/// auto-transport.
///
/// Extracted from `trade_interception.dart` so the input-scan library and the
/// apply path share one source of truth without re-declaring tuning values
/// (Refs #3615 Cluster 4 file decomposition). Pure value declarations only —
/// no `Game` access, no logger, no RNG.
///
/// SPEC/program/naval-movement-resolution.md (P_cargo_intercept, P_ship_sunk);
/// SPEC/game/ships-and-naval.md § Trade and Transport Interception.
library;

/// Civilian target bonus for cargo interception. SPEC: 1.25–1.5.
const double civilianTargetBonus = 1.25;

/// Privateering doctrine bonus to trade/transport raid effectiveness.
///
/// Applied as a single multiplicative factor to the `interceptRating`
/// contribution of intercepting enemy fleets whose owner has
/// `privateering_companies` unlocked, before the `ratio`/`base` terms and the
/// documented cargo/ship clamps. Deterministic, no ruleset lookup.
/// SPEC/program/naval-movement-resolution.md § Trade/Transport Interception.
const double kPrivateeringTradeRaidBonus = 1.25;

/// Action factor for patrol (baseline).
const double actionFactorPatrol = 0.5;

/// Blockade bonus multiplier when interceptor has Blockade mission (vs Patrol).
const double blockadeBonusFactor = 1.5;

/// Escort protection: max loss reduction from strong escorts. SPEC: 50%.
const double escortFactorMax = 0.5;

/// Escort strength weight in loss reduction formula. SPEC: escortStrength/cargoStrength × 0.3.
const double escortStrengthWeight = 0.3;

/// Civilian ships twice as vulnerable to ship loss. SPEC: civilianPenalty = 2.0.
const double civilianShipLossPenalty = 2.0;

/// Raid efficiency range (min–max) for cargo loss. SPEC: 0.3 to 0.7 depending on relative strength.
const double raidEfficiencyMin = 0.3;
const double raidEfficiencyMax = 0.7;

/// Merchant ship type ids (civilian); others count as escort/warship.
/// SPEC/game/ships-and-naval.md.
const Set<String> kMerchantShipTypeIds = {'fluyte', 'carrack'};
