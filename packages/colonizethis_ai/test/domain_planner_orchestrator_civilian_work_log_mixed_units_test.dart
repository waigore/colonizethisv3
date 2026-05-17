import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'domain_planner_test_fake_api.dart';

void main() {
  group('runDomainPlanners civilian work logging — mixed unit types', () {
    test(
      'tech_thief: spy work present still assigns Explorer work (per-unit, '
      'Refs #2082)',
      () {
        const nationId = 'gp1';
        const ow = 'oldWorld';
        const provinceId = '$ow|p1';
        const tileSpy = '$ow|p1|0|0';
        const tileExp = '$ow|p1|1|0';
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
                  id: 's1',
                  type: kUnitTypeSpy,
                  ownerId: nationId,
                  locationProvinceId: provinceId,
                  tileKey: tileSpy,
                ),
                Unit(
                  id: 'e1',
                  type: kUnitTypeExplorer,
                  ownerId: nationId,
                  locationProvinceId: provinceId,
                  tileKey: tileExp,
                ),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              nationId: {
                tileSpy: 'fullyVisible',
                tileExp: 'fullyVisible',
              },
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                provinceId: [tileSpy, tileExp],
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
          hiddenAgendaId: 'tech_thief',
        );
        final seeds = AISeedBundle.fromTurnSeed(20823);
        const spyWork = WorkOrder(
          unitId: 's1',
          target: kWorkTargetStealTech,
          targetTileKey: tileSpy,
        );
        const exploreWork = WorkOrder(
          unitId: 'e1',
          target: kWorkTargetExplore,
          targetTileKey: tileExp,
        );
        const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [spyWork, exploreWork],
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
          primaryGoal: StrategicGoal.expand,
          seeds: seeds,
          suggestionAPI: fakeApi,
          economyPlan: economyPlan,
        );

        final workList = orders.workOrdersByPlayerId[nationId] ?? const [];
        expect(workList, hasLength(2));
        expect(
          workList.map((w) => w.unitId).toSet(),
          {'s1', 'e1'},
        );
      },
    );

    test(
      'mixed idle + assigned: K civilian_work_assigned and N civilian_work_idle',
      () {
        const nationId = 'gp1';
        const ow = 'oldWorld';
        const provinceId = '$ow|p1';
        const tileA = '$ow|p1|0|0';
        const tileB = '$ow|p1|1|0';
        const tileC = '$ow|p1|0|1';
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
                  tileKey: tileA,
                ),
                Unit(
                  id: 'e2',
                  type: kUnitTypeExplorer,
                  ownerId: nationId,
                  locationProvinceId: provinceId,
                  tileKey: tileB,
                ),
                Unit(
                  id: 'b1',
                  type: kUnitTypeBuilder,
                  ownerId: nationId,
                  locationProvinceId: provinceId,
                  tileKey: tileC,
                ),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              nationId: {
                tileA: 'fullyVisible',
                tileB: 'fullyVisible',
                tileC: 'fullyVisible',
              },
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                provinceId: [tileA, tileB, tileC],
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
        final seeds = AISeedBundle.fromTurnSeed(20824);
        const workOrder = WorkOrder(
          unitId: 'e1',
          target: kWorkTargetExplore,
          targetTileKey: tileA,
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
        final idle = captured
            .where((e) => e.message.contains('civilian_work_idle'))
            .toList();
        expect(assigned, hasLength(1));
        expect(idle, hasLength(2));
        expect(idle.any((e) => e.message.contains('unitId=e2')), isTrue);
        expect(idle.any((e) => e.message.contains('unitId=b1')), isTrue);

        final unitIdPattern = RegExp(r'unitId=([A-Za-z0-9_-]+)');
        final idsFromMessages = <String>{
          for (final e in [...assigned, ...idle])
            ...unitIdPattern.allMatches(e.message).map((m) => m.group(1)!),
        };
        expect(idsFromMessages, {'e1', 'e2', 'b1'});
      },
    );
  });
}
