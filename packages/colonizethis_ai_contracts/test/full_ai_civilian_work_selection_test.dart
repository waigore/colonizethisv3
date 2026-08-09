import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/civilian_work_selection_fixture.dart';

void main() {
  group('selectFullAiCivilianWorkOrders', () {
    test(
      'non-Explorer picks lexicographically smallest (target, targetTileKey)',
      () {
        final game = civilianWorkSelectionGame();
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: const [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildRoad,
              targetTileKey: 'oldWorld|p1|1|0',
            ),
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
          view: civilianWorkSelectionView(
            game: game,
            unitId: 'b1',
            unitType: kUnitTypeBuilder,
          ),
          game: game,
        );
        expect(r.workOrders, hasLength(1));
        expect(r.workOrders.single.target, kWorkTargetBuildImprovement);
        expect(r.idleEvents, isEmpty);
      },
    );

    test(
      'Builder prefers unimproved resource tile over lexicographically smaller road',
      () {
        const tileRoad = 'oldWorld|p1|0|0';
        const tileResource = 'oldWorld|p1|1|0';
        final game = civilianWorkSelectionGame(
          resourceByTileKey: {tileResource: 'grain'},
        );
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: const [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildRoad,
              targetTileKey: tileRoad,
            ),
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileResource,
            ),
          ],
          view: civilianWorkSelectionView(
            game: game,
            unitId: 'b1',
            unitType: kUnitTypeBuilder,
          ),
          game: game,
        );
        expect(r.workOrders.single.targetTileKey, tileResource);
      },
    );

    test(
      'Explorer with two equal E_score explores picks lexicographically smaller tile',
      () {
        const ow = 'oldWorld';
        const pA = '$ow|pA';
        const pB = '$ow|pB';
        const tileB = 'oldWorld|pB|0|0';
        const tileA = 'oldWorld|pA|0|0';
        final game = civilianWorkSelectionGame(
          oldWorld: RegionData(
            provinces: [
              Province(id: pA, regionId: ow, ownerId: 'tribe1'),
              Province(id: pB, regionId: ow, ownerId: 'tribe1'),
            ],
            units: const [],
          ),
          playerVisibilityByTile: const {
            'gp1': {tileA: 'unknown', tileB: 'unknown'},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              pA: [tileA],
              pB: [tileB],
            },
          },
          tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
        );
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: [
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: tileB,
            ),
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: tileA,
            ),
          ],
          view: civilianWorkSelectionView(
            game: game,
            unitId: 'e1',
            unitType: kUnitTypeExplorer,
            locationProvinceId: pA,
            tileKey: tileA,
            visibilityByTile: const {
              tileA: VisibilityLevel.unknown,
              tileB: VisibilityLevel.unknown,
            },
          ),
          game: game,
        );
        expect(r.workOrders.single.targetTileKey, tileA);
        expect(r.idleEvents, isEmpty);
      },
    );

    test(
      'idle Explorer with empty explore/prospect suggestions logs no_suggestions',
      () {
        final game = civilianWorkSelectionGame();
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: const [],
          view: civilianWorkSelectionView(
            game: game,
            unitId: 'e1',
            unitType: kUnitTypeExplorer,
          ),
          game: game,
        );
        expect(r.workOrders, isEmpty);
        expect(r.idleEvents, hasLength(1));
        expect(r.idleEvents.single.unitId, 'e1');
        expect(r.idleEvents.single.reason, 'no_suggestions');
      },
    );
  });

  group('growth-stage feedstock build routing (Refs #3371 AC1/AC2)', () {
    const grainTile = 'oldWorld|p1|0|0';
    const woolTile = 'oldWorld|p1|1|0';
    const timberTile = 'oldWorld|p1|2|0';

    const grainSuggestion = WorkOrder(
      unitId: 'b1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: grainTile,
    );
    const woolSuggestion = WorkOrder(
      unitId: 'b1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: woolTile,
    );
    const timberSuggestion = WorkOrder(
      unitId: 'b1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: timberTile,
    );

    FullAiCivilianWorkSelectionResult selectOn(
      Map<String, String> resources, {
      Set<String> fabric = const {},
      Set<String> infra = const {},
      required List<WorkOrder> suggestions,
    }) {
      final game = civilianWorkSelectionGame(resourceByTileKey: resources);
      return selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: civilianWorkSelectionView(
          game: game,
          unitId: 'b1',
          unitType: kUnitTypeBuilder,
        ),
        game: game,
        growthStageFabricFeedstockResourceIds: fabric,
        growthStageInfraFeedstockResourceIds: infra,
      );
    }

    test('negative: without growth-stage sets, lex-first grain tile wins', () {
      final r = selectOn(
        {grainTile: 'grain', woolTile: 'wool'},
        suggestions: const [grainSuggestion, woolSuggestion],
      );
      expect(r.workOrders.single.targetTileKey, grainTile);
    });

    test('positive: fabric feedstock set routes Builder to wool over grain', () {
      final r = selectOn(
        {grainTile: 'grain', woolTile: 'wool'},
        fabric: const {'wool', 'cotton'},
        suggestions: const [grainSuggestion, woolSuggestion],
      );
      expect(r.workOrders.single.targetTileKey, woolTile);
    });

    test('positive: fabric feedstock outranks infrastructure feedstock', () {
      final r = selectOn(
        {woolTile: 'wool', timberTile: 'timber'},
        fabric: const {'wool', 'cotton'},
        infra: const {'timber', 'iron', 'coal'},
        suggestions: const [timberSuggestion, woolSuggestion],
      );
      expect(r.workOrders.single.targetTileKey, woolTile);
    });

    test('positive: infrastructure feedstock set routes Builder to timber', () {
      final r = selectOn(
        {grainTile: 'grain', timberTile: 'timber'},
        infra: const {'timber', 'iron', 'coal'},
        suggestions: const [grainSuggestion, timberSuggestion],
      );
      expect(r.workOrders.single.targetTileKey, timberTile);
    });
  });
}
