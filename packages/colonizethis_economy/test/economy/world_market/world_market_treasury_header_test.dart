// Treasury bid-budget header composition (Refs #4631 split from treasury runner).
//
// SPEC/game/world-market.md § Treasury budget for bids,
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('projectedNonBidTreasuryDelta (Refs #4186)', () {
    test('returns 0 when projectedDelta is unavailable', () {
      expect(projectedNonBidTreasuryDelta(null, 40), 0);
    });

    test('adds staged bid spend back to signed projected delta', () {
      expect(projectedNonBidTreasuryDelta(-80, 30), -50);
      expect(projectedNonBidTreasuryDelta(10, 0), 10);
    });
  });

  group('marketTabBidBudgetHeaderState (Refs #4186)', () {
    test('reports remaining budget after staged bid spend', () {
      final game = buildTreasuryBidBudgetGame(
        treasury: 100,
        prices: const {'timber': 30},
      );
      final orders = humanOrdersWith([bidOrder('timber', 2)]);

      final state = marketTabBidBudgetHeaderState(
        game: game,
        playerId: humanPlayerId,
        orders: orders,
        projectedTreasuryDelta: -60,
        resourceRules: rules,
      );

      expect(state.budgetTotal, 100);
      expect(state.budgetRemaining, 40);
      expect(state.warningVisible, isFalse);
    });

    test('shows warning when remaining budget is zero after bids', () {
      final game = buildTreasuryBidBudgetGame(
        treasury: 60,
        prices: const {'timber': 30},
      );
      final orders = humanOrdersWith([bidOrder('timber', 2)]);

      final state = marketTabBidBudgetHeaderState(
        game: game,
        playerId: humanPlayerId,
        orders: orders,
        projectedTreasuryDelta: -60,
        resourceRules: rules,
      );

      expect(state.budgetTotal, 60);
      expect(state.budgetRemaining, 0);
      expect(state.warningVisible, isTrue);
    });

    test('offers do not reduce remaining bid budget', () {
      final game = buildTreasuryBidBudgetGame(
        treasury: 100,
        prices: const {'timber': 30},
      );
      final orders = humanOrdersWith([offerOrder('timber', 5)]);

      final state = marketTabBidBudgetHeaderState(
        game: game,
        playerId: humanPlayerId,
        orders: orders,
        projectedTreasuryDelta: 0,
        resourceRules: rules,
      );

      expect(state.budgetTotal, 100);
      expect(state.budgetRemaining, 100);
      expect(state.warningVisible, isFalse);
    });

    test('reduces total budget when non-bid deficit is projected', () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      final orders = humanOrdersWith(const <TradeOrder>[]);

      final state = marketTabBidBudgetHeaderState(
        game: game,
        playerId: humanPlayerId,
        orders: orders,
        projectedTreasuryDelta: -40,
        resourceRules: rules,
      );

      expect(state.budgetTotal, 60);
      expect(state.budgetRemaining, 60);
      expect(state.warningVisible, isFalse);
    });

    test('falls back to raw treasury when projectedDelta is null', () {
      final game = buildTreasuryBidBudgetGame(treasury: 75);
      final orders = humanOrdersWith(const <TradeOrder>[]);

      final state = marketTabBidBudgetHeaderState(
        game: game,
        playerId: humanPlayerId,
        orders: orders,
        projectedTreasuryDelta: null,
        resourceRules: rules,
      );

      expect(state.budgetTotal, 75);
      expect(state.budgetRemaining, 75);
      expect(state.warningVisible, isFalse);
    });

    test('shows warning when total budget is zero with no staged bids', () {
      final game = buildTreasuryBidBudgetGame(treasury: 0);
      final orders = humanOrdersWith(const <TradeOrder>[]);

      final state = marketTabBidBudgetHeaderState(
        game: game,
        playerId: humanPlayerId,
        orders: orders,
        projectedTreasuryDelta: 0,
        resourceRules: rules,
      );

      expect(state.budgetTotal, 0);
      expect(state.budgetRemaining, 0);
      expect(state.warningVisible, isTrue);
    });
  });
}
