// Industry Counsel Agree apply handlers (Refs #4191).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/screens/counsel/counsel_industry_apply.dart';
import 'panel_fixtures/core.dart';

void main() {
  suppressLogsForTests();

  group('industryCounselOrdersAfterTrainAgree', () {
    test('returns null when tier is not affordable', () {
      const playerId = kPanelTestHumanPlayerId;
      final game = buildPanelTestGame(
        players: [
          Player(
            id: playerId,
            displayName: 'Broke GP',
            isHuman: true,
            stockpile: const Stockpile(),
            workerPool: const WorkerPool(peasants: 1),
          ),
        ],
      );

      final result = industryCounselOrdersAfterTrainAgree(
        currentOrders: const Orders(),
        playerId: playerId,
        tier: WorkerTier.peasant,
        game: game,
        topology: const MapTopology(),
      );

      expect(result, isNull);
    });

    test('appends recruit order when tier is affordable', () {
      const playerId = kPanelTestHumanPlayerId;
      final game = buildPanelTestGame(
        players: [
          Player(
            id: playerId,
            displayName: 'Funded GP',
            isHuman: true,
            stockpile: Stockpile().applyDelta(CommodityCatalog.fabric.id, 4),
            workerPool: const WorkerPool(peasants: 1),
          ),
        ],
      );

      final result = industryCounselOrdersAfterTrainAgree(
        currentOrders: const Orders(),
        playerId: playerId,
        tier: WorkerTier.peasant,
        game: game,
        topology: const MapTopology(),
      );

      expect(result, isNotNull);
      final queued =
          result!.recruitWorkerOrdersByPlayerId[playerId] ?? const [];
      expect(queued, hasLength(1));
      expect(queued.single.targetTier, WorkerTier.peasant);
    });
  });
}
