import 'package:colonizethis_models/colonizethis_models.dart';

/// Riches (commodities that convert to treasury) and their base prices.
/// SPEC/game/commodity-catalog.md (Riches and treasury).
/// Imperialism II 02-economy: spices $50/unit; others derived from scarcity.
///
/// Base price formula: spices fixed at 50; others = spicesBasePrice * (spicesSpawnWeight / spawnWeight).
/// Higher spawn weight = more common = lower price.

/// Spawn weight for spices (most common riches). Imperialism II: "lowest valued".
const int _spicesSpawnWeight = 10;

/// Base price for spices per unit (Imperialism II 02-economy).
const int spicesBasePrice = 50;

/// Spawn weights for riches (higher = more common). Keys match CommodityCatalog ids.
const Map<String, int> _richesSpawnWeights = {
  'spices': 10,
  'silver': 5,
  'gold': 3,
  'gems': 2,
  'diamonds': 1,
};

/// Commodity ids that convert to treasury in the riches-to-treasury phase (stable order).
const List<CommodityId> richesCommodityIds = [
  'spices',
  'silver',
  'gold',
  'gems',
  'diamonds',
];

/// Base price per unit for a riches commodity when cashing in.
/// Returns 0 for non-riches ids (callers can check [richesCommodityIds] first).
int richesBasePrice(CommodityId id) {
  final weight = _richesSpawnWeights[id];
  if (weight == null || weight <= 0) return 0;
  // basePrice = spicesBasePrice * (spicesSpawnWeight / weight), integer truncation
  return (spicesBasePrice * _spicesSpawnWeight / weight).truncate();
}

/// Default base price for non-riches commodities when used in Merchant purchase_land (15× this = tile cost).
/// SPEC/game/civilian-units.md. Riches use [richesBasePrice]; others use this default until ruleset config exists.
const int landPurchaseDefaultBasePrice = 10;

/// Base price per unit for a commodity when computing Merchant purchase_land cost (15 × base price).
/// Riches use [richesBasePrice]; non-riches return [landPurchaseDefaultBasePrice].
int landPurchaseBasePrice(CommodityId id) {
  final richesPrice = richesBasePrice(id);
  if (richesPrice > 0) return richesPrice;
  return landPurchaseDefaultBasePrice;
}
