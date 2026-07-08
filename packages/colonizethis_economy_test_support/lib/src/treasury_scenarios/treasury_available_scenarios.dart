// Table-driven treasuryAvailableForBidsByPlayer scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_expectations.dart';
import 'treasury_test_support.dart';

/// One row for [treasuryAvailableForBidsScenarios].
typedef TreasuryAvailableScenario = ({
  String label,
  int treasury,
  String playerId,
  int projectedNonBidTreasuryDelta,
  int expected,
  String? refs,
  TreasuryAvailableExpectation? extra,
});

final List<TreasuryAvailableScenario> treasuryAvailableForBidsScenarios = [
  treasuryAvailableRow(
    label: "returns the player's raw treasury for known players",
    treasury: 250,
    expected: 250,
    refs: '#3093',
  ),
  treasuryAvailableRow(
    label: 'clamps negative treasury to 0 (defensive guard)',
    treasury: -10,
    expected: 0,
    refs: null,
  ),
  treasuryAvailableRow(
    label: 'returns 0 when playerId does not resolve to a player',
    treasury: 100,
    playerId: 'gp_ghost',
    expected: 0,
    refs: null,
  ),
  treasuryAvailableRow(
    label: 'default projectedNonBidTreasuryDelta == 0 preserves the legacy '
        '"raw treasury" contract for callers without a projection',
    treasury: 175,
    expected: 175,
    refs: '#3093',
    extra: TreasuryAvailableExpectation(omitProjectedDeltaAlias: true),
  ),
  treasuryAvailableRow(
    label: 'projectedNonBidTreasuryDelta < 0 subtracts the absolute deficit '
        'from raw treasury (positive AC #1)',
    treasury: 100,
    projectedNonBidTreasuryDelta: -40,
    expected: 60,
    refs: '#3093',
  ),
  treasuryAvailableRow(
    label: 'projectedNonBidTreasuryDelta > 0 leaves the budget at raw treasury '
        '(conservative — net non-bid income never raises the budget)',
    treasury: 100,
    projectedNonBidTreasuryDelta: 50,
    expected: 100,
    refs: '#3093',
  ),
  treasuryAvailableRow(
    label: 'projected deficit equal to treasury clamps the budget at exactly 0',
    treasury: 80,
    projectedNonBidTreasuryDelta: -80,
    expected: 0,
    refs: null,
  ),
  treasuryAvailableRow(
    label: 'projected deficit larger than treasury still clamps at 0 (not negative)',
    treasury: 50,
    projectedNonBidTreasuryDelta: -120,
    expected: 0,
    refs: null,
  ),
  treasuryAvailableRow(
    label: 'projectedNonBidTreasuryDelta is ignored when treasury is already 0',
    treasury: 0,
    projectedNonBidTreasuryDelta: 25,
    expected: 0,
    refs: null,
    extra: const TreasuryAvailableExpectation(
      ignoredProjectedDeltaWhenTreasuryZero: -25,
    ),
  ),
  treasuryAvailableRow(
    label: 'unknown playerId returns 0 even when a non-zero '
        'projectedNonBidTreasuryDelta is supplied',
    treasury: 100,
    playerId: 'gp_ghost',
    projectedNonBidTreasuryDelta: -30,
    expected: 0,
    refs: null,
  ),
];

void runTreasuryAvailableScenario(TreasuryAvailableScenario scenario) {
  final game = buildTreasuryBidBudgetGame(treasury: scenario.treasury);
  if (scenario.extra != null) {
    assertTreasuryAvailableExpectation(
      game: game,
      playerId: scenario.playerId,
      expectation: scenario.extra!,
    );
  }
  final actual = treasuryAvailableForBidsByPlayer(
    game: game,
    playerId: scenario.playerId,
    projectedNonBidTreasuryDelta: scenario.projectedNonBidTreasuryDelta,
  );
  expect(actual, scenario.expected);
}

/// UI composition scenarios reconstructing treasury-bid-cap math end-to-end.
class TreasuryUiCompositionScenario {
  const TreasuryUiCompositionScenario({
    required this.label,
    required this.treasury,
    this.prices = const {},
    this.stagedBids = const [],
    this.projectedNonBidTreasuryDelta = 0,
    required this.verify,
    this.refs,
  });

