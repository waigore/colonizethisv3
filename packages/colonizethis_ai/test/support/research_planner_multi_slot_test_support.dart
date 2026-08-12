// Shared Game / API fixtures for research-planner multi-slot pins
// (Refs #4310 Slice C).

import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_ai/src/planning/research_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

const String researchPlannerMultiSlotPlayerId = 'gp1';
const MapTopology researchPlannerMultiSlotTopology =
    MapTopology(nodes: [], edges: []);

Game researchPlannerMultiSlotGameWith({
  required int treasury,
  Map<String, int>? progress,
  int researchSlots = 3,
}) =>
    Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [
        Player(
          id: researchPlannerMultiSlotPlayerId,
          displayName: 'GP',
          isHuman: false,
          leaderKey: 'victoria',
          treasury: treasury,
          researchSlots: researchSlots,
          researchProgressByTechId: progress,
        ),
      ],
    );

FakeOrderSuggestionAPIForDomainPlannerTests researchPlannerMultiSlotApiWith(
  List<ResearchOrder> research,
) =>
    FakeOrderSuggestionAPIForDomainPlannerTests(
      work: const [],
      build: const [],
      move: const [],
      research: research,
      navalMove: const [],
      navalMission: const [],
    );

ResearchOrder researchPlannerMultiSlotRo(int slot, String tech) =>
    ResearchOrder(
      slotIndex: slot,
      techId: tech,
      funding: ResearchFundingLevel.medium,
    );

/// Player view owning [ownedOldWorldProvinces] Old World provinces, used to
/// drive the stalled-expansion cap (`isStalledOldWorldExpansion`): 1..9 owned
/// is stalled, 0 owned is terminal collapse (not stalled). Refs #3472.
PlayerView researchPlannerMultiSlotViewOwning(
  Game game,
  int ownedOldWorldProvinces,
) {
  final provincesById = <String, Province>{};
  for (var i = 0; i < ownedOldWorldProvinces; i++) {
    final id = ProvinceId.full(kOldWorldRegionId, 'p$i');
    provincesById[id] = Province(
      id: id,
      regionId: kOldWorldRegionId,
      ownerId: researchPlannerMultiSlotPlayerId,
    );
  }
  return PlayerView(
    playerId: researchPlannerMultiSlotPlayerId,
    player: game.players.single,
    ownUnitsById: const {},
    provincesById: provincesById,
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

List<ResearchOrder> researchPlannerMultiSlotRunFor({
  required Game game,
  required FakeOrderSuggestionAPIForDomainPlannerTests api,
  StrategicGoal primaryGoal = StrategicGoal.expand,
  AIConfig config = kTestAiConfig,
  PlayerView? view,
}) {
  final ctx = buildTestPlannerContext(
    game: game,
    topology: researchPlannerMultiSlotTopology,
    primaryGoal: primaryGoal,
    config: config,
    suggestionAPI: api,
    view: view,
  );
  final orders = runResearchPlanner(ctx: ctx);
  return orders.researchOrdersByPlayerId[researchPlannerMultiSlotPlayerId] ??
      const <ResearchOrder>[];
}

ResearchPlannerResult researchPlannerMultiSlotDecisionFor({
  required Game game,
  required FakeOrderSuggestionAPIForDomainPlannerTests api,
  StrategicGoal primaryGoal = StrategicGoal.expand,
  AIConfig config = kTestAiConfig,
  PlayerView? view,
}) {
  final ctx = buildTestPlannerContext(
    game: game,
    topology: researchPlannerMultiSlotTopology,
    primaryGoal: primaryGoal,
    config: config,
    suggestionAPI: api,
    view: view,
  );
  return runResearchPlannerWithDecision(ctx: ctx);
}
