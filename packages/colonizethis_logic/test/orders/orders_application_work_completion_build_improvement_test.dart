import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';


void main() {
  group('applyBuildAndWorkOrders work completion (build improvement)', () {
    const ow = 'oldWorld';
    const tileKey = 'oldWorld|P1|0|0';
    const provinceId = 'oldWorld|P1';

    // Non-empty orders so applyBuildAndWorkOrders does not return early (empty build list still counts).
    Orders ordersToTriggerProcessWork() =>
        Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]});

    test(
      'build_improvement completion increases improvement level and clears currentWork',
      () {
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildImprovement,
            tileKey: tileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        expect(next.worldState.tileState.improvementLevel(tileKey), 1);
        final after = next.worldState.oldWorld.units.single;
        expect(after.tileKey, tileKey);
        expect(after.originTileKey, isNull);
        expect(after.assignedTileKey, isNull);
      },
    );

    test(
      'build_improvement completion sets envy mirror hint for human on extraction tile',
      () {
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildImprovement,
            tileKey: tileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKey: 'grain'},
            tileState: tileState,
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        expect(next.lastHumanCompletedResearchCategory, 'gathering');
        expect(next.lastHumanResearchCategoryCompletionTurn, 2);
      },
    );

    test(
      'build_improvement completion adds envy evidence when AI mirrors human gathering hint',
      () {
        const aiId = 'ai1';
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: aiId,
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildImprovement,
            tileKey: tileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: aiId),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKey: 'coal'},
            tileState: tileState,
          ),
          players: const [
            Player(id: 'human', displayName: 'H', isHuman: true),
            Player(id: aiId, displayName: 'AI', isHuman: false),
          ],
          aiControlByGpId: const {aiId: true},
          lastHumanCompletedResearchCategory: 'gathering',
          lastHumanResearchCategoryCompletionTurn: 0,
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        final envy = next.dossierEvidenceEntries
            .where((e) => e.agendaType == 'envy')
            .toList();
        expect(envy, isNotEmpty);
        expect(envy.single.subjectId, aiId);
        expect(envy.single.scoreDelta, 1);
      },
    );

    test(
      'build_improvement completion raises stored level from 3 to 4 (global max)',
      () {
        final tileState = TileMapState().setImprovement(tileKey, 3);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildImprovement,
            tileKey: tileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKey: 'grain'},
            tileState: tileState,
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        expect(next.worldState.tileState.improvementLevel(tileKey), 4);
      },
    );

    test(
      'build_improvement completion does not re-apply extraction tech cap (#1291)',
      () {
        // Assign-time would reject 3→4 with extraction cap 2; completion still applies +1 to stored level.
        expect(
          extractionCapForResourceForUnlocked(const {
            kTechIdSawMill: true,
          }, 'grain'),
          1,
        );
        final tileState = TileMapState().setImprovement(tileKey, 3);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildImprovement,
            tileKey: tileKey,
            totalTurns: 1,
            remainingTurns: 1,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKey: 'grain'},
            tileState: tileState,
          ),
          players: const [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              techUnlocked: {kTechIdSawMill: true},
            ),
          ],
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        expect(next.worldState.tileState.improvementLevel(tileKey), 4);
      },
    );

    test(
      'work cancelled when province containing target tile is conquered (#376)',
      () {
        // Unit p1 is working on a tile in P1; province P1 is conquered by p2.
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          originTileKey: 'oldWorld|P1|1|0',
          assignedTileKey: tileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetBuildImprovement,
            tileKey: tileKey,
            totalTurns: 2,
            remainingTurns: 2,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              // Province owned by p2 (conquered); unit still belongs to p1.
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p2'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: true),
          ],
        );
        final next = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        final uAfter = next.worldState.oldWorld.units.single;
        expect(uAfter.status, UnitStatus.idle);
        expect(uAfter.currentWork, isNull);
        expect(uAfter.tileKey, 'oldWorld|P1|1|0');
        expect(uAfter.originTileKey, isNull);
        expect(uAfter.assignedTileKey, isNull);
        // Improvement not applied (work was cancelled).
        expect(next.worldState.tileState.improvementLevel(tileKey), 0);
      },
    );

    test(
      'multi-turn work decrements remainingTurns and completes only when zero',
      () {
        final tileState = TileMapState().setImprovement(tileKey, 0);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeBuilder,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
          status: UnitStatus.working,
          currentWork: CurrentWork(
            workTarget: kWorkTargetBuildImprovement,
            tileKey: tileKey,
            totalTurns: 2,
            remainingTurns: 2,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final afterFirst = applyBuildAndWorkOrders(
          game,
          ordersToTriggerProcessWork(),
        );
        expect(afterFirst.worldState.tileState.improvementLevel(tileKey), 0);
        final uAfterFirst = afterFirst.worldState.oldWorld.units.single;
        expect(uAfterFirst.currentWork!.remainingTurns, 1);
        final afterSecond = applyBuildAndWorkOrders(
          afterFirst,
          ordersToTriggerProcessWork(),
        );
        expect(afterSecond.worldState.tileState.improvementLevel(tileKey), 1);
      },
    );
  });
}
