import 'package:colonizethis_app/core/services/app_event_handler_debug_treasury.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

Game _gameWithPlayer({
  TurnPhase phase = TurnPhase.orders,
  int treasury = 100,
}) {
  return Game(
    id: 'g-treasury',
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: treasury),
    ],
  );
}

void main() {
  suppressLogsForTests();

  group('applyDebugTreasuryCredit', () {
    test('credits treasury and reports new balance (equal amounts)', () {
      final game = _gameWithPlayer(treasury: 100);
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 50,
        creditedAmount: 50,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game!.players.single.treasury, 150);
      expect(result.message, 'Treasury +50. New balance: 150.');
    });

    test('clamped credit includes requested and credited amounts', () {
      final game = _gameWithPlayer(treasury: 0);
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 12000,
        creditedAmount: 9999,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game!.players.single.treasury, 9999);
      expect(
        result.message,
        'Treasury +9999 (requested 12000, credited 9999). New balance: 9999.',
      );
    });

    test('short-circuits with no active game', () {
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 10,
        creditedAmount: 10,
      );
      final result = applyDebugTreasuryCredit(currentGame: null, event: event);
      expect(result.game, isNull);
      expect(result.message, 'Debug treasury credit ignored: no active game.');
    });

    test('rejects outside human Orders phase under add_money label', () {
      final game = _gameWithPlayer(phase: TurnPhase.movement);
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 10,
        creditedAmount: 10,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        'Debug add_money rejected: command is allowed only during human '
        'Orders phase.',
      );
    });

    test('short-circuits when credited amount below minimum', () {
      final game = _gameWithPlayer();
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 0,
        creditedAmount: 0,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        'Debug treasury credit ignored: credited amount must be >= 1.',
      );
    });

    test('short-circuits on unknown player', () {
      final game = _gameWithPlayer();
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'ghost',
        requestedAmount: 10,
        creditedAmount: 10,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        'Debug treasury credit ignored: unknown player ghost.',
      );
    });
  });
}
