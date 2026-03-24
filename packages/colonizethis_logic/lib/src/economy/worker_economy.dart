import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Worker economy primitives (labour, food, and luxuries).
/// SPEC/program/economy-models.md, SPEC/game/workers-and-population.md.
///
/// Public for use by AI economy planner and production/consumption pipelines.

int effectiveLabourForWorkers({
  required WorkerPool workers,
  required Stockpile stockpile,
}) {
  final peasantsLabour =
      workers.peasants * WorkerPool.labourPerPeasantTurn;

  final refinedSugar = stockpile.quantityOf(CommodityCatalog.refinedSugar.id);
  final cigars = stockpile.quantityOf(CommodityCatalog.cigars.id);
  final furHats = stockpile.quantityOf(CommodityCatalog.furHats.id);

  final apprenticesWithLuxury = workers.apprentices <= 0
      ? 0
      : (refinedSugar < workers.apprentices
          ? refinedSugar
          : workers.apprentices);
  final journeymenWithLuxury = workers.journeymen <= 0
      ? 0
      : (cigars < workers.journeymen ? cigars : workers.journeymen);
  final mastersWithLuxury = workers.masters <= 0
      ? 0
      : (furHats < workers.masters ? furHats : workers.masters);

  return peasantsLabour +
      apprenticesWithLuxury * WorkerPool.labourPerApprenticeTurn +
      journeymenWithLuxury * WorkerPool.labourPerJourneymanTurn +
      mastersWithLuxury * WorkerPool.labourPerMasterTurn;
}

/// Consumes up to [required] food units (grain/meat) from [stockpile].
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

/// Applies tier luxury consumption for trained workers and returns the updated stockpile.
Stockpile deductLuxuryForWorkers({
  required Stockpile stockpile,
  required WorkerPool workers,
}) {
  var current = stockpile;

  int _deduct({
    required int workerCount,
    required CommodityId luxuryId,
  }) {
    if (workerCount <= 0) {
      return 0;
    }
    final available = current.quantityOf(luxuryId);
    if (available <= 0) {
      return 0;
    }
    final toUse = workerCount < available ? workerCount : available;
    if (toUse <= 0) {
      return 0;
    }
    current = current.applyDelta(luxuryId, -toUse);
    return toUse;
  }

  final refinedSugarId = CommodityCatalog.refinedSugar.id;
  final cigarsId = CommodityCatalog.cigars.id;
  final furHatsId = CommodityCatalog.furHats.id;

  _deduct(workerCount: workers.apprentices, luxuryId: refinedSugarId);
  _deduct(workerCount: workers.journeymen, luxuryId: cigarsId);
  _deduct(workerCount: workers.masters, luxuryId: furHatsId);

  return current;
}
