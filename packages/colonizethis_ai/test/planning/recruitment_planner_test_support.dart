// Shared fixtures for recruitment planner pins (Refs #4104 Slice A/C).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';

const recruitmentPlannerTestConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

const recruitmentPlannerTestTopology = MapTopology(nodes: [], edges: []);

OrderSuggestionAPI recruitmentPlannerFakeApi({
  List<RecruitWorkerOrder> recruit = const [],
  List<BuildUnitOrder> build = const [],
}) {
  return FakeOrderSuggestionAPIForDomainPlannerTests(
    work: const [],
    build: build,
    move: const [],
    research: const [],
    navalMove: const [],
    navalMission: const [],
    recruitWorker: recruit,
  );
}

Game recruitmentPlannerTestGameWith(Player player) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [], units: []),
    newWorld: RegionData(provinces: [], units: []),
  ),
  players: [player],
);
