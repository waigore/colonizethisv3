import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/full_ai_civilian_work_supplier_feedstock_extraction_fixtures.dart';
import 'support/h8_supplier_prospect_game.dart';

// Refs #2847 § H8-extraction Old World mineral feedstock prospect localization.
//
// `ownsProspectedOldWorldMineralFeedstockTile`, `hasIdleExplorerUnit`, and
// `ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile` are the
// read-only localization predicates that split the residual supplier `iron`
// extraction break (the H8 castIron supplier owns an unimproved Old World `iron`
// mineral tile every gate-active turn yet never holds `iron`) into its proximate
// stages: no idle Explorer to reserve (`hasIdleExplorerUnit` false); the tile is
// prospected but never improved (`ownsProspectedOldWorldMineralFeedstockTile`
// true while `iron` held stays 0); or an idle Explorer exists but is never
// positioned on the feedstock province so no `prospect` candidate generates
// (`ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile`
// false while `hasIdleExplorerUnit` is true → reservation positioning residual).

void main() {
  group(
    'ownsProspectedOldWorldMineralFeedstockTile (Refs #2847 H8-extraction)',
    () {
      test('true when the supplier owns a prospected Old World iron tile', () {
        final game = supplierGame().copyWithSupplierProspected({
          h8SupplierProspectIronTile,
        });
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
        final game = supplierGame();
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
        final game = supplierGame().copyWithSupplierProspected({
          h8SupplierProspectTimberTile,
        });
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
        final game = supplierGame(
          resourceByTileKey: const {
            h8SupplierProspectTimberTile: 'timber',
            h8SupplierProspectNewWorldIronTile: 'iron',
            sellerWoolTile: 'wool',
          },
        ).copyWithSupplierProspected({h8SupplierProspectNewWorldIronTile});
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
        final game = supplierGame().copyWithSupplierProspected({
          h8SupplierProspectIronTile,
        });
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
      final game = supplierGame(extraUnits: [supplierProspectExplorer('e1')]);
      expect(hasIdleExplorerUnit(game, supplierFeedstockId), isTrue);
    });

    test('false when the only Explorer is busy (currentWork set)', () {
      final game = supplierGame(
        extraUnits: [
          supplierProspectExplorer(
            'e1',
            currentWork: const CurrentWork(
              workTarget: kWorkTargetExplore,
              tileKey: h8SupplierProspectNewWorldIronTile,
              totalTurns: 5,
              remainingTurns: 3,
            ),
          ),
        ],
      );
      expect(hasIdleExplorerUnit(game, supplierFeedstockId), isFalse);
    });

    test('false when the player owns no Explorer (only a Builder)', () {
      final game = supplierGame(extraUnits: [supplierProspectBuilder('b1')]);
      expect(hasIdleExplorerUnit(game, supplierFeedstockId), isFalse);
    });
  });

  group('ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile '
      '(Refs #2847 H8-extraction)', () {
    test(
      'true when an idle Explorer shares the unprospected iron province',
      () {
        final game = supplierGame(extraUnits: [supplierProspectExplorer('e1')]);
        expect(
          ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
          ),
          isTrue,
        );
      },
    );

    test('false when the idle Explorer is in a different province', () {
      final game = supplierGame(
        extraUnits: [supplierProspectExplorerAt('e1', 'oldWorld|s9')],
      );
      expect(
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
          game,
          supplierFeedstockId,
          {'iron'},
        ),
        isFalse,
      );
    });

    test('false when the co-located Explorer is busy (currentWork set)', () {
      final game = supplierGame(
        extraUnits: [
          supplierProspectExplorer(
            'e1',
            currentWork: const CurrentWork(
              workTarget: kWorkTargetExplore,
              tileKey: h8SupplierProspectNewWorldIronTile,
              totalTurns: 5,
              remainingTurns: 3,
            ),
          ),
        ],
      );
      expect(
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
          game,
          supplierFeedstockId,
          {'iron'},
        ),
        isFalse,
      );
    });

    test('false when the iron tile is already prospected (no unprospected '
        'feedstock province)', () {
      final game = supplierGame(
        extraUnits: [supplierProspectExplorer('e1')],
      ).copyWithSupplierProspected({h8SupplierProspectIronTile});
      expect(
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
          game,
          supplierFeedstockId,
          {'iron'},
        ),
        isFalse,
      );
    });

    test('false for a New World iron tile (Old World only)', () {
      final game = supplierGame(
        resourceByTileKey: const {
          h8SupplierProspectTimberTile: 'timber',
          h8SupplierProspectNewWorldIronTile: 'iron',
          sellerWoolTile: 'wool',
        },
        extraUnits: [supplierProspectExplorer('e1')],
      );
      expect(
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
          game,
          supplierFeedstockId,
          {'iron'},
        ),
        isFalse,
      );
    });

    test('false for an empty feedstock set (negative control)', () {
      final game = supplierGame(extraUnits: [supplierProspectExplorer('e1')]);
      expect(
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
          game,
          supplierFeedstockId,
          const <String>{},
        ),
        isFalse,
      );
    });

    test(
      'false when only a co-located Builder is present (Explorers only)',
      () {
        final game = supplierGame(extraUnits: [supplierProspectBuilder('b1')]);
        expect(
          ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
            game,
            supplierFeedstockId,
            {'iron'},
          ),
          isFalse,
        );
      },
    );
  });
}
