// Shared fixture for `phase_planner_naval_wiring_planner_*_cases.dart` (Refs #4291).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

const ColonialNavalPlan kPhaseNavalWiringColonialNavalPriority = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

const ColonialLiteNavalPlan kPhaseNavalWiringColonialLiteNavalPriority =
    ColonialLiteNavalPlan(
      priorityNwProvinceIdsSorted: <String>['newWorld|tribe2_b'],
      priorityTargetOwnerFactionIdsSorted: <String>['tribe2'],
    );

class PhaseNavalWiringPlannerFixture {
  PhaseNavalWiringPlannerFixture._({
    required this.game,
    required this.ctx,
    required this.snapshot,
  });

  final Game game;
  final PlannerContext ctx;
  final AIWorldSnapshot snapshot;

  static PhaseNavalWiringPlannerFixture build() {
    final game = Game(
      id: 'g-phase-naval-wiring',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|gp1_1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(
              id: 'newWorld|tribe1_a',
              regionId: 'newWorld',
              ownerId: 'tribe1',
            ),
          ],
        ),
      ),
      players: const [
        Player(
          id: 'gp1',
          displayName: 'P1',
          isHuman: false,
          leaderKey: 'henry',
        ),
      ],
      tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
    );
    const topology = MapTopology(nodes: [], edges: []);
    final ctx = buildTestPlannerContext(
      game: game,
      topology: topology,
      nationId: 'gp1',
      primaryGoal: StrategicGoal.expand,
      config: const AIConfig(
        leaderId: 'henry',
        personalityId: 'henry',
        hiddenAgendaId: 'merchant',
      ),
      suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
        work: [],
        build: [],
        move: [],
        research: [],
        navalMove: [
          NavalMoveOrder(
            fleetId: 'f_nw',
            destinationSeaZoneId: 'newWorld|sea1',
          ),
        ],
        navalMission: [],
      ),
    );
    const snapshot = AIWorldSnapshot(
      playerId: 'gp1',
      threats: ThreatSummary(),
      opportunities: OpportunitySummary(),
      conquest: ConquestSummary(oldWorldProvincesOwned: 1),
      colonial: ColonialSummary(
        invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1_a'],
        adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
      ),
      economy: EconomySummary(),
      relations: {},
    );
    return PhaseNavalWiringPlannerFixture._(
      game: game,
      ctx: ctx,
      snapshot: snapshot,
    );
  }
}
