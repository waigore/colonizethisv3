import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/civilian_work_scenario_matrix_fixture.dart';

/// Scenario matrix SC-01-SC-05 for GitHub #2082 / `selectFullAiCivilianWorkOrders`.
/// Split from monolith for #2288; see sibling files for SC-06-SC-09 and regressions.
void main() {
  group('Full AI civilian work #2082 scenario matrix (SC-01-SC-05)', () {
    test('SC-01: only explore in C(e) → explore (E_score=118)', () {
      final tiles = matrixProvinceTiles('pExp', 7);
      final p = matrixProvinceId('pExp');
      final game = matrixOwGame(
        provinces: [matrixTribeProvince('pExp')],
        tilesByProvince: {p: tiles},
      );
      final view = matrixExplorerView(
        game: game,
        locationProvinceId: p,
        tileKey: tiles[0],
        visibilityByTile: matrixExploreVisibility(tiles),
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [matrixExploreWork(tiles[0])],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetExplore);
      expect(r.workOrders.single.targetTileKey, tiles[0]);
      expect(r.idleEvents, isEmpty);
    });

    test('SC-02: only prospect in C(e) → prospect (P_score=57)', () {
      final p = matrixProvinceId('pOwn');
      final tk = matrixTileKey('pOwn');
      final game = matrixOwGame(
        provinces: [matrixOwnedProvince('pOwn')],
        tilesByProvince: {
          p: [tk],
        },
        tribes: const [],
      );
      final view = matrixExplorerView(
        game: game,
        locationProvinceId: p,
        tileKey: tk,
        visibilityByTile: {tk: VisibilityLevel.fullyVisible},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [matrixProspectWork(tk)],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetProspect);
      expect(r.workOrders.single.targetTileKey, tk);
    });

    test('SC-03: explore beats weaker prospect (118 > 57)', () {
      final expTiles = matrixProvinceTiles('pExp', 7);
      final pExp = matrixProvinceId('pExp');
      final pOwn = matrixProvinceId('pOwn');
      final ownTk = matrixTileKey('pOwn');
      final game = matrixOwGame(
        provinces: [
          matrixTribeProvince('pExp'),
          matrixOwnedProvince('pOwn'),
        ],
        tilesByProvince: {
          pExp: expTiles,
          pOwn: [ownTk],
        },
      );
      final view = matrixExplorerView(
        game: game,
        locationProvinceId: pExp,
        tileKey: expTiles[0],
        visibilityByTile: matrixExploreVisibility(
          expTiles,
          extra: {ownTk: VisibilityLevel.fullyVisible},
        ),
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          matrixExploreWork(expTiles[0]),
          matrixProspectWork(ownTk),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetExplore);
    });

    test('SC-04: strong prospect beats explore (152 > 100)', () {
      final pExp = matrixProvinceId('pExp');
      final pOwn = matrixProvinceId('pOwn');
      final expTk = matrixTileKey('pExp');
      final ownTk = matrixTileKey('pOwn');
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['pOwn'],
        ],
        terrainGrid: const [
          [TerrainType.hills],
        ],
      );
      final game = matrixOwGame(
        provinces: [
          matrixTribeProvince('pExp'),
          matrixOwnedProvince('pOwn'),
        ],
        tilesByProvince: {
          pExp: [expTk],
          pOwn: [ownTk],
        },
      );
      final view = matrixExplorerView(
        game: game,
        locationProvinceId: pExp,
        tileKey: expTk,
        visibilityByTile: {
          expTk: VisibilityLevel.fullyVisible,
          ownTk: VisibilityLevel.fullyVisible,
        },
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          matrixExploreWork(expTk),
          matrixProspectWork(ownTk),
        ],
        view: view,
        game: game,
        tileMapByRegion: {matrixOw: tileMap},
      );
      expect(r.workOrders.single.target, kWorkTargetProspect);
      expect(r.workOrders.single.targetTileKey, ownTk);
    });

    test('SC-05: two prospect rows — pick higher P (tile B, 140)', () {
      final expTiles = matrixProvinceTiles('pExp', 7);
      final pExp = matrixProvinceId('pExp');
      final pA = matrixProvinceId('pA');
      final pB = matrixProvinceId('pB');
      final tileA = matrixTileKey('pA');
      final tileB = matrixTileKey('pB', 1);
      final tileMap = TileMapResult(
        width: 2,
        height: 1,
        grid: const [
          ['pA', 'pB'],
        ],
        terrainGrid: const [
          [TerrainType.plains, TerrainType.hills],
        ],
      );
      final game = matrixOwGame(
        provinces: [
          matrixTribeProvince('pExp'),
          matrixOwnedProvince('pA'),
          matrixMinorProvince('pB'),
        ],
        tilesByProvince: {
          pExp: expTiles,
          pA: [tileA],
          pB: [tileB],
        },
        purchasedTilesByTileKey: {tileB: matrixPlayerId},
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
      );
      final view = matrixExplorerView(
        game: game,
        locationProvinceId: pExp,
        tileKey: expTiles[0],
        visibilityByTile: matrixExploreVisibility(
          expTiles,
          extra: {
            tileA: VisibilityLevel.fullyVisible,
            tileB: VisibilityLevel.fullyVisible,
          },
        ),
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          matrixExploreWork(expTiles[0]),
          matrixProspectWork(tileA),
          matrixProspectWork(tileB),
        ],
        view: view,
        game: game,
        tileMapByRegion: {matrixOw: tileMap},
      );
      expect(r.workOrders.single.target, kWorkTargetProspect);
      expect(r.workOrders.single.targetTileKey, tileB);
    });
  });
}
