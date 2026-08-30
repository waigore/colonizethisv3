import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Consumes up to [required] food units (grain then meat) from [stockpile].
/// Returns a record of (updatedStockpile, unitsConsumed).
(Stockpile, int) consumeFoodUnits({
  required Stockpile stockpile,
  required int required,
}) {
  var current = stockpile;
  var remaining = required;
  final grainId = CommodityCatalog.grain.id;
  final meatId = CommodityCatalog.meat.id;

  final grainAvailable = current.quantityOf(grainId);
  final meatAvailable = current.quantityOf(meatId);

  final grainToUse = remaining <= 0
      ? 0
      : remaining <= grainAvailable
      ? remaining
      : grainAvailable;
  if (grainToUse > 0) {
    current = current.applyDelta(grainId, -grainToUse);
    remaining -= grainToUse;
  }

  final meatToUse = remaining <= 0
      ? 0
      : remaining <= meatAvailable
      ? remaining
      : meatAvailable;
  if (meatToUse > 0) {
    current = current.applyDelta(meatId, -meatToUse);
    remaining -= meatToUse;
  }

  return (current, required - remaining);
}
