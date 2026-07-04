// Table-driven matcher treasury budget helper scenarios (Refs #3856).

/// One row in [maxAffordableBidQuantityScenarios].
typedef MaxAffordableBidQuantityScenario = ({
  String label,
  int bidRemaining,
  double pricePerUnit,
  int remainingTreasuryBudget,
  int expected,
  String? refs,
});

/// Canonical scenarios for [maxAffordableBidQuantity] parity with
/// [capBidQuantityForBudgets] treasury semantics.
const List<MaxAffordableBidQuantityScenario> maxAffordableBidQuantityScenarios =
    [
  (
    label: 'floor(treasury / price) when price is positive',
    bidRemaining: 10,
    pricePerUnit: 30.0,
    remainingTreasuryBudget: 90,
    expected: 3,
    refs: '#3115',
  ),
  (
    label: 'zero treasury budget yields zero',
    bidRemaining: 10,
    pricePerUnit: 30.0,
    remainingTreasuryBudget: 0,
    expected: 0,
    refs: '#3115',
  ),
  (
    label: 'missing-price free-fill returns bid remaining',
    bidRemaining: 8,
    pricePerUnit: 0.0,
    remainingTreasuryBudget: 10,
    expected: 8,
    refs: '#3115',
  ),
  (
    label: 'negative price preserves free-fill contract',
    bidRemaining: 5,
    pricePerUnit: -1.0,
    remainingTreasuryBudget: 0,
    expected: 5,
    refs: '#3115',
  ),
];
