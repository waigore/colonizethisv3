// AppEventHandlerScope debug treasury/stockpile credit ACs (Refs #4352).
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_event_handler_scope_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugTreasuryCredit', () {
    test('returns message when there is no active game', () {
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 10,
        creditedAmount: 10,
      );
      final result = applyDebugTreasuryCredit(currentGame: null, event: event);
      expect(result.game, isNull);
      expect(result.message, contains('no active game'));
    });

    test('adds credited amount to human player treasury', () {
      final game = scopeEmptyWorldGame(
        id: 'g-treasury',
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: 100),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 50,
        creditedAmount: 50,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game, isNotNull);
      final p1 = result.game!.players.firstWhere((p) => p.id == 'p1');
      expect(p1.treasury, 150);
      expect(result.message, contains('+50'));
      expect(result.message, contains('150'));
    });

    test('clamped success message includes requested and credited amounts', () {
      final game = scopeEmptyWorldGame(
        id: 'g-treasury2',
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: 0),
        ],
      );
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 12000,
        creditedAmount: 9999,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game!.players.single.treasury, 9999);
      expect(result.message, contains('12000'));
      expect(result.message, contains('9999'));
    });

    test('rejects command outside human orders phase', () {
      final game = scopeEmptyWorldGame(
        id: 'g-treasury3',
        phase: TurnPhase.movement,
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: 10),
        ],
      );
      const event = CreditDebugTreasuryEvent(
        humanPlayerId: 'p1',
        requestedAmount: 50,
        creditedAmount: 50,
      );
      final result = applyDebugTreasuryCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        contains('allowed only during human Orders phase'),
      );
    });
  });

  group('applyDebugStockpileCredit', () {
    test('adds credited amount to human player stockpile commodity', () {
      final game = scopeEmptyWorldGame(
        id: 'g-stockpile',
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: Stockpile(quantities: {'grain': 100}),
          ),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );
      const event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: 'grain',
        requestedAmount: 50,
        creditedAmount: 50,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(result.game, isNotNull);
      final p1 = result.game!.players.firstWhere((p) => p.id == 'p1');
      expect(p1.stockpile.quantityOf('grain'), 150);
      expect(result.message, contains('grain'));
      expect(result.message, contains('150'));
    });

    test('rejects add_resource command outside human orders phase', () {
      final game = scopeEmptyWorldGame(
        id: 'g-stockpile2',
        phase: TurnPhase.movement,
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: 'grain',
        requestedAmount: 50,
        creditedAmount: 50,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(result.game, isNull);
      expect(
        result.message,
        contains('allowed only during human Orders phase'),
      );
    });

    test('clamped success message includes requested and credited amounts', () {
      final game = scopeEmptyWorldGame(
        id: 'g-stockpile3',
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const event = CreditDebugStockpileCommodityEvent(
        humanPlayerId: 'p1',
        commodityId: 'castIron',
        requestedAmount: 12000,
        creditedAmount: 9999,
      );
      final result = applyDebugStockpileCredit(currentGame: game, event: event);
      expect(result.game, isNotNull);
      expect(
        result.game!.players.single.stockpile.quantityOf('castIron'),
        9999,
      );
      expect(result.message, contains('12000'));
      expect(result.message, contains('9999'));
    });
  });
}
