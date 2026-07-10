// Table-driven economy extraction scenarios (Refs #3939 phase 3 slice 34).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'core_economy_test_support.dart';
import 'economy_extraction_expectations.dart';
import 'scenario_runner.dart';

/// One row in [applyExtractionToStockpileScenarios].
class ApplyExtractionToStockpileScenario implements RefsScenario {
  const ApplyExtractionToStockpileScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runApplyExtractionToStockpileScenario(
  ApplyExtractionToStockpileScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [applyExtractionToStockpile].
List<ApplyExtractionToStockpileScenario> applyExtractionToStockpileScenarios() =>
    [
      applyExtractionToStockpileScenario(
        label: 'adds extracted quantities to stockpile',
        extracted: {
          CommodityCatalog.grain.id: 5,
          CommodityCatalog.iron.id: 2,
        },
        expectedQuantities: {
          CommodityCatalog.grain.id: 5,
          CommodityCatalog.iron.id: 2,
        },
      ),
      applyExtractionToStockpileScenario(
        label: 'accumulates on existing stockpile',
        initialDeltas: {
          CommodityCatalog.grain.id: 3,
          CommodityCatalog.meat.id: 1,
        },
        extracted: {
          CommodityCatalog.grain.id: 4,
          CommodityCatalog.meat.id: 2,
        },
        expectedQuantities: {
          CommodityCatalog.grain.id: 7,
          CommodityCatalog.meat.id: 3,
        },
      ),
      applyExtractionToStockpileScenario(
        label: 'ignores negative values in extracted',
        initialDeltas: {CommodityCatalog.grain.id: 10},
        extracted: {
          CommodityCatalog.grain.id: -2,
          CommodityCatalog.meat.id: 3,
        },
        expectedQuantities: {
          CommodityCatalog.grain.id: 10,
          CommodityCatalog.meat.id: 3,
        },
      ),
      applyExtractionToStockpileScenario(
        label: 'zero quantities do not change stockpile',
        initialDeltas: {CommodityCatalog.grain.id: 5},
        extracted: {
          CommodityCatalog.grain.id: 0,
          CommodityCatalog.iron.id: 0,
        },
        expectedQuantities: {CommodityCatalog.grain.id: 5},
      ),
      applyExtractionToStockpileScenario(
        label: 'empty extracted returns same stockpile',
        initialDeltas: {CommodityCatalog.grain.id: 5},
        extracted: const {},
        expectedQuantities: {CommodityCatalog.grain.id: 5},
      ),
      applyExtractionToStockpileScenario(
        label:
            'adds large extraction without storage cap (unbounded strategic stockpile)',
        initialDeltas: {CommodityCatalog.grain.id: 1000000},
        extracted: {CommodityCatalog.grain.id: 500000},
        expectedQuantities: {CommodityCatalog.grain.id: 1500000},
      ),
    ];

/// One row in [applyExtractionForPlayersScenarios].
class ApplyExtractionForPlayersScenario implements RefsScenario {
  const ApplyExtractionForPlayersScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runApplyExtractionForPlayersScenario(
  ApplyExtractionForPlayersScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [applyExtractionForPlayers].
List<ApplyExtractionForPlayersScenario> applyExtractionForPlayersScenarios() =>
    [
      applyExtractionForPlayersScenario(
        label: 'applies per-player extraction to player stockpiles',
        game: minimalTwoPlayerGame(),
        extractedByPlayerId: {
          'p1': {CommodityCatalog.grain.id: 3, CommodityCatalog.iron.id: 1},
          'p2': {CommodityCatalog.iron.id: 2, CommodityCatalog.coal.id: 4},
        },
        stockpilePins: [
          (playerIndex: 0, commodityId: CommodityCatalog.grain.id, quantity: 3),
          (playerIndex: 0, commodityId: CommodityCatalog.iron.id, quantity: 1),
          (playerIndex: 1, commodityId: CommodityCatalog.iron.id, quantity: 2),
          (playerIndex: 1, commodityId: CommodityCatalog.coal.id, quantity: 4),
        ],
      ),
      applyExtractionForPlayersScenario(
        label: 'players with no extraction keep existing stockpile',
        game: minimalTwoPlayerGame(
          players: [
            const Player(
              id: 'p1',
              displayName: 'A',
              isHuman: true,
            ).copyWith(
              stockpile: const Stockpile().applyDelta(
                CommodityCatalog.grain.id,
                7,
              ),
            ),
            const Player(id: 'p2', displayName: 'B', isHuman: false),
          ],
        ),
        extractedByPlayerId: {
          'p2': {CommodityCatalog.iron.id: 2},
        },
        stockpilePins: [
          (playerIndex: 0, commodityId: CommodityCatalog.grain.id, quantity: 7),
          (playerIndex: 1, commodityId: CommodityCatalog.iron.id, quantity: 2),
        ],
      ),
      applyExtractionForPlayersScenario(
        label: 'empty extractedByPlayerId returns game unchanged',
        game: minimalTwoPlayerGame(
          players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
        ),
        extractedByPlayerId: const {},
        expectUnchangedPlayers: true,
      ),
    ];
