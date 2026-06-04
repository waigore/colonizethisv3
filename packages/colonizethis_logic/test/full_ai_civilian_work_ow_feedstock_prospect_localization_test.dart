import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'full_ai_civilian_work_supplier_feedstock_extraction_fixtures.dart';

// Refs #2847 § H8-extraction Old World mineral feedstock prospect localization.
//
// `ownsProspectedOldWorldMineralFeedstockTile` and `hasIdleExplorerUnit` are the
// read-only localization predicates that split the residual supplier `iron`
// extraction break (the H8 castIron supplier owns an unimproved Old World `iron`
// mineral tile every gate-active turn yet never holds `iron`) into its proximate
// stages: no idle Explorer to reserve (`hasIdleExplorerUnit` false), versus the
// tile is prospected but never improved
// (`ownsProspectedOldWorldMineralFeedstockTile` true while `iron` held stays 0).

const _supplierIronTile = 'oldWorld|s0|2|0';
const _supplierTimberTile = 'oldWorld|s0|1|0';
const _newWorldIronTile = 'newWorld|n0|0|0';

Game _supplierGame({
  Map<String, String>? resourceByTileKey,
  List<Unit> extraUnits = const [],
}) {
  return twoPlayerSupplierFeedstockGame(
    resourceByTileKey: resourceByTileKey ??
        const {
          _supplierTimberTile: 'timber',
          _supplierIronTile: 'iron',
          sellerWoolTile: 'wool',
        },
    extraUnits: extraUnits,
  );
}

Unit _explorer(String id, {CurrentWork? currentWork}) => Unit(
  id: id,
  type: kUnitTypeExplorer,
  ownerId: supplierFeedstockId,
  locationProvinceId: 'oldWorld|s0',
  currentWork: currentWork,
);

Unit _builder(String id) => Unit(
  id: id,
  type: kUnitTypeBuilder,
  ownerId: supplierFeedstockId,
  locationProvinceId: 'oldWorld|s0',
);

void main() {
  group(
    'ownsProspectedOldWorldMineralFeedstockTile (Refs #2847 H8-extraction)',
    () {
      test('true when the supplier owns a prospected Old World iron tile', () {
        final game = _supplierGame().copyWithSupplierProspected(
          {_supplierIronTile},
        );
        expect(
          ownsProspectedOldWorldMineralFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
          ),
          isTrue,
        );
      });

      test('false when the owned Old World iron tile is not prospected', () {
        final game = _supplierGame();
        expect(
          ownsProspectedOldWorldMineralFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
          ),
          isFalse,
        );
      });

      test('false for a prospected non-mineral (surface) feedstock tile', () {
        // timber is a surface resource (not in kMineralResourceIds): only
        // mineral feedstock tiles require a prospect, so timber never counts.
        final game = _supplierGame().copyWithSupplierProspected(
          {_supplierTimberTile},
        );
        expect(
          ownsProspectedOldWorldMineralFeedstockTile(
            game,
            supplierFeedstockId,
            {'timber'},
          ),
          isFalse,
        );
      });

      test('false for a prospected New World iron tile (Old World only)', () {
        final game = _supplierGame(
          resourceByTileKey: const {
            _supplierTimberTile: 'timber',
            _newWorldIronTile: 'iron',
            sellerWoolTile: 'wool',
          },
        ).copyWithSupplierProspected({_newWorldIronTile});
        expect(
          ownsProspectedOldWorldMineralFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
          ),
          isFalse,
        );
      });

      test('false for an empty feedstock set (negative control)', () {
        final game = _supplierGame().copyWithSupplierProspected(
          {_supplierIronTile},
        );
        expect(
          ownsProspectedOldWorldMineralFeedstockTile(
            game,
            supplierFeedstockId,
            const <String>{},
          ),
          isFalse,
        );
      });
    },
  );

  group('hasIdleExplorerUnit (Refs #2847 H8-extraction)', () {
    test('true when the player owns an idle Explorer', () {
      final game = _supplierGame(extraUnits: [_explorer('e1')]);
      expect(hasIdleExplorerUnit(game, supplierFeedstockId), isTrue);
    });

    test('false when the only Explorer is busy (currentWork set)', () {
      final game = _supplierGame(
        extraUnits: [
          _explorer(
            'e1',
            currentWork: const CurrentWork(
              workTarget: 'explore',
              tileKey: _newWorldIronTile,
              totalTurns: 5,
              remainingTurns: 3,
            ),
          ),
        ],
      );
      expect(hasIdleExplorerUnit(game, supplierFeedstockId), isFalse);
    });

    test('false when the player owns no Explorer (only a Builder)', () {
      final game = _supplierGame(extraUnits: [_builder('b1')]);
      expect(hasIdleExplorerUnit(game, supplierFeedstockId), isFalse);
    });
  });
}
