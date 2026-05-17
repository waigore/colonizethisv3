import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

/// Colonial civilian work through [runDomainPlanners] (Refs #2509).
void main() {
  group('runDomainPlanners colonial civilian work', () {
    test(
      'colonial pressure emits build_improvement when work is suggested',
      () {
        const nationId = 'gp1';
        const nwProvince = 'newWorld|p1';
        const tileKey = '$nwProvince|0|0';
        final game = Game(
          id: 'g-colonial-work',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
          conquest: const ConquestSummary(oldWorldProvincesOwned: 12),
          colonial: const ColonialSummary(
            newWorldProvincesOwned: 1,
            invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1'],
          ),
          economy: const EconomySummary(ownProvinceCount: 5),
          relations: const {},
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
          game: game,
          topology: topology,
          nationId: nationId,
          view: view,
          snapshot: snapshot,
          config: config,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: AISeedBundle.fromTurnSeed(25091),
          suggestionAPI: fakeApi,
          economyPlan: economyPlan,
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
