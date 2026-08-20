import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';
import 'support/init_game_map_view_region_cells_scenarios.dart';
import 'support/init_game_map_view_region_cells_presence_scenarios.dart';
import 'support/init_game_map_view_region_cells_slice_scenarios.dart';

void main() {
  group('buildInitGameMapViewData region data', () {
    test('returns InitGameMapViewData with oldWorld and newWorld regions', () {
      final viewData = regionCellsBasicDualRegionView();

      expect(viewData.oldWorld.regionId, 'oldWorld');
      expect(viewData.newWorld.regionId, 'newWorld');
      expect(viewData.oldWorld.width, 2);
      expect(viewData.oldWorld.height, 2);
      expect(viewData.oldWorld.cells.length, 4);
      expect(viewData.oldWorld.cells[0].regionCellId, 'p1');
      expect(viewData.oldWorld.cells[0].isSea, false);
      expect(viewData.oldWorld.cells[1].regionCellId, 's1');
      expect(viewData.oldWorld.cells[1].isSea, true);
      expect(viewData.oldWorld.factionColors, isNotEmpty);
      expect(viewData.oldWorld.greatPowerFactionIds, {'gp1'});
      expect(viewData.newWorld.greatPowerFactionIds, {'gp1'});
      expect(
        viewData.oldWorld.provincePoliticalOwnerByPrefixedProvinceId['oldWorld|p1'],
        'gp1',
      );
      expect(
        viewData.newWorld.provincePoliticalOwnerByPrefixedProvinceId['newWorld|p1'],
        isNull,
      );
      expect(viewData.newWorld.cells.length, 4);
    });

    test(
      'copies seaZoneDisplayNameById into RegionMapViewData.seaZoneDisplayNameByPrefixedId',
      () {
        final viewData = regionCellsSeaZoneDisplayNameView();

        expect(
          viewData.oldWorld.seaZoneDisplayNameByPrefixedId['oldWorld|s1'],
          'Adriatic Sea',
        );
        expect(
          viewData.newWorld.seaZoneDisplayNameByPrefixedId['newWorld|s1'],
          'Caribbean Sea',
        );
      },
    );

    test('invokes with seed configSummary and greatPowerColorOverride', () {
      final viewData = regionCellsSeedConfigView();
      expect(viewData.seed, 123);
      expect(viewData.configSummary, 'test config');
      expect(viewData.oldWorld.factionColors['gp1'], isNotNull);
      expect(
        viewData.oldWorld.cells.singleWhere((c) => !c.isSea).ownerFactionId,
        'gp1',
      );
    });
  });

  group('buildInitGameMapViewData extracted slice coverage', () {
    test(
      'region setup maps owner/display and terrain palette from minimal data',
      expectRegionCellsTerrainSliceMapping,
    );

    test('overlay setup counts regiments, civilians, and in-port ships', () {
      expectRegionCellsOverlayUnitCounts();
    });

    test('marker helpers expose capitals ports towns and warps', () {
      expectRegionCellsMarkerHelpersExposeWarp();
    });

    test('cell helper applies visibility and extraction overlays', () {
      expectRegionCellsVisibilityOverlayOnCell();
    });

    test(
      'does not synthesize a Home Fleet marker when fleet entity is missing',
      expectRegionCellsHomeFleetMissingEntity,
    );

    test('keeps an empty Home Fleet marker when real fleet entity exists', () {
      expectRegionCellsHomeFleetWithEntity();
    });
  });

  group('buildInitGameMapViewData visibility and unit presence', () {
    test('applies visibilityByTile map to CellViewData.visibility', () {
      final viewData = buildViewDataForScenario(
        dualRegionScenario(
          game: regionCellsVisibilityGame(),
          oldWorldGrid: const [
            ['p1', 'p1'],
          ],
          oldWorldTopology: regionTopology(
            regionId: 'oldWorld',
            provinceIds: const ['p1'],
          ),
        ),
        visibilityByTile: const {
          'oldWorld|p1|0|0': TileVisibility.visible,
          'oldWorld|p1|1|0': TileVisibility.fogged,
          'newWorld|p1|0|0': TileVisibility.unrevealed,
        },
      );

      final owCells = viewData.oldWorld.cells;
      expect(
        owCells.singleWhere((c) => c.x == 0 && c.y == 0).visibility,
        TileVisibility.visible,
      );
      expect(
        owCells.singleWhere((c) => c.x == 1 && c.y == 0).visibility,
        TileVisibility.fogged,
      );
      expect(
        viewData.newWorld.cells.single.visibility,
        TileVisibility.unrevealed,
      );
    });

    test(
      'province unit presence shows own province counts and hides other province without visible intel',
      () {
        final viewData = buildViewDataForScenario(
          dualRegionScenario(
            game: regionCellsPresenceHiddenOtherGame(),
            oldWorldGrid: const [
              ['pOwn', 'pOther'],
            ],
            oldWorldTopology: regionTopology(
              regionId: 'oldWorld',
              provinceIds: const ['pOwn', 'pOther'],
              edges: const [TopologyEdge(id1: 'pOwn', id2: 'pOther')],
            ),
          ),
          visibilityByTile: const {
            'oldWorld|pOwn|0|0': TileVisibility.visible,
            'oldWorld|pOther|1|0': TileVisibility.unrevealed,
          },
        );

        final own =
            viewData.oldWorld.provinceUnitPresenceByProvinceId['oldWorld|pOwn'];
        final other =
            viewData.oldWorld.provinceUnitPresenceByProvinceId['oldWorld|pOther'];
        expect(own, isNotNull);
        expect(other, isNotNull);
        expect(own!.intelVisible, isTrue);
        expect(own.civilianCount, 1);
        expect(own.regimentCount, 0);
        expect(own.shipCount, 0);
        expect(other!.intelVisible, isFalse);
        expect(other.civilianCount, 0);
        expect(other.regimentCount, 1);
        expect(other.shipCount, 1);
      },
    );

    test(
      'province unit presence exposes other province counts when tile is visible',
      () {
        final viewData = buildViewDataForScenario(
          dualRegionScenario(
            game: regionCellsPresenceVisibleOtherGame(),
            oldWorldGrid: const [
              ['pOther'],
            ],
            oldWorldTopology: regionTopology(
              regionId: 'oldWorld',
              provinceIds: const ['pOther'],
            ),
          ),
          visibilityByTile: const {
            'oldWorld|pOther|0|0': TileVisibility.visible,
          },
        );

        final other =
            viewData.oldWorld.provinceUnitPresenceByProvinceId['oldWorld|pOther'];
        expect(other, isNotNull);
        expect(other!.intelVisible, isTrue);
        expect(other.civilianCount, 1);
        expect(other.regimentCount, 1);
        expect(other.shipCount, 1);
      },
    );
  });
}
