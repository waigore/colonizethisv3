import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/core/services/debug/app_event_handler_debug_worker_pool.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'debug_handler_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugWorkerPoolCredit', () {
    test('returns message when there is no active game', () {
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'peasants',
        requestedAmount: 10,
        creditedAmount: 10,
      );
      final result = applyDebugWorkerPoolCredit(currentGame: null, event: event);
      expect(result.game, isNull);
      expect(result.message, contains('no active game'));
    });

    test('adds credited amount to matching worker tier', () {
      final game = buildDebugHandlerPlayerGame(
        id: 'g-workers',
        workerPool: const WorkerPool(peasants: 10, apprentices: 2),
      );
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'peasants',
        requestedAmount: 5,
        creditedAmount: 5,
      );
      final result = applyDebugWorkerPoolCredit(currentGame: game, event: event);
      expect(result.game, isNotNull);
      final p1 = result.game!.players.single;
      expect(p1.workerPool.peasants, 15);
      expect(p1.workerPool.apprentices, 2);
      expect(result.message, contains('peasants'));
      expect(result.message, contains('15'));
    });

    test('clamped success message includes requested and credited amounts', () {
      final game = buildDebugHandlerPlayerGame(
        id: 'g-workers2',
        workerPool: const WorkerPool(masters: 1),
      );
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'masters',
        requestedAmount: 12000,
        creditedAmount: 9999,
      );
      final result = applyDebugWorkerPoolCredit(currentGame: game, event: event);
      expect(result.game!.players.single.workerPool.masters, 10000);
      expect(result.message, contains('12000'));
      expect(result.message, contains('9999'));
    });

    test('applies during non-Orders turn phases (parity with debug treasury policy)', () {
      final game = buildDebugHandlerPlayerGame(
        id: 'g-workers3',
        phase: TurnPhase.movement,
        workerPool: const WorkerPool(apprentices: 1),
      );
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'apprentices',
        requestedAmount: 3,
        creditedAmount: 3,
      );
      final result = applyDebugWorkerPoolCredit(currentGame: game, event: event);
      expect(result.game, isNotNull);
      expect(result.game!.players.single.workerPool.apprentices, 4);
      expect(result.message, contains('apprentices'));
    });

    test('ignores unknown worker tier on event', () {
      final game = buildDebugHandlerPlayerGame(id: 'g-workers4');
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'not_a_tier',
        requestedAmount: 1,
        creditedAmount: 1,
      );
      final result = applyDebugWorkerPoolCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(result.message, contains('unknown worker tier'));
    });
  });
}
