// Table-driven treasury bid budget cap scenarios (Refs #3836).

/// One row in the [capBidQuantityForBudgetsScenarios] table.
typedef CapBidQuantityScenario = ({
  String label,
  int bidQuantity,
  int remainingCargoBudget,
  int remainingTreasuryBudget,
  int? unitPrice,
  int expected,
  String? refs,
});

/// Canonical scenarios for [capBidQuantityForBudgets] parity with suggester
/// clamp semantics (cargo first, then treasury affordability).
const List<CapBidQuantityScenario> capBidQuantityForBudgetsScenarios = [
  (
    label: 'cargo-only cap when treasury is ample',
    bidQuantity: 10,
    remainingCargoBudget: 4,
    remainingTreasuryBudget: 1000,
    unitPrice: 30,
    expected: 4,
    refs: '#3093',
  ),
  (
    label: 'treasury-only cap when cargo is ample',
    bidQuantity: 10,
    remainingCargoBudget: 100,
    remainingTreasuryBudget: 90,
    unitPrice: 30,
    expected: 3,
    refs: '#3123',
  ),
  (
    label: 'zero treasury budget yields zero',
    bidQuantity: 5,
    remainingCargoBudget: 100,
    remainingTreasuryBudget: 0,
    unitPrice: 30,
    expected: 0,
    refs: '#3123',
  ),
  (
    label: 'zero cargo budget yields zero',
    bidQuantity: 5,
    remainingCargoBudget: 0,
    remainingTreasuryBudget: 100,
    unitPrice: 30,
    expected: 0,
    refs: null,
  ),
  (
    label: 'null unit price applies cargo cap only',
    bidQuantity: 8,
    remainingCargoBudget: 5,
    remainingTreasuryBudget: 10,
    unitPrice: null,
    expected: 5,
    refs: null,
  ),
  (
    label: 'non-positive unit price applies cargo cap only',
    bidQuantity: 8,
    remainingCargoBudget: 5,
    remainingTreasuryBudget: 10,
    unitPrice: 0,
    expected: 5,
    refs: null,
  ),
  (
    label: 'bid quantity below both caps passes through',
    bidQuantity: 2,
    remainingCargoBudget: 10,
    remainingTreasuryBudget: 100,
    unitPrice: 30,
    expected: 2,
    refs: null,
  ),
  (
    label: 'non-positive bid quantity yields zero',
    bidQuantity: 0,
    remainingCargoBudget: 10,
    remainingTreasuryBudget: 100,
    unitPrice: 30,
    expected: 0,
    refs: null,
  ),
];
