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
    runLabeledScenarios(
      <
        ({
          String label,
          int treasury,
          Map<String, int> prices,
          List<TradeOrder> staged,
          int? projectedTreasuryDelta,
          int budgetTotal,
          int budgetRemaining,
          bool warningVisible,
        })
      >[
        (
          label: 'reports remaining budget after staged bid spend',
          treasury: 100,
          prices: const {'timber': 30},
          staged: [bidOrder('timber', 2)],
          projectedTreasuryDelta: -60,
          budgetTotal: 100,
          budgetRemaining: 40,
          warningVisible: false,
        ),
        (
          label: 'shows warning when remaining budget is zero after bids',
          treasury: 60,
          prices: const {'timber': 30},
          staged: [bidOrder('timber', 2)],
          projectedTreasuryDelta: -60,
          budgetTotal: 60,
          budgetRemaining: 0,
          warningVisible: true,
        ),
        (
          label: 'offers do not reduce remaining bid budget',
          treasury: 100,
          prices: const {'timber': 30},
          staged: [offerOrder('timber', 5)],
          projectedTreasuryDelta: 0,
          budgetTotal: 100,
          budgetRemaining: 100,
          warningVisible: false,
        ),
        (
          label: 'reduces total budget when non-bid deficit is projected',
          treasury: 100,
          prices: const {},
          staged: const <TradeOrder>[],
          projectedTreasuryDelta: -40,
          budgetTotal: 60,
          budgetRemaining: 60,
          warningVisible: false,
        ),
        (
          label: 'falls back to raw treasury when projectedDelta is null',
          treasury: 75,
          prices: const {},
          staged: const <TradeOrder>[],
          projectedTreasuryDelta: null,
          budgetTotal: 75,
          budgetRemaining: 75,
          warningVisible: false,
        ),
        (
          label: 'shows warning when total budget is zero with no staged bids',
          treasury: 0,
          prices: const {},
          staged: const <TradeOrder>[],
          projectedTreasuryDelta: 0,
          budgetTotal: 0,
          budgetRemaining: 0,
          warningVisible: true,
        ),
      ],
      (scenario) {
        final game = buildTreasuryBidBudgetGame(
          treasury: scenario.treasury,
          prices: scenario.prices,
        );
        final state = marketTabBidBudgetHeaderState(
          game: game,
          playerId: humanPlayerId,
          orders: humanOrdersWith(scenario.staged),
          projectedTreasuryDelta: scenario.projectedTreasuryDelta,
          resourceRules: rules,
        );
        expect(state.budgetTotal, scenario.budgetTotal);
        expect(state.budgetRemaining, scenario.budgetRemaining);
        expect(state.warningVisible, scenario.warningVisible);
      },
      labelOf: (s) => s.label,
    );
  });
}
