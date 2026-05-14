import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Riches-to-treasury phase: convert riches in stockpile to treasury at base price.
/// SPEC/program/turn-resolution-phases.md (Riches to treasury).
/// Imperialism II 02-economy, GDD 04.

/// Result of applying riches-to-treasury: updated stockpile and treasury delta.
class RichesToTreasuryResult {
  const RichesToTreasuryResult({
    required this.stockpile,
    required this.treasuryDelta,
  });

  final Stockpile stockpile;
  final int treasuryDelta;
}

/// Converts all riches in [stockpile] to treasury; returns updated stockpile and cash delta.
///
/// For each riches commodity, adds quantity × basePrice × [richesCashMultiplier] to treasury
/// (truncated to int), then removes that quantity from the stockpile.
/// [richesCashMultiplier] defaults to 1.0 (e.g. El Dorado scenario can use 1.5).
RichesToTreasuryResult resolveRichesToTreasury({
  required Stockpile stockpile,
  double richesCashMultiplier = 1.0,
}) {
  var updatedStockpile = stockpile;
  var totalCash = 0;

  for (final id in richesCommodityIds) {
    final qty = stockpile.quantityOf(id);
    if (qty <= 0) continue;

    final basePrice = richesBasePrice(id);
    if (basePrice <= 0) continue;

    final cash = (qty * basePrice * richesCashMultiplier).truncate();
    totalCash += cash;
    updatedStockpile = updatedStockpile.applyDelta(id, -qty);
  }

  logicLog.d(
    'riches-to-treasury treasuryDelta=$totalCash multiplier=$richesCashMultiplier',
  );
  return RichesToTreasuryResult(
    stockpile: updatedStockpile,
    treasuryDelta: totalCash,
  );
}
