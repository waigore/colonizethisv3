// Table-driven resolveConsumption scenarios (Refs #3856, #3939 slice 34).

import 'package:colonizethis_data/colonizethis_data.dart';
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
    stockpileDeltas: {
      CommodityCatalog.grain.id: 5,
      CommodityCatalog.meat.id: 0,
    },
    workers: const WorkerPool(peasants: 5),
    pins: (
      workerPool: WorkerPool(peasants: 5),
      idleLabour: WorkerIdleCounts(peasants: 5),
      grainRemaining: 0,
      meatRemaining: 0,
      combinedFoodRemaining: null,
      sugarRemaining: null,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
    ),
  ),
  resolveConsumptionScenario(
    label: 'trained tiers consume 2 food each',
    stockpileDeltas: {
      CommodityCatalog.grain.id: 4,
      CommodityCatalog.meat.id: 4,
      CommodityCatalog.refinedSugar.id: 2,
      CommodityCatalog.cigars.id: 1,
    },
    workers: const WorkerPool(
      peasants: 0,
      apprentices: 2,
      journeymen: 1,
      masters: 0,
    ),
    pins: (
      workerPool: WorkerPool(
        peasants: 0,
        apprentices: 2,
        journeymen: 1,
        masters: 0,
      ),
      idleLabour: null,
      grainRemaining: null,
      meatRemaining: null,
      combinedFoodRemaining: 2,
      sugarRemaining: null,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
    ),
  ),
  resolveConsumptionScenario(
    label: 'food strike: masters fed before peasants when food is tight',
    stockpileDeltas: {
      CommodityCatalog.grain.id: 2,
      CommodityCatalog.meat.id: 0,
      CommodityCatalog.furHats.id: 1,
    },
    workers: const WorkerPool(peasants: 5, masters: 1),
    pins: (
      workerPool: WorkerPool(peasants: 5, masters: 1),
      idleLabour: WorkerIdleCounts(masters: 1, peasants: 0),
      grainRemaining: 0,
      meatRemaining: null,
      combinedFoodRemaining: null,
      sugarRemaining: null,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
    ),
  ),
  resolveConsumptionScenario(
    label: 'food strike: journeymen fed before apprentices and peasants',
    stockpileDeltas: {
      CommodityCatalog.grain.id: 3,
      CommodityCatalog.meat.id: 0,
      CommodityCatalog.cigars.id: 1,
    },
    workers: const WorkerPool(
      peasants: 1,
      apprentices: 1,
      journeymen: 1,
      masters: 0,
    ),
    pins: (
      workerPool: WorkerPool(
        peasants: 1,
        apprentices: 1,
        journeymen: 1,
        masters: 0,
      ),
      idleLabour: WorkerIdleCounts(journeymen: 1, apprentices: 0, peasants: 0),
      grainRemaining: null,
      meatRemaining: null,
      combinedFoodRemaining: null,
      sugarRemaining: null,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
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
    pins: (
      workerPool: WorkerPool(
        peasants: 2,
        apprentices: 1,
        journeymen: 0,
        masters: 0,
      ),
      idleLabour: WorkerIdleCounts.zero,
      grainRemaining: null,
      meatRemaining: null,
      combinedFoodRemaining: null,
      sugarRemaining: null,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
    ),
  ),
  resolveConsumptionScenario(
    label: 'grain used before meat when both available',
    stockpileDeltas: {
      CommodityCatalog.grain.id: 2,
      CommodityCatalog.meat.id: 10,
      CommodityCatalog.refinedSugar.id: 2,
    },
    workers: const WorkerPool(
      peasants: 0,
      apprentices: 2,
      journeymen: 0,
      masters: 0,
    ),
    pins: (
      workerPool: null,
      idleLabour: WorkerIdleCounts(apprentices: 2),
      grainRemaining: 0,
      meatRemaining: 8,
      combinedFoodRemaining: null,
      sugarRemaining: null,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
    ),
  ),
  resolveConsumptionScenario(
    label: 'zero workers and zero military leaves stockpile unchanged',
    stockpileDeltas: {
      CommodityCatalog.grain.id: 5,
      CommodityCatalog.meat.id: 5,
    },
    workers: const WorkerPool(peasants: 0),
    pins: (
      workerPool: null,
      idleLabour: null,
      grainRemaining: 5,
      meatRemaining: 5,
      combinedFoodRemaining: null,
      sugarRemaining: null,
      cigarsRemaining: null,
      furHatsRemaining: null,
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
    pins: (
      workerPool: null,
      idleLabour: null,
      grainRemaining: null,
      meatRemaining: null,
      combinedFoodRemaining: null,
      sugarRemaining: null,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
    ),
  ),
  resolveConsumptionScenario(
    label:
        'resolveConsumption wires military→navy→workers strike order and counts',
    stockpileDeltas: {
      CommodityCatalog.grain.id: 8,
      CommodityCatalog.meat.id: 0,
    },
    workers: const WorkerPool(peasants: 5),
    militaryUnits: 2,
    shipCountsById: const {'carrack': 1},
    pins: (
      workerPool: WorkerPool(peasants: 5),
      idleLabour: WorkerIdleCounts(peasants: 2),
      grainRemaining: 0,
      meatRemaining: null,
      combinedFoodRemaining: null,
      sugarRemaining: null,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: 2,
      fullyFedRegiments: 2,
      totalShips: 1,
      fullyFedShips: 1,
    ),
  ),
  resolveConsumptionScenario(
    label:
        'luxury only for food-fed trained; no sugar deducted if apprentice on strike',
    stockpileDeltas: {
      CommodityCatalog.grain.id: 1,
      CommodityCatalog.meat.id: 0,
      CommodityCatalog.refinedSugar.id: 5,
    },
    workers: const WorkerPool(apprentices: 2, peasants: 0),
    pins: (
      workerPool: null,
      idleLabour: WorkerIdleCounts(apprentices: 0),
      grainRemaining: null,
      meatRemaining: null,
      combinedFoodRemaining: null,
      sugarRemaining: 5,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
    ),
  ),
  resolveConsumptionScenario(
    label: 'trained workers consume tier luxuries when food-fed',
    stockpileDeltas: {
      CommodityCatalog.grain.id: 10,
      CommodityCatalog.meat.id: 10,
      CommodityCatalog.refinedSugar.id: 2,
      CommodityCatalog.cigars.id: 1,
      CommodityCatalog.furHats.id: 1,
    },
    workers: const WorkerPool(
      peasants: 0,
      apprentices: 2,
      journeymen: 1,
      masters: 1,
    ),
    pins: (
      workerPool: null,
      idleLabour: WorkerIdleCounts(apprentices: 2, journeymen: 1, masters: 1),
      grainRemaining: null,
      meatRemaining: null,
      combinedFoodRemaining: null,
      sugarRemaining: 0,
      cigarsRemaining: 0,
      furHatsRemaining: 0,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
    ),
  ),
  resolveConsumptionScenario(
    label:
        'luxury strike: food-fed but short luxury → idle capped, partial deduction',
    stockpileDeltas: {
      CommodityCatalog.grain.id: 10,
      CommodityCatalog.meat.id: 10,
      CommodityCatalog.refinedSugar.id: 1,
    },
    workers: const WorkerPool(apprentices: 3, peasants: 0),
    pins: (
      workerPool: null,
      idleLabour: WorkerIdleCounts(apprentices: 1),
      grainRemaining: null,
      meatRemaining: null,
      combinedFoodRemaining: null,
      sugarRemaining: 0,
      cigarsRemaining: null,
      furHatsRemaining: null,
      totalRegiments: null,
      fullyFedRegiments: null,
      totalShips: null,
      fullyFedShips: null,
    ),
  ),
];
