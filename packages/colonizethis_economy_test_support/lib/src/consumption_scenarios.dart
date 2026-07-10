// Table-driven resolveConsumption scenarios (Refs #3856, #3939 slices 34 / 45).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'consumption_expectations.dart';

/// One row in a resolveConsumption scenario table.
class ConsumptionScenario {
  const ConsumptionScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  final String label;
  final void Function() run;
  final String? refs;
}

/// Runs [scenario] (setup + assertions live in [ConsumptionScenario.run]).
void runConsumptionScenario(ConsumptionScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [resolveConsumption].
List<ConsumptionScenario> resolveConsumptionScenarios() => [
  ..._resolveConsumptionWorkerFoodScenarios(),
  ..._resolveConsumptionMilitaryLuxuryScenarios(),
];

List<ConsumptionScenario> _resolveConsumptionWorkerFoodScenarios() => [
  resolveConsumptionScenario(
    label: 'peasants consume 1 food each (grain or meat)',
    stockpileDeltas: {'grain': 5, 'meat': 0},
    workers: const WorkerPool(peasants: 5),
    pins: ResolveConsumptionPins(
      workerPool: WorkerPool(peasants: 5),
      idleLabour: WorkerIdleCounts(peasants: 5),
      grainRemaining: 0,
      meatRemaining: 0,
    ),
  ),
  resolveConsumptionScenario(
    label: 'trained tiers consume 2 food each',
    stockpileDeltas: {'grain': 4, 'meat': 4, 'refinedSugar': 2, 'cigars': 1},
    workers: const WorkerPool(
      peasants: 0,
      apprentices: 2,
      journeymen: 1,
      masters: 0,
    ),
    pins: ResolveConsumptionPins(
      workerPool: WorkerPool(
        peasants: 0,
        apprentices: 2,
        journeymen: 1,
        masters: 0,
      ),
      combinedFoodRemaining: 2,
    ),
  ),
  resolveConsumptionScenario(
    label: 'food strike: masters fed before peasants when food is tight',
    stockpileDeltas: {'grain': 2, 'meat': 0, 'furHats': 1},
    workers: const WorkerPool(peasants: 5, masters: 1),
    pins: ResolveConsumptionPins(
      workerPool: WorkerPool(peasants: 5, masters: 1),
      idleLabour: WorkerIdleCounts(masters: 1, peasants: 0),
      grainRemaining: 0,
    ),
  ),
  resolveConsumptionScenario(
    label: 'food strike: journeymen fed before apprentices and peasants',
    stockpileDeltas: {'grain': 3, 'meat': 0, 'cigars': 1},
    workers: const WorkerPool(
      peasants: 1,
      apprentices: 1,
      journeymen: 1,
      masters: 0,
    ),
    pins: ResolveConsumptionPins(
      workerPool: WorkerPool(
        peasants: 1,
        apprentices: 1,
        journeymen: 1,
        masters: 0,
      ),
      idleLabour: WorkerIdleCounts(journeymen: 1, apprentices: 0, peasants: 0),
    ),
  ),
  resolveConsumptionScenario(
    label: 'food strike: pool unchanged when no food',
    stockpile: const Stockpile(),
    workers: const WorkerPool(
      peasants: 2,
      apprentices: 1,
      journeymen: 0,
      masters: 0,
    ),
    pins: ResolveConsumptionPins(
      workerPool: WorkerPool(
        peasants: 2,
        apprentices: 1,
        journeymen: 0,
        masters: 0,
      ),
      idleLabour: WorkerIdleCounts.zero,
    ),
  ),
  resolveConsumptionScenario(
    label: 'grain used before meat when both available',
    stockpileDeltas: {'grain': 2, 'meat': 10, 'refinedSugar': 2},
    workers: const WorkerPool(
      peasants: 0,
      apprentices: 2,
      journeymen: 0,
      masters: 0,
    ),
    pins: ResolveConsumptionPins(
      idleLabour: WorkerIdleCounts(apprentices: 2),
      grainRemaining: 0,
      meatRemaining: 8,
    ),
  ),
  resolveConsumptionScenario(
    label: 'zero workers and zero military leaves stockpile unchanged',
    stockpileDeltas: {'grain': 5, 'meat': 5},
    workers: const WorkerPool(peasants: 0),
    pins: const ResolveConsumptionPins(
      grainRemaining: 5,
      meatRemaining: 5,
      totalRegiments: 0,
      fullyFedRegiments: 0,
      totalShips: 0,
      fullyFedShips: 0,
    ),
  ),
];

List<ConsumptionScenario> _resolveConsumptionMilitaryLuxuryScenarios() => [
  resolveConsumptionScenario(
    label: 'unknown ship type id throws ConsumptionUnknownShipTypeException',
    stockpile: const Stockpile(),
    workers: const WorkerPool(peasants: 0),
    shipCountsById: const {'not_a_real_ship': 1},
    expectUnknownShipThrows: true,
    pins: const ResolveConsumptionPins(),
  ),
  resolveConsumptionScenario(
    label:
        'resolveConsumption wires military→navy→workers strike order and counts',
    stockpileDeltas: {'grain': 8, 'meat': 0},
    workers: const WorkerPool(peasants: 5),
    militaryUnits: 2,
    shipCountsById: const {'carrack': 1},
    pins: ResolveConsumptionPins(
      workerPool: WorkerPool(peasants: 5),
      idleLabour: WorkerIdleCounts(peasants: 2),
      grainRemaining: 0,
      totalRegiments: 2,
      fullyFedRegiments: 2,
      totalShips: 1,
      fullyFedShips: 1,
    ),
  ),
  resolveConsumptionScenario(
    label:
        'luxury only for food-fed trained; no sugar deducted if apprentice on strike',
    stockpileDeltas: {'grain': 1, 'meat': 0, 'refinedSugar': 5},
    workers: const WorkerPool(apprentices: 2, peasants: 0),
    pins: ResolveConsumptionPins(
      idleLabour: WorkerIdleCounts(apprentices: 0),
      sugarRemaining: 5,
    ),
  ),
  resolveConsumptionScenario(
    label: 'trained workers consume tier luxuries when food-fed',
    stockpileDeltas: {
      'grain': 10,
      'meat': 10,
      'refinedSugar': 2,
      'cigars': 1,
      'furHats': 1,
    },
    workers: const WorkerPool(
      peasants: 0,
      apprentices: 2,
      journeymen: 1,
      masters: 1,
    ),
    pins: ResolveConsumptionPins(
      idleLabour: WorkerIdleCounts(apprentices: 2, journeymen: 1, masters: 1),
      sugarRemaining: 0,
      cigarsRemaining: 0,
      furHatsRemaining: 0,
    ),
  ),
  resolveConsumptionScenario(
    label:
        'luxury strike: food-fed but short luxury → idle capped, partial deduction',
    stockpileDeltas: {'grain': 10, 'meat': 10, 'refinedSugar': 1},
    workers: const WorkerPool(apprentices: 3, peasants: 0),
    pins: ResolveConsumptionPins(
      idleLabour: WorkerIdleCounts(apprentices: 1),
      sugarRemaining: 0,
    ),
  ),
];
