import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';

/// Colonial civilian work through [runDomainPlanners] (Refs #2509).

void registerDomainPlannerOrchestratorColonialCivilianWorkTailCases() {

  group('runDomainPlanners colonial civilian work', () {
    test(
      'DEVELOP phase emits build_improvement when work is suggested',
      () {
        const nationId = 'gp1';
        const nwProvince = 'newWorld|p1';
        const tileKey = '$nwProvince|0|0';
        final game = Game(
          id: 'g-develop-work',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 140),
            oldWorld: const RegionData(),
            newWorld: RegionData(
              provinces: [
                Province(
                  id: nwProvince,
                  regionId: kNewWorldRegionId,
                  ownerId: nationId,
                ),
              ],
              units: [
                Unit(
                  id: 'b1',
                  type: kUnitTypeBuilder,
                  ownerId: nationId,
                  locationProvinceId: nwProvince,
                  tileKey: tileKey,
                ),
              ],
            ),
            playerVisibilityByTile: const {
              nationId: {tileKey: 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: const {
              kNewWorldRegionId: {
                nwProvince: [tileKey],
              },
            },
            resourceByTileKey: const {tileKey: 'grain'},
          ),
          players: const [
            Player(
              id: nationId,
              displayName: 'GP',
              isHuman: false,
              leaderKey: 'victoria',
            ),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, nationId);
        final snapshot = AIWorldSnapshot(
          playerId: nationId,
          threats: const ThreatSummary(),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(oldWorldProvincesOwned: 11),
          colonial: const ColonialSummary(newWorldProvincesOwned: 2),
          economy: const EconomySummary(ownProvinceCount: 5),
          relations: const {},
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.develop,
        );
        const config = AIConfig(
          leaderId: 'victoria',
          personalityId: 'victoria',
          hiddenAgendaId: 'peacemaker',
        );
        const workOrder = WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileKey,
        );
        const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [workOrder],
          build: const [],
          move: const [],
          research: const [],
          navalMove: const [],
          navalMission: const [],
        );
        const economyPlan = EconomyPlan(
          productionAssignments: [],
          cargoPreference: CargoPreference.none,
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: nationId,
            view: view,
            snapshot: snapshot,
            config: config,
            primaryGoal: StrategicGoal.diplomacy,
            seeds: AISeedBundle.fromTurnSeed(25093),
            suggestionAPI: fakeApi,
            economyPlan: economyPlan,
          ),
        );

        final work = orders.workOrdersByPlayerId[nationId] ?? [];
        expect(
          work.where((w) => w.target == kWorkTargetBuildImprovement),
          isNotEmpty,
        );
        expect(work.single.targetTileKey, tileKey);
      },
    );
  });
}
