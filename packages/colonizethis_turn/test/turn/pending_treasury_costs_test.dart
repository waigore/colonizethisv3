// Unit tests for `pendingTreasuryCostsForTurn` (Refs #3122).
//
// SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing and
// SPEC/program/turn-resolution-phases.md § Phase sequence.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'pending_treasury_costs_cases.dart';

void main() {
  group('pendingTreasuryCostsForTurn (Refs #3122)', () {
    test('returns 0 when player has no orders', () {
      final game = pendingTreasuryGame(treasury: 1000);
      expect(pendingTreasuryCostsForTurn(game, pendingTreasuryGp, const Orders()), 0);
    });

    test('returns 0 when playerId does not resolve', () {
      final game = pendingTreasuryGame(treasury: 1000);
      expect(
        pendingTreasuryCostsForTurn(game, 'gp_ghost', const Orders()),
        0,
      );
    });

    test('sums research order treasury costs', () {
      final game = pendingTreasuryGame(treasury: 100000);
      final orders = Orders(
        researchOrdersByPlayerId: {
          pendingTreasuryGp: [
            const ResearchOrder(
              slotIndex: 0,
              techId: 'someTech',
              funding: ResearchFundingLevel.low,
            ),
            const ResearchOrder(
              slotIndex: 1,
              techId: 'anotherTech',
              funding: ResearchFundingLevel.medium,
            ),
          ],
        },
      );
      final expected =
          treasuryCostForFunding(ResearchFundingLevel.low) +
              treasuryCostForFunding(ResearchFundingLevel.medium);
      expect(pendingTreasuryCostsForTurn(game, pendingTreasuryGp, orders), expected);
    });

    test('research orders with empty techId or zero-cost funding are skipped',
        () {
      final game = pendingTreasuryGame(treasury: 100000);
      final orders = Orders(
        researchOrdersByPlayerId: {
          pendingTreasuryGp: [
            const ResearchOrder(
              slotIndex: 0,
              techId: '',
              funding: ResearchFundingLevel.high,
            ),
            const ResearchOrder(
              slotIndex: 1,
              techId: 'tech',
              funding: ResearchFundingLevel.none,
            ),
          ],
        },
      );
      expect(pendingTreasuryCostsForTurn(game, pendingTreasuryGp, orders), 0);
    });

    test('sums recruit worker treasury costs and respects affordability gate',
        () {
      const tier = WorkerTier.peasant;
      final tierRow = WorkerActionEconomyCatalog.forTier(tier);
      final game = pendingTreasuryGame(
        treasury: tierRow.treasuryCost,
        stockpile: Stockpile(quantities: {
          for (final e in tierRow.materialCosts.entries) e.key: e.value,
        }),
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          pendingTreasuryGp: [
            RecruitWorkerOrder(targetTier: tier),
            RecruitWorkerOrder(targetTier: tier),
          ],
        },
      );
      expect(
        pendingTreasuryCostsForTurn(game, pendingTreasuryGp, orders),
        tierRow.treasuryCost,
        reason: 'Only the first recruit fits the budget; the second '
            'sequential check fails canAffordRecruitWorker.',
      );
    });

    test('aggregates research + recruit + build into one int sum '
        '(WorkOrder excluded; stockpile-only material costs)', () {
      final scenario = pendingTreasuryResearchRecruitWorkScenario();
      expect(
        pendingTreasuryCostsForTurn(
          scenario.game,
          pendingTreasuryGp,
          scenario.orders,
        ),
        scenario.expected,
        reason: scenario.reason,
      );
    });

    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC9: pendingTreasuryCostsForTurn must sum Research + RecruitWorker +
    // BuildUnit treasury costs exactly and exclude stockpile-only WorkOrder
    // material costs. The "aggregates research + recruit + build" test
    // above does not actually include a BuildUnitOrder in the fixture;
    // this test pins the BuildUnit code path with all four order types
    // present (Refs #3122).
    test('aggregates research + recruit + build (with BuildUnitOrder) '
        'into one int sum equal to L + C_b + C_r '
        '(WorkOrder still excluded)', () {
      final scenario = pendingTreasuryFullAggregateScenario();
      expect(
        pendingTreasuryCostsForTurn(
          scenario.game,
          pendingTreasuryGp,
          scenario.orders,
        ),
        scenario.expected,
        reason: scenario.reason,
      );
    });

    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC9 negative pin: if the BuildUnitOrder cannot be afforded (no
    // peasants in the worker pool), the order is skipped per
    // canAffordBuildOrder gating and its `buildTreasuryCost` does not
    // contribute to the projection (Refs #3122).
    test('BuildUnitOrder skipped when canAffordBuildOrder fails: '
        'cost does not contribute', () {
      final scenario = pendingTreasuryBuildUnitSkippedScenario();
      expect(
        pendingTreasuryCostsForTurn(
          scenario.game,
          pendingTreasuryGp,
          scenario.orders,
        ),
        scenario.expected,
        reason: scenario.reason,
      );
    });

    test('returns at most the player\'s starting treasury (invariant)', () {
      // Three research orders each costing > treasury/3 — only those that
      // fit the running balance contribute, so the helper never returns
      // more than the player started with.
      final game = pendingTreasuryGame(treasury: 50);
      final orders = Orders(
        researchOrdersByPlayerId: {
          pendingTreasuryGp: [
            const ResearchOrder(
              slotIndex: 0,
              techId: 'a',
              funding: ResearchFundingLevel.maximum,
            ),
            const ResearchOrder(
              slotIndex: 1,
              techId: 'b',
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );
      final spent = pendingTreasuryCostsForTurn(game, pendingTreasuryGp, orders);
      expect(spent, lessThanOrEqualTo(50));
    });

    test('deterministic: same inputs return same value across two calls', () {
      final game = pendingTreasuryGame(treasury: 1000);
      final orders = Orders(
        researchOrdersByPlayerId: {
          pendingTreasuryGp: [
            const ResearchOrder(
              slotIndex: 0,
              techId: 'tech',
              funding: ResearchFundingLevel.low,
            ),
          ],
        },
      );
      expect(
        pendingTreasuryCostsForTurn(game, pendingTreasuryGp, orders),
        pendingTreasuryCostsForTurn(game, pendingTreasuryGp, orders),
      );
    });
  });
}
