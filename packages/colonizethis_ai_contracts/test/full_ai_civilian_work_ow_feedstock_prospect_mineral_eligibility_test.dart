import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'full_ai_civilian_work_supplier_feedstock_extraction_fixtures.dart';

// Refs #2847 § H8-extraction Old World mineral feedstock prospect localization
// (terrain mineral-eligibility gate slice).
//
// `ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile`
// narrows the residual supplier `iron` extraction break past the resource-only
// co-location predicate: an idle Explorer can share the unprospected Old World
// feedstock province yet still generate no `prospect` candidate when the tile's
// live terrain is not mineral-eligible (plains/forest rather than
// hills/mountain/swamp/desert). This predicate adds the live-terrain
// mineral-eligibility check on top of the resource-only co-location signal.

const _supplierIronTile = 'oldWorld|s0|2|0';
const _supplierTimberTile = 'oldWorld|s0|1|0';
const _newWorldIronTile = 'newWorld|n0|0|0';

Game _supplierGame({
  Map<String, String>? resourceByTileKey,
  List<Unit> extraUnits = const [],
}) {
  return twoPlayerSupplierFeedstockGame(
    resourceByTileKey:
        resourceByTileKey ??
        const {
          _supplierTimberTile: 'timber',
          _supplierIronTile: 'iron',
          sellerWoolTile: 'wool',
        },
    extraUnits: extraUnits,
  );
}

Unit _explorer(String id, {CurrentWork? currentWork}) =>
    _explorerAt(id, 'oldWorld|s0', currentWork: currentWork);

Unit _explorerAt(
  String id,
  String locationProvinceId, {
  CurrentWork? currentWork,
}) => Unit(
  id: id,
  type: kUnitTypeExplorer,
  ownerId: supplierFeedstockId,
  locationProvinceId: locationProvinceId,
  currentWork: currentWork,
);

// The supplier `iron` tile sits at (x=2, y=0) of region `oldWorld`. This live
// tile map sets the iron tile's terrain to [ironTerrain] so the mineral-
// eligibility terrain check can pass (hills/mountain/swamp/desert) or fail
// (plains/forest); the other cells are hills (prospectable filler).
Map<String, TileMapResult> _tileMapWithIronTerrain(TerrainType ironTerrain) => {
  'oldWorld': TileMapResult(
    width: 3,
    height: 1,
    grid: const [
      ['oldWorld|s0', 'oldWorld|s0', 'oldWorld|s0'],
    ],
    terrainGrid: [
      [TerrainType.hills, TerrainType.hills, ironTerrain],
    ],
  ),
};

void main() {
  group(
    'ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile'
    ' (Refs #2847 H8-extraction terrain mineral-eligibility gate)',
    () {
      test('true when the co-located iron tile is on prospectable terrain '
          '(hills)', () {
        final game = _supplierGame(extraUnits: [_explorer('e1')]);
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
            _tileMapWithIronTerrain(TerrainType.hills),
          ),
          isTrue,
        );
      });

      test('false when the co-located iron tile is on non-prospectable terrain '
          '(plains) — localizes the residual to terrain mineral-eligibility',
          () {
        final game = _supplierGame(extraUnits: [_explorer('e1')]);
        // Teeth: the resource-only co-located predicate is still true (the
        // supplier owns an idle Explorer on the unprospected iron province),
        // so the only discriminator is the live-terrain mineral-eligibility
        // check the new predicate adds.
        expect(
          ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
          ),
          isTrue,
        );
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
            _tileMapWithIronTerrain(TerrainType.plains),
          ),
          isFalse,
        );
      });

      test('true when tileMapByRegion is null (terrain unknown falls back to '
          'the mineral resource on the tile)', () {
        // With no live terrain map the eligibility check degrades to the
        // resource-only signal, matching `isMineralEligibleTile`'s documented
        // missing-terrain fallback, so the predicate stays equivalent to the
        // resource-only co-located counterpart.
        final game = _supplierGame(extraUnits: [_explorer('e1')]);
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
            null,
          ),
          isTrue,
        );
      });

      test('false when the idle Explorer is in a different province', () {
        final game = _supplierGame(
          extraUnits: [_explorerAt('e1', 'oldWorld|s9')],
        );
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
            _tileMapWithIronTerrain(TerrainType.hills),
          ),
          isFalse,
        );
      });

      test('false when the co-located Explorer is busy (currentWork set)', () {
        final game = _supplierGame(
          extraUnits: [
            _explorer(
              'e1',
              currentWork: const CurrentWork(
                workTarget: kWorkTargetExplore,
                tileKey: _newWorldIronTile,
                totalTurns: 5,
                remainingTurns: 3,
              ),
            ),
          ],
        );
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
            _tileMapWithIronTerrain(TerrainType.hills),
          ),
          isFalse,
        );
      });

      test('false when the iron tile is already prospected', () {
        final game = _supplierGame(
          extraUnits: [_explorer('e1')],
        ).copyWithSupplierProspected({_supplierIronTile});
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
            _tileMapWithIronTerrain(TerrainType.hills),
          ),
          isFalse,
        );
      });

      test('false for an empty feedstock set (negative control)', () {
        final game = _supplierGame(extraUnits: [_explorer('e1')]);
        expect(
          ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
            game,
            supplierFeedstockId,
            const <String>{},
            _tileMapWithIronTerrain(TerrainType.hills),
          ),
          isFalse,
        );
      });
    },
  );
}
