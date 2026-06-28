import 'package:colonizethis_app/core/services/app_event_handler_debug_stockpile.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

Game _gameWithPlayer({TurnPhase phase = TurnPhase.orders}) {
  return Game(
    id: 'g-stockpile',
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
    ],
  );
}

void main() {
  suppressLogsForTests();

  final commodityId = CommodityCatalog.paper.id;

  group('applyDebugStockpileCredit', () {
    test('credits commodity and reports new balance (equal amounts)', () {
      final game = _gameWithPlayer();
      final event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: commodityId,
        requestedAmount: 7,
        creditedAmount: 7,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(
        result.game!.players.single.stockpile.quantityOf(commodityId),
        7,
      );
      expect(
        result.message,
        'Stockpile $commodityId +7. New balance: 7.',
      );
    });

    test('clamped credit includes requested and credited amounts', () {
      final game = _gameWithPlayer();
      final event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: commodityId,
        requestedAmount: 99999,
        creditedAmount: 9999,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(
        result.message,
        'Stockpile $commodityId +9999 (requested 99999, credited 9999). '
        'New balance: 9999.',
      );
    });

    test('short-circuits with no active game', () {
      final event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: commodityId,
        requestedAmount: 10,
        creditedAmount: 10,
      );
      final result = applyDebugStockpileCredit(currentGame: null, event: event);
      expect(result.game, isNull);
      expect(result.message, 'Debug add_resource ignored: no active game.');
    });

    test('rejects outside human Orders phase', () {
      final game = _gameWithPlayer(phase: TurnPhase.movement);
      final event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: commodityId,
        requestedAmount: 10,
        creditedAmount: 10,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        'Debug add_resource rejected: command is allowed only during human '
        'Orders phase.',
      );
    });

    test('short-circuits when credited amount below minimum', () {
      final game = _gameWithPlayer();
      final event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: commodityId,
        requestedAmount: 0,
        creditedAmount: 0,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        'Debug add_resource ignored: credited amount must be >= 1.',
      );
    });

    test('short-circuits on unknown player', () {
      final game = _gameWithPlayer();
      final event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'ghost',
        commodityId: commodityId,
        requestedAmount: 10,
        creditedAmount: 10,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        'Debug add_resource ignored: unknown player ghost.',
      );
    });
  });
}
