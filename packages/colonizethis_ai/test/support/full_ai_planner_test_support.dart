// Shared Game fixtures for Full AI planner pins (Refs #4310 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Minimal empty-world Game for Full AI contract pins.
Game fullAiPlannerMinimalGame({
  required List<Player> players,
  Map<String, bool> aiControlByGpId = const {},
  Map<String, String> hiddenAgendaByGpId = const {},
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(provinces: [], units: []),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: players,
    aiControlByGpId: aiControlByGpId,
    hiddenAgendaByGpId: hiddenAgendaByGpId,
  );
}

/// Non-trivial two-GP Game for Full AI determinism pins (Refs #2509).
Game fullAiPlannerDeterminismScenarioGame() {
  return Game(
    id: 'g-full-ai-determinism',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: const RegionData(provinces: [], units: []),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: false,
        leaderKey: 'victoria',
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 20)
            .applyDelta(CommodityCatalog.timber.id, 20)
            .applyDelta(CommodityCatalog.iron.id, 20)
            .applyDelta(CommodityCatalog.coal.id, 10),
        workerPool: const WorkerPool(peasants: 12),
      ),
      const Player(
        id: 'gp2',
        displayName: 'France',
        isHuman: false,
        leaderKey: 'napoleon',
      ),
    ],
    aiControlByGpId: const {'gp1': true, 'gp2': true},
    hiddenAgendaByGpId: const {'gp1': 'peacemaker', 'gp2': 'warmonger'},
    globalGameSeed: 42,
  );
}

void expectFullAiEconomyPlansEqual(EconomyPlan a, EconomyPlan b) {
  expect(a.cargoPreference, b.cargoPreference,
      reason: 'cargoPreference must be deterministic');
  expect(
    a.productionAssignments.length,
    b.productionAssignments.length,
    reason: 'productionAssignments count must be deterministic',
  );
  for (var i = 0; i < a.productionAssignments.length; i++) {
    expect(
      a.productionAssignments[i].recipeId,
      b.productionAssignments[i].recipeId,
      reason: 'recipeId at index $i must be deterministic',
    );
    expect(
      a.productionAssignments[i].assignedLabour,
      b.productionAssignments[i].assignedLabour,
      reason: 'assignedLabour at index $i must be deterministic',
    );
  }
  expect(a.tradeOrders, b.tradeOrders,
      reason: 'tradeOrders must be deterministic');
}