  TreasuryUiCompositionScenario.expect({
    required String label,
    required int treasury,
    Map<CommodityId, int> prices = const {},
    List<TradeOrder> stagedBids = const [],
    int projectedNonBidTreasuryDelta = 0,
    required TreasuryUiCompositionExpectation expect,
    String? refs,
  }) : this(
          label: label,
          treasury: treasury,
          prices: prices,
          stagedBids: stagedBids,
          projectedNonBidTreasuryDelta: projectedNonBidTreasuryDelta,
          verify: ({
            required game,
            required rules,
            required budget,
            required currentSpend,
          }) =>
              assertTreasuryUiCompositionExpectation(
            game: game,
            rules: rules,
            budget: budget,
            currentSpend: currentSpend,
            expectation: expect,
          ),
          refs: refs,
        );

  final String label;
  final int treasury;
  final Map<CommodityId, int> prices;
  final List<TradeOrder> stagedBids;
  final int projectedNonBidTreasuryDelta;
  final void Function({
    required Game game,
    required data.ResourceRules rules,
    required int budget,
    required int currentSpend,
  })
  verify;
  final String? refs;
}

List<TreasuryUiCompositionScenario> treasuryUiCompositionScenarios(
  data.ResourceRules rules,
) => [
  TreasuryUiCompositionScenario.expect(
    label: 'treasury 100, market price timber 30, no staged bids → headroom for '
        'fresh row equals raw treasury (allows up to qty 3)',
    treasury: 100,
    prices: const {'timber': 30},
    expect: const TreasuryUiCompositionExpectation(
      commodityPrices: {'timber': 30},
      maxAffordableQty: (commodityId: 'timber', qty: 3),
    ),
    refs: '#3093',
  ),
  TreasuryUiCompositionScenario.expect(
    label: 'treasury 100, staged Bid timber qty 3 (spend 90) → adding a fresh bid '
        'for iron (price 80) is refused (headroom 10 < 80)',
    treasury: 100,
    prices: const {'timber': 30, 'iron': 80},
    stagedBids: [bidOrder('timber', 3)],
    expect: const TreasuryUiCompositionExpectation(
      commodityPrices: {'iron': 80},
      headroom: 10,
      headroomLessThanCommodity: 'iron',
    ),
    refs: '#3093',
  ),
  TreasuryUiCompositionScenario.expect(
    label: 'treasury 100, staged Bid timber qty 3 (spend 90), incrementing timber → '
        'next increment would make spend 120 (> 100), so the UI must silent-no-op',
    treasury: 100,
    prices: const {'timber': 30},
    stagedBids: [bidOrder('timber', 3)],
    expect: const TreasuryUiCompositionExpectation(
      commodityPrices: {'timber': 30},
      spendIncrementExceedsBudget: (commodityId: 'timber', delta: 1),
    ),
    refs: '#3093',
  ),
  TreasuryUiCompositionScenario.expect(
    label: 'treasury 100, projectedDelta=-40 (UI reconstructs non-bid delta with '
        'no staged bids), market price timber 30 → budget = 60, default qty '
        '1 fits and headroom permits up to qty 2 (spend 60)',
    treasury: 100,
    prices: const {'timber': 30},
    projectedNonBidTreasuryDelta: -40,
    expect: const TreasuryUiCompositionExpectation(
      budget: 60,
      commodityPrices: {'timber': 30},
      maxAffordableQty: (commodityId: 'timber', qty: 2),
    ),
    refs: '#3093',
  ),
  TreasuryUiCompositionScenario.expect(
    label: 'treasury 50, projectedNonBidTreasuryDelta=-60 → budget clamps to 0 '
        'so no bid (even default qty 1) can be staged on any priced '
        'commodity (silent no-op gate)',
    treasury: 50,
    prices: const {'timber': 30},
    projectedNonBidTreasuryDelta: -60,
    expect: const TreasuryUiCompositionExpectation(
      budget: 0,
      commodityPrices: {'timber': 30},
      budgetLessThanCommodity: 'timber',
    ),
    refs: '#3093',
  ),
];

void runTreasuryUiCompositionScenario(
  TreasuryUiCompositionScenario scenario,
  data.ResourceRules rules,
) {
  final game = buildTreasuryBidBudgetGame(
    treasury: scenario.treasury,
    prices: scenario.prices,
  );
  final orders = scenario.stagedBids.isEmpty
      ? const Orders()
      : humanOrdersWith(scenario.stagedBids);
  final budget = treasuryAvailableForBidsByPlayer(
    game: game,
    playerId: humanPlayerId,
    projectedNonBidTreasuryDelta: scenario.projectedNonBidTreasuryDelta,
  );
  final currentSpend = stagedBidTotalSpendByPlayer(
    orders: orders,
    playerId: humanPlayerId,
    game: game,
    resourceRules: rules,
  );
  scenario.verify(
    game: game,
    rules: rules,
    budget: budget,
    currentSpend: currentSpend,
  );
}
