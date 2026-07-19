import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/civilian_work_scenario_matrix_fixture.dart';

/// Scenario matrix SC-06-SC-09 for GitHub #2082 / `selectFullAiCivilianWorkOrders`.
/// Split from monolith for #2288; see sibling file for SC-01-SC-05 and regressions.
void main() {
  group('Full AI civilian work #2082 scenario matrix (SC-06-SC-09)', () {
    test('SC-06: two explore rows — pick higher E (province β, 124)', () {
      final alphaTiles = matrixProvinceTiles('pAlpha', 7);
      final betaTiles = matrixProvinceTiles('pBeta', 8);
      final pAlpha = matrixProvinceId('pAlpha');
      final pBeta = matrixProvinceId('pBeta');
      final vis = <String, VisibilityLevel>{
        alphaTiles[0]: VisibilityLevel.unknown,
        alphaTiles[1]: VisibilityLevel.unknown,
        for (var i = 2; i < 7; i++) alphaTiles[i]: VisibilityLevel.fogged,
        for (final t in betaTiles) t: VisibilityLevel.unknown,
      };
      final game = matrixOwGame(
        provinces: [
          matrixTribeProvince('pAlpha'),
          matrixTribeProvince('pBeta'),
        ],
        tilesByProvince: {pAlpha: alphaTiles, pBeta: betaTiles},
      );
      final view = matrixExplorerView(
        game: game,
        locationProvinceId: pAlpha,
        tileKey: alphaTiles[0],
        visibilityByTile: vis,
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          matrixExploreWork(alphaTiles[0]),
          matrixExploreWork(betaTiles[0]),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetExplore);
      expect(r.workOrders.single.targetTileKey, betaTiles[0]);
    });

    test(
      'SC-07b: equal P_score prospects → lexicographically smaller tile',
      () {
        final pOwn = matrixProvinceId('pOwn');
        final tkLo = matrixTileKey('pOwn');
        final tkHi = matrixTileKey('pOwn', 1);
        final game = matrixOwGame(
          provinces: [matrixOwnedProvince('pOwn')],
          tilesByProvince: {
            pOwn: [tkLo, tkHi],
          },
          tribes: const [],
        );
        final view = matrixExplorerView(
          game: game,
          locationProvinceId: pOwn,
          tileKey: tkLo,
          visibilityByTile: {
            tkLo: VisibilityLevel.fullyVisible,
            tkHi: VisibilityLevel.fullyVisible,
          },
        );
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: [
            matrixProspectWork(tkHi),
            matrixProspectWork(tkLo),
          ],
          view: view,
          game: game,
        );
        expect(r.workOrders.single.targetTileKey, tkLo);
      },
    );

    test('SC-08: owned prospect beats minor (57 > 37)', () {
      final pOwn = matrixProvinceId('pOwn');
      final pMin = matrixProvinceId('pMin');
      final tkOwn = matrixTileKey('pOwn');
      final tkMin = matrixTileKey('pMin');
      final game = matrixOwGame(
        provinces: [
          matrixOwnedProvince('pOwn'),
          matrixMinorProvince('pMin'),
        ],
        tilesByProvince: {
          pOwn: [tkOwn],
          pMin: [tkMin],
        },
        tribes: const [],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
      );
      final view = matrixExplorerView(
        game: game,
        locationProvinceId: pOwn,
        tileKey: tkOwn,
        visibilityByTile: {
          tkOwn: VisibilityLevel.fullyVisible,
          tkMin: VisibilityLevel.fullyVisible,
        },
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          matrixProspectWork(tkMin),
          matrixProspectWork(tkOwn),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.targetTileKey, tkOwn);
    });

    test('SC-09: urgent minor prospect beats explore-only (132 > 100)', () {
      final pOwn = matrixProvinceId('pOwn');
      final pTribe = matrixProvinceId('pTr');
      final tkExp = matrixTileKey('pOwn');
      final tkPr = matrixTileKey('pTr');
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['pTr'],
        ],
        terrainGrid: const [
          [TerrainType.swamp],
        ],
      );
      final game = matrixOwGame(
        provinces: [
          matrixOwnedProvince('pOwn'),
          matrixTribeProvince('pTr'),
        ],
        tilesByProvince: {
          pOwn: [tkExp],
          pTribe: [tkPr],
        },
      );
      final view = matrixExplorerView(
        game: game,
        locationProvinceId: pOwn,
        tileKey: tkExp,
        visibilityByTile: {
          tkExp: VisibilityLevel.fullyVisible,
          tkPr: VisibilityLevel.fullyVisible,
        },
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          matrixExploreWork(tkExp),
          matrixProspectWork(tkPr),
        ],
        view: view,
        game: game,
        tileMapByRegion: {matrixOw: tileMap},
      );
      expect(r.workOrders.single.target, kWorkTargetProspect);
      expect(r.workOrders.single.targetTileKey, tkPr);
    });
  });
}
