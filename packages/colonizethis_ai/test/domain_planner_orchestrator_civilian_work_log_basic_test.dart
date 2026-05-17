import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'domain_planner_test_fake_api.dart';

void main() {
  group('runDomainPlanners civilian work logging — basic', () {
    test('one civilian_work_assigned info line per emitted WorkOrder', () {
      const nationId = 'gp1';
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      const tileKey = '$ow|p1|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: provinceId, regionId: ow, ownerId: nationId),
            ],
            units: [
              Unit(
                id: 'e1',
                type: kUnitTypeExplorer,
                ownerId: nationId,
                locationProvinceId: provinceId,
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            nationId: {tileKey: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              provinceId: [tileKey],
            },
          },
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
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(20821);
      const workOrder = WorkOrder(
        unitId: 'e1',
        target: kWorkTargetExplore,
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

      final captured = <LogEvent>[];
      void listener(LogEvent e) => captured.add(e);
      Logger.addLogListener(listener);
      Logger.level = Level.info;
      try {
        runDomainPlanners(
          game: game,
          topology: topology,
          nationId: nationId,
          view: view,
          snapshot: snapshot,
          config: config,
          primaryGoal: StrategicGoal.expand,
          seeds: seeds,
          suggestionAPI: fakeApi,
          economyPlan: economyPlan,
        );
      } finally {
        Logger.removeLogListener(listener);
        Logger.level = Level.info;
      }

      final assigned = captured
          .where((e) => e.message.contains('civilian_work_assigned'))
          .toList();
      expect(assigned, hasLength(1));
      expect(assigned.single.message, contains('unitId=e1'));
      expect(assigned.single.message, contains('unitType=Explorer'));
      expect(assigned.single.message, contains('target=explore'));
    });

    test('civilian_work_idle when explorer has no work suggestions', () {
      const nationId = 'gp1';
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      const tileKey = '$ow|p1|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: provinceId, regionId: ow, ownerId: nationId),
            ],
            units: [
              Unit(
                id: 'e1',
                type: kUnitTypeExplorer,
                ownerId: nationId,
                locationProvinceId: provinceId,
                tileKey: tileKey,
              ),
              Unit(
                id: 'e2',
                type: kUnitTypeExplorer,
                ownerId: nationId,
                locationProvinceId: provinceId,
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            nationId: {tileKey: 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              provinceId: [tileKey],
            },
          },
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
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(20822);
      const workOrder = WorkOrder(
        unitId: 'e1',
        target: kWorkTargetExplore,
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

      final captured = <LogEvent>[];
      void listener(LogEvent e) => captured.add(e);
      Logger.addLogListener(listener);
      Logger.level = Level.info;
      try {
        runDomainPlanners(
          game: game,
          topology: topology,
          nationId: nationId,
          view: view,
          snapshot: snapshot,
          config: config,
          primaryGoal: StrategicGoal.expand,
          seeds: seeds,
          suggestionAPI: fakeApi,
          economyPlan: economyPlan,
        );
      } finally {
        Logger.removeLogListener(listener);
        Logger.level = Level.info;
      }

      final idleLines = captured
          .where((e) => e.message.contains('civilian_work_idle'))
          .map((e) => e.message)
          .toList();
      expect(idleLines, hasLength(1));
      expect(idleLines.single, contains('unitId=e2'));
      expect(idleLines.single, contains('reason=no_suggestions'));

      final assigned = captured
          .where((e) => e.message.contains('civilian_work_assigned'))
          .toList();
      expect(assigned, hasLength(1));
    });
  });
}
