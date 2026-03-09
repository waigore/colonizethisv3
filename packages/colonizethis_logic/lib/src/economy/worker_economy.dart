import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Worker economy primitives (labour and luxuries).
/// SPEC/program/economy-models.md, SPEC/game/workers-and-population.md.
///
/// Public for use by AI economy planner and production/consumption pipelines.

/// Computes effective available labour for production, capped by luxury
/// availability per SPEC/program/economy-models.md and
/// SPEC/game/workers-and-population.md.
int effectiveLabourForWorkers({
  required WorkerPool workers,
  required Stockpile stockpile,
}) {
  final peasantsLabour = workers.peasants * 1;

  final refinedSugar = stockpile.quantityOf(CommodityCatalog.refinedSugar.id);
  final cigars = stockpile.quantityOf(CommodityCatalog.cigars.id);
  final furHats = stockpile.quantityOf(CommodityCatalog.furHats.id);

  final apprenticesWithLuxury = workers.apprentices <= 0
      ? 0
      : (refinedSugar < workers.apprentices ? refinedSugar : workers.apprentices);
  final journeymenWithLuxury = workers.journeymen <= 0
      ? 0
      : (cigars < workers.journeymen ? cigars : workers.journeymen);
  final mastersWithLuxury = workers.masters <= 0
      ? 0
      : (furHats < workers.masters ? furHats : workers.masters);

  return peasantsLabour +
      apprenticesWithLuxury * 4 +
      journeymenWithLuxury * 6 +
      mastersWithLuxury * 8;
}

