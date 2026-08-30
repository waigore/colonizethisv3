// Shared helpers for scalar predicate matrix cases (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_models/colonizethis_models.dart';

Stockpile expandPeaceMatrixRichesStockpile(String commodityId, int qty) =>
    qty <= 0 ? const Stockpile() : Stockpile().applyDelta(commodityId, qty);

({
  int quota,
  int floor,
  int cheapest,
  int goldPrice,
  int silverPrice,
  int spicesPrice,
})
expandPeaceScalarPredicateConstants() {
  const quota = kObserverConquestMinOwProvincesPerGp;
  const floor = kBelowQuotaPeaceMinRegimentsBeforeDeclareWar;
  final cheapest = cheapestRegimentBuildTreasuryCost();
  final goldPrice = richesBasePrice(CommodityCatalog.gold.id);
  final silverPrice = richesBasePrice(CommodityCatalog.silver.id);
  final spicesPrice = richesBasePrice(CommodityCatalog.spices.id);
  return (
    quota: quota,
    floor: floor,
    cheapest: cheapest,
    goldPrice: goldPrice,
    silverPrice: silverPrice,
    spicesPrice: spicesPrice,
  );
}
