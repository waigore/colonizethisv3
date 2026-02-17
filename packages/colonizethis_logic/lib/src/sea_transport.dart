import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Sea transport: allocate overseas extraction to stockpile by priority. SPEC/program/auto-transport.
///
/// Phase 2: cargo holds = fixed stub per player. Fill by priority until cap; rest left behind.

/// Default cargo holds per player when no ships (Phase 2 stub).
const int defaultCargoHoldsStub = 24;

/// Priority order for filling cargo: food, raw materials, riches, then manufactured/luxury/advanced.
final List<CommodityCategory> _seaPriorityOrder = [
  CommodityCategory.food,
  CommodityCategory.rawMaterial,
  CommodityCategory.riches,
  CommodityCategory.manufactured,
  CommodityCategory.luxury,
  CommodityCategory.advanced,
];

/// Allocates [overseasTotals] to delivered amounts, filling up to [cargoHolds] units total
/// by [priorityOrder] (default: food, raw, riches, manufactured, luxury, advanced).
/// Returns the map of commodity id → quantity to add to stockpile.
Map<CommodityId, int> allocateOverseasToStockpile(
  Map<CommodityId, int> overseasTotals, {
  int cargoHolds = defaultCargoHoldsStub,
  List<CommodityCategory>? priorityOrder,
}) {
  final order = priorityOrder ?? _seaPriorityOrder;
  final remaining = Map<CommodityId, int>.from(overseasTotals);
  var spaceLeft = cargoHolds;
  final delivered = <CommodityId, int>{};

  for (final category in order) {
    if (spaceLeft <= 0) break;
    for (final c in CommodityCatalog.all) {
      if (c.category != category) continue;
      final id = c.id;
      final available = remaining[id] ?? 0;
      if (available <= 0) continue;
      final take = available < spaceLeft ? available : spaceLeft;
      if (take <= 0) continue;
      delivered[id] = (delivered[id] ?? 0) + take;
      remaining[id] = available - take;
      spaceLeft -= take;
    }
  }

  return delivered;
}
