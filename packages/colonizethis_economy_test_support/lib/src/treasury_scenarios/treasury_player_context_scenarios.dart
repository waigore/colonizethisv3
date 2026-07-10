// dart format off
// Table-driven world-market player-context facade scenarios (Refs #3856, #3939 slice 19).

import 'treasury_player_context_expectations.dart';

/// One row for `PlayerContextScenario` tables (Refs #3939 slice 63).
typedef PlayerContextScenario = ({String label, void Function() run, String? refs});

/// Compact expect-wired row (Refs #3939 slice 59).
PlayerContextScenario playerContextRow({required String label, required PlayerContextExpectation expect, String? refs}) => (label: label, run: () => assertPlayerContextExpectation(expect), refs: refs);

void runPlayerContextScenario(PlayerContextScenario scenario) {
  scenario.run();
}

/// `worldMarketPlayerContextFromGame` snapshot cases (Refs #3615 Cluster 2).
List<PlayerContextScenario> worldMarketPlayerContextSnapshotScenarios() => [
  playerContextRow(
    label: 'surfaces the raw treasury budget for a known player',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.snapshot, treasury: 175, treasuryBudgetForBids: 175, worldMarketStateSameAsGame: true),
    refs: '#3615',
  ),
  playerContextRow(
    label: 'negative treasury clamps the snapshot budget at 0',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.snapshot, treasury: -25, treasuryBudgetForBids: 0),
    refs: '#3615',
  ),
  playerContextRow(
    label: 'ghost player id returns a zero-budget snapshot (ghost guard)',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.snapshot, treasury: 200, playerId: 'gp_ghost', treasuryBudgetForBids: 0),
    refs: '#3615',
  ),
  playerContextRow(
    label:
        'staged orders + projectedTreasuryDelta reduce the snapshot budget '
        'by the projected non-bid deficit',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.snapshot, treasury: 175, treasuryBudgetForBids: 125, projectedTreasuryDelta: -50),
    refs: '#3615',
  ),
];

/// Factory parity over the shared snapshot (single build path).
List<PlayerContextScenario> worldMarketPlayerContextFactoryParityScenarios() => [
  playerContextRow(
    label:
        'validation and suggestion factories reuse identical shared scalars '
        'for the same (game, player)',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.factoryParityScalars, treasury: 175),
    refs: '#3615',
  ),
  playerContextRow(
    label:
        'validation and suggestion factories share the same staged '
        'treasury-budget composition',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.factoryParityTreasury, treasury: 175, treasuryBudgetForBids: 125, projectedTreasuryDelta: -50),
    refs: '#3615',
  ),
];

/// `tradeSuggestionContextFromGame` concern-specific behavior.
List<PlayerContextScenario> tradeSuggestionContextFromGameBehaviorScenarios() => [
  playerContextRow(
    label:
        'passes the caller-supplied availability through unchanged (suggester '
        'raw-stockpile source is not replaced by offer caps)',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.suggestion, treasury: 100, availableStockpileByCommodityId: {'timber': 7, 'grain': 3}),
    refs: '#3615',
  ),
  playerContextRow(
    label: 'keeps the suggester defaults when need and priorities are omitted',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.suggestion, treasury: 100, checkDefaultNeedAndPriorities: true),
    refs: '#3615',
  ),
  playerContextRow(
    label: 'forwards caller need and priority overrides',
    expect: const PlayerContextExpectation(target: PlayerContextScenarioTarget.suggestion, treasury: 100, commodityNeedByCommodityId: {'iron': 4}, offerPriority: 9, bidPriority: 2),
    refs: '#3615',
  ),
];
// dart format on
