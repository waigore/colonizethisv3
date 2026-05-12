import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/core/services/app_event_handler_debug_worker_pool.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

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
      final result = applyDebugWorkerPoolCredit(
        currentGame: null,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('no active game'));
    });

    test('adds credited amount to correct worker tier', () {
      final game = Game(
        id: 'g-workers',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            workerPool: WorkerPool(peasants: 2, apprentices: 3),
          ),
        ],
      );
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'apprentices',
        requestedAmount: 5,
        creditedAmount: 5,
      );
      final result = applyDebugWorkerPoolCredit(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNotNull);
      final p1 = result.game!.players.single;
      expect(p1.workerPool.peasants, 2);
      expect(p1.workerPool.apprentices, 8);
      expect(result.message, contains('apprentices'));
      expect(result.message, contains('8'));
    });

    test('clamped success message includes requested and credited amounts', () {
      final game = Game(
        id: 'g-workers2',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'journeymen',
        requestedAmount: 12000,
        creditedAmount: 9999,
      );
      final result = applyDebugWorkerPoolCredit(
        currentGame: game,
        event: event,
      );
      expect(result.game!.players.single.workerPool.journeymen, 9999);
      expect(result.message, contains('12000'));
      expect(result.message, contains('9999'));
    });

    test('applies worker pool credit outside human orders phase', () {
      final game = Game(
        id: 'g-workers3',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.movement, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            workerPool: WorkerPool(masters: 1),
          ),
        ],
      );
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'masters',
        requestedAmount: 3,
        creditedAmount: 3,
      );
      final result = applyDebugWorkerPoolCredit(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNotNull);
      expect(result.game!.players.single.workerPool.masters, 4);
    });

    test('worker pool mutation round-trips through game json', () {
      final game = Game(
        id: 'g-workers-json',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'peasants',
        requestedAmount: 40,
        creditedAmount: 40,
      );
      final applied = applyDebugWorkerPoolCredit(
        currentGame: game,
        event: event,
      );
      final roundTrip = Game.fromJson(applied.game!.toJson());
      expect(roundTrip.players.single.workerPool.peasants, 40);
    });

    test('rejects unsupported worker tier id at apply layer', () {
      final game = Game(
        id: 'g-workers-bad-tier',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = CreditDebugWorkerPoolEvent(
        humanPlayerId: 'p1',
        workerTierId: 'invalid_tier',
        requestedAmount: 1,
        creditedAmount: 1,
      );
      final result = applyDebugWorkerPoolCredit(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('unsupported tier'));
    });
  });
}
