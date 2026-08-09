// Post-extraction labour readiness preview. SPEC/ui/production-panel.md § Labour readiness (#4237).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_stockpile_preview_cases.dart';
import 'support/economy_stockpile_preview_test_support.dart';

void main() {
  suppressLogsForTests();

  group('labourReadinessForPlayer', () {
    test(
      'uses post-extraction stockpile so extraction grain feeds idle workers',
      () {
        final player = economyPreviewSinglePlayer(
          workerPool: const WorkerPool(peasants: 4),
          stockpile: const Stockpile(),
        );
        final game = economyPreviewSinglePlayerGame(player);

        final warehouseOnly = computeLabourReadiness(
          workers: player.workerPool,
          stockpile: player.stockpile,
        );
        expect(warehouseOnly.effectiveLabour, 0);

        final afterExtraction = labourReadinessForPlayer(
          game: game,
          topology: const MapTopology(),
          playerId: 'p1',
          inputs: economyPreviewInputs(
            extractedByPlayerId: {
              'p1': {
                CommodityCatalog.grain.id: 10,
                CommodityCatalog.meat.id: 10,
              },
            },
          ),
        );
        expect(
          afterExtraction.effectiveLabour,
          player.workerPool.labourSupplyPerTurn,
        );
        expect(afterExtraction.isFullCapacity, isTrue);
      },
    );
  });
}
