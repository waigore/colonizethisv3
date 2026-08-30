/// Per-turn food consumption phases used by [resolveConsumption].
///
/// Each phase is a pure, stockpile-in/stockpile-out function so the land
/// military, navy, and worker stages can be unit-tested in isolation.
/// SPEC/game/workers-and-population.md
/// SPEC/game/stockpiles-and-production.md
library;

export 'economy_consumption_food_units.dart';
export 'economy_consumption_fully_fed.dart';
export 'economy_consumption_military.dart';
export 'economy_consumption_navy.dart';
export 'economy_consumption_unknown_ship.dart';
export 'economy_consumption_workers.dart';
export 'economy_worker_consumption_rates.dart';
