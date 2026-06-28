// Unit tests for `pendingTreasuryCostsForTurn` (Refs #3122).
//
// SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing and
// SPEC/program/turn-resolution-phases.md § Phase sequence.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp = 'gp1';

Game _game({
  required int treasury,
  Stockpile stockpile = const Stockpile(),
  WorkerPool workerPool = const WorkerPool(peasants: 5),
  Map<String, bool>? techUnlocked,
}) {
  return Game(
    id: 'g_pending_treasury_costs',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: _gp,
        displayName: 'GP1',
        isHuman: false,
        treasury: treasury,
        stockpile: stockpile,
        workerPool: workerPool,
        techUnlocked: techUnlocked,
      ),
    ],
  );
}

void main() {
  group('pendingTreasuryCostsForTurn (Refs #3122)', () {
    test('returns 0 when player has no orders', () {
      final game = _game(treasury: 1000);
      expect(pendingTreasuryCostsForTurn(game, _gp, const Orders()), 0);
    });

    test('returns 0 when playerId does not resolve', () {
      final game = _game(treasury: 1000);
      expect(
        pendingTreasuryCostsForTurn(game, 'gp_ghost', const Orders()),
        0,
      );
    });

    test('sums research order treasury costs', () {
      final game = _game(treasury: 100000);
      final orders = Orders(
        researchOrdersByPlayerId: {
          _gp: [
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
      expect(pendingTreasuryCostsForTurn(game, _gp, orders), expected);
    });

    test('research orders with empty techId or zero-cost funding are skipped',
        () {
      final game = _game(treasury: 100000);
      final orders = Orders(
        researchOrdersByPlayerId: {
          _gp: [
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
      expect(pendingTreasuryCostsForTurn(game, _gp, orders), 0);
    });

    test('sums recruit worker treasury costs and respects affordability gate',
        () {
      const tier = WorkerTier.peasant;
      final tierRow = WorkerActionEconomyCatalog.forTier(tier);
      final game = _game(
        treasury: tierRow.treasuryCost,
        stockpile: Stockpile(quantities: {
          for (final e in tierRow.materialCosts.entries) e.key: e.value,
        }),
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          _gp: [
            RecruitWorkerOrder(targetTier: tier),
            RecruitWorkerOrder(targetTier: tier),
          ],
        },
      );
      expect(
        pendingTreasuryCostsForTurn(game, _gp, orders),
        tierRow.treasuryCost,
        reason: 'Only the first recruit fits the budget; the second '
            'sequential check fails canAffordRecruitWorker.',
      );
    });

    test('aggregates research + recruit + build into one int sum '
        '(WorkOrder excluded; stockpile-only material costs)', () {
      const apprentice = WorkerTier.apprentice;
      final apprenticeRow = WorkerActionEconomyCatalog.forTier(apprentice);
      final game = _game(
        treasury: 100000,
        stockpile: Stockpile(quantities: {
          for (final e in apprenticeRow.materialCosts.entries) e.key: e.value,
          'timber': 100,
        }),
        workerPool: const WorkerPool(peasants: 5, apprentices: 2),
        techUnlocked: {
          for (final t in apprenticeRow.requiredTechIds) t: true,
        },
      );
      final orders = Orders(
        researchOrdersByPlayerId: {
          _gp: [
            const ResearchOrder(
              slotIndex: 0,
              techId: 'tech',
              funding: ResearchFundingLevel.low,
            ),
          ],
        },
        recruitWorkerOrdersByPlayerId: {
          _gp: [
            RecruitWorkerOrder(targetTier: apprentice),
          ],
        },
        workOrdersByPlayerId: {
          _gp: [
            const WorkOrder(
              unitId: 'u1',
              target: 'buildImprovement',
              targetTileKey: 'oldWorld|tile-1',
            ),
          ],
        },
      );

      final expected =
          treasuryCostForFunding(ResearchFundingLevel.low) +
              apprenticeRow.treasuryCost;
      expect(
        pendingTreasuryCostsForTurn(game, _gp, orders),
        expected,
        reason: 'WorkOrder pending costs are stockpile-only and must not '
            'contribute to the treasury projection.',
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
      const apprentice = WorkerTier.apprentice;
      final apprenticeRow = WorkerActionEconomyCatalog.forTier(apprentice);
      final peasantLevies = RegimentEconomyCatalog.peasantLevies;
      final fundingLevel = ResearchFundingLevel.low;
      final game = _game(
        treasury: 100000,
        stockpile: Stockpile(quantities: {
          for (final e in apprenticeRow.materialCosts.entries) e.key: e.value,
          for (final e in peasantLevies.buildInputs.entries) e.key: e.value,
          'timber': 100,
        }),
        workerPool: const WorkerPool(peasants: 5, apprentices: 2),
        techUnlocked: {
          for (final t in apprenticeRow.requiredTechIds) t: true,
        },
      );
      final orders = Orders(
        researchOrdersByPlayerId: {
          _gp: [
            ResearchOrder(
              slotIndex: 0,
              techId: 'tech',
              funding: fundingLevel,
            ),
          ],
        },
        recruitWorkerOrdersByPlayerId: {
          _gp: [
            RecruitWorkerOrder(targetTier: apprentice),
          ],
        },
        buildUnitOrdersByPlayerId: {
          _gp: [
            BuildUnitOrder(
              unitType: peasantLevies.id,
              isMilitary: true,
              spawnProvinceId: 'oldWorld|p1',
            ),
          ],
        },
        workOrdersByPlayerId: {
          _gp: [
            const WorkOrder(
              unitId: 'u1',
              target: 'buildImprovement',
              targetTileKey: 'oldWorld|tile-1',
            ),
          ],
        },
      );

      final expected = treasuryCostForFunding(fundingLevel) +
          apprenticeRow.treasuryCost +
          peasantLevies.buildTreasuryCost;
      expect(
        pendingTreasuryCostsForTurn(game, _gp, orders),
        expected,
        reason: 'Pending Research + RecruitWorker + BuildUnit treasury '
            'costs must sum exactly (L + C_r + C_b). WorkOrder material '
            'costs are stockpile-only and must not contribute.',
      );
    });

    // SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing —
    // AC9 negative pin: if the BuildUnitOrder cannot be afforded (no
    // peasants in the worker pool), the order is skipped per
    // canAffordBuildOrder gating and its `buildTreasuryCost` does not
    // contribute to the projection (Refs #3122).
    test('BuildUnitOrder skipped when canAffordBuildOrder fails: '
        'cost does not contribute', () {
      final peasantLevies = RegimentEconomyCatalog.peasantLevies;
      final game = _game(
        treasury: 100000,
        stockpile: Stockpile(quantities: {
          for (final e in peasantLevies.buildInputs.entries) e.key: e.value,
        }),
        // peasants == 0 fails the regiment-build affordability gate per
        // `_resolveBuildDeductionPlan` "Insufficient workers".
        workerPool: const WorkerPool(peasants: 0),
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          _gp: [
            BuildUnitOrder(
              unitType: peasantLevies.id,
              isMilitary: true,
              spawnProvinceId: 'oldWorld|p1',
            ),
          ],
        },
      );
      expect(
        pendingTreasuryCostsForTurn(game, _gp, orders),
        0,
        reason: 'Unaffordable BuildUnitOrder is skipped by the live '
            'resolver and must therefore be skipped by the projection so '
            'AI planners do not subtract phantom treasury costs.',
      );
    });

    test('returns at most the player\'s starting treasury (invariant)', () {
      // Three research orders each costing > treasury/3 — only those that
      // fit the running balance contribute, so the helper never returns
      // more than the player started with.
      final game = _game(treasury: 50);
      final orders = Orders(
        researchOrdersByPlayerId: {
          _gp: [
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
      final spent = pendingTreasuryCostsForTurn(game, _gp, orders);
      expect(spent, lessThanOrEqualTo(50));
    });

    test('deterministic: same inputs return same value across two calls', () {
      final game = _game(treasury: 1000);
      final orders = Orders(
        researchOrdersByPlayerId: {
          _gp: [
            const ResearchOrder(
              slotIndex: 0,
              techId: 'tech',
              funding: ResearchFundingLevel.low,
            ),
          ],
        },
      );
      expect(
        pendingTreasuryCostsForTurn(game, _gp, orders),
        pendingTreasuryCostsForTurn(game, _gp, orders),
      );
    });
  });
}
