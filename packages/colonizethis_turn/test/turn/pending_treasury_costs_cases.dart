// Shared fixtures for pending_treasury_costs_test (Refs #4252 slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const pendingTreasuryGp = 'gp1';

Game pendingTreasuryGame({
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
        id: pendingTreasuryGp,
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

typedef PendingTreasuryScenario = ({
  Game game,
  Orders orders,
  int expected,
  String? reason,
});

PendingTreasuryScenario pendingTreasuryResearchRecruitWorkScenario() {
  const apprentice = WorkerTier.apprentice;
  final apprenticeRow = WorkerActionEconomyCatalog.forTier(apprentice);
  final game = pendingTreasuryGame(
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
      pendingTreasuryGp: [
        const ResearchOrder(
          slotIndex: 0,
          techId: 'tech',
          funding: ResearchFundingLevel.low,
        ),
      ],
    },
    recruitWorkerOrdersByPlayerId: {
      pendingTreasuryGp: [
        RecruitWorkerOrder(targetTier: apprentice),
      ],
    },
    workOrdersByPlayerId: {
      pendingTreasuryGp: [
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
  return (
    game: game,
    orders: orders,
    expected: expected,
    reason: 'WorkOrder pending costs are stockpile-only and must not '
        'contribute to the treasury projection.',
  );
}

PendingTreasuryScenario pendingTreasuryFullAggregateScenario() {
  const apprentice = WorkerTier.apprentice;
  final apprenticeRow = WorkerActionEconomyCatalog.forTier(apprentice);
  final peasantLevies = RegimentEconomyCatalog.peasantLevies;
  final fundingLevel = ResearchFundingLevel.low;
  final game = pendingTreasuryGame(
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
      pendingTreasuryGp: [
        ResearchOrder(
          slotIndex: 0,
          techId: 'tech',
          funding: fundingLevel,
        ),
      ],
    },
    recruitWorkerOrdersByPlayerId: {
      pendingTreasuryGp: [
        RecruitWorkerOrder(targetTier: apprentice),
      ],
    },
    buildUnitOrdersByPlayerId: {
      pendingTreasuryGp: [
        BuildUnitOrder(
          unitType: peasantLevies.id,
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        ),
      ],
    },
    workOrdersByPlayerId: {
      pendingTreasuryGp: [
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
  return (
    game: game,
    orders: orders,
    expected: expected,
    reason: 'Pending Research + RecruitWorker + BuildUnit treasury '
        'costs must sum exactly (L + C_r + C_b). WorkOrder material '
        'costs are stockpile-only and must not contribute.',
  );
}

PendingTreasuryScenario pendingTreasuryBuildUnitSkippedScenario() {
  final peasantLevies = RegimentEconomyCatalog.peasantLevies;
  final game = pendingTreasuryGame(
    treasury: 100000,
    stockpile: Stockpile(quantities: {
      for (final e in peasantLevies.buildInputs.entries) e.key: e.value,
    }),
    workerPool: const WorkerPool(peasants: 0),
  );
  final orders = Orders(
    buildUnitOrdersByPlayerId: {
      pendingTreasuryGp: [
        BuildUnitOrder(
          unitType: peasantLevies.id,
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        ),
      ],
    },
  );
  return (
    game: game,
    orders: orders,
    expected: 0,
    reason: 'Unaffordable BuildUnitOrder is skipped by the live '
        'resolver and must therefore be skipped by the projection so '
        'AI planners do not subtract phantom treasury costs.',
  );
}
