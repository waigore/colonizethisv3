// Table-driven economy extraction scenarios (Refs #3939 phase 3 slice 34).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core_economy_test_support.dart';
import 'economy_extraction_expectations.dart';

/// One row in [applyExtractionToStockpileScenarios] (Refs #3939 slice 64).
typedef ApplyExtractionToStockpileScenario = ({
  String label,
  void Function() run,
  String? refs,
});

void runApplyExtractionToStockpileScenario(
  ApplyExtractionToStockpileScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [applyExtractionToStockpile].
List<ApplyExtractionToStockpileScenario>
applyExtractionToStockpileScenarios() => [
  applyExtractionToStockpileScenario(
    label: 'adds extracted quantities to stockpile',
    extracted: {'grain': 5, 'iron': 2},
    expectedQuantities: {'grain': 5, 'iron': 2},
  ),
  applyExtractionToStockpileScenario(
    label: 'accumulates on existing stockpile',
    initialDeltas: {'grain': 3, 'meat': 1},
    extracted: {'grain': 4, 'meat': 2},
    expectedQuantities: {'grain': 7, 'meat': 3},
  ),
  applyExtractionToStockpileScenario(
    label: 'ignores negative values in extracted',
    initialDeltas: {'grain': 10},
    extracted: {'grain': -2, 'meat': 3},
    expectedQuantities: {'grain': 10, 'meat': 3},
  ),
  applyExtractionToStockpileScenario(
    label: 'zero quantities do not change stockpile',
    initialDeltas: {'grain': 5},
    extracted: {'grain': 0, 'iron': 0},
    expectedQuantities: {'grain': 5},
  ),
  applyExtractionToStockpileScenario(
    label: 'empty extracted returns same stockpile',
    initialDeltas: {'grain': 5},
    extracted: const {},
    expectedQuantities: {'grain': 5},
  ),
  applyExtractionToStockpileScenario(
    label:
        'adds large extraction without storage cap (unbounded strategic stockpile)',
    initialDeltas: {'grain': 1000000},
    extracted: {'grain': 500000},
    expectedQuantities: {'grain': 1500000},
  ),
];

/// One row in [applyExtractionForPlayersScenarios] (Refs #3939 slice 64).
typedef ApplyExtractionForPlayersScenario = ({
  String label,
  void Function() run,
  String? refs,
});

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
          'p1': {'grain': 3, 'iron': 1},
          'p2': {'iron': 2, 'coal': 4},
        },
        stockpilePins: [
          (playerIndex: 0, commodityId: 'grain', quantity: 3),
          (playerIndex: 0, commodityId: 'iron', quantity: 1),
          (playerIndex: 1, commodityId: 'iron', quantity: 2),
          (playerIndex: 1, commodityId: 'coal', quantity: 4),
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
            ).copyWith(stockpile: const Stockpile().applyDelta('grain', 7)),
            const Player(id: 'p2', displayName: 'B', isHuman: false),
          ],
        ),
        extractedByPlayerId: {
          'p2': {'iron': 2},
        },
        stockpilePins: [
          (playerIndex: 0, commodityId: 'grain', quantity: 7),
          (playerIndex: 1, commodityId: 'iron', quantity: 2),
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
