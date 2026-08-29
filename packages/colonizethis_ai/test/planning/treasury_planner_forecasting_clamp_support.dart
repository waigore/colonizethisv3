// Shared helpers for `treasury_planner_forecasting_clamp_*_cases.dart` (Refs #4669).

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Stockpile treasuryForecastingStockpileWellStockedExcept(
  Iterable<CommodityId> excluded,
) {
  final excludedSet = excluded.toSet();
  var stockpile = const Stockpile();
  for (final commodity in CommodityCatalog.all) {
    if (richesCommodityIds.contains(commodity.id)) continue;
    if (excludedSet.contains(commodity.id)) continue;
    stockpile = stockpile.applyDelta(
      commodity.id,
      kSpeculativeBidStockpileTarget * 4,
    );
  }
  return stockpile;
}
