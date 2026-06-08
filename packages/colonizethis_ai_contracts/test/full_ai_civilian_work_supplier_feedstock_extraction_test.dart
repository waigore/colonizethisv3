import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'full_ai_civilian_work_supplier_feedstock_extraction_fixtures.dart';

void main() {
  group(
    'supplierImprovementInputFeedstockExtractionResourceIds '
    '(Refs #2847 H8-extraction supplier feedstock)',
    () {
      test('active peer demand returns castIron feedstock {timber, iron}', () {
        final game = twoPlayerSupplierFeedstockGame();
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            supplierFeedstockId,
          ),
          containsAll(<String>['timber', 'iron']),
        );
      });

      test('returns empty for a player that is itself a locked seller', () {
        final game = twoPlayerSupplierFeedstockGame();
        // The seller's own feedstock-extraction gate routes its Builder; the
        // supplier role must exclude it.
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            sellerFeedstockId,
          ),
          isEmpty,
        );
      });

      test('returns empty when no peer needs the improvement input', () {
        // Seller at quota → not a below-quota lock-recovery seller, so no peer
        // demand exists.
        final game = twoPlayerSupplierFeedstockGame(
          sellerOw: kObserverConquestMinOwProvincesPerGp,
        );
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            supplierFeedstockId,
          ),
          isEmpty,
        );
      });

      test('returns empty when the peer already holds castIron', () {
        final game = twoPlayerSupplierFeedstockGame(
          sellerStockpile: const Stockpile(
            quantities: {'lumber': 1, 'castIron': 1},
          ),
        );
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            supplierFeedstockId,
          ),
          isEmpty,
        );
      });

      test('returns empty when the supplier owns no unimproved feedstock tile', () {
        final game = twoPlayerSupplierFeedstockGame(
          resourceByTileKey: const {
            supplierGrainTile: 'grain',
            sellerWoolTile: 'wool',
          },
        );
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            supplierFeedstockId,
          ),
          isEmpty,
        );
      });

      test('returns empty when the supplier feedstock tile is already improved', () {
        final game = twoPlayerSupplierFeedstockGame(
          tileState: TileMapState().setImprovement(supplierTimberTile, 1),
        );
        expect(
          supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            supplierFeedstockId,
          ),
          isEmpty,
        );
      });

      test('evaluation is deterministic', () {
        final game = twoPlayerSupplierFeedstockGame();
        final a = supplierImprovementInputFeedstockExtractionResourceIds(
          game,
          supplierFeedstockId,
        );
        final b = supplierImprovementInputFeedstockExtractionResourceIds(
          game,
          supplierFeedstockId,
        );
        expect(a, equals(b));
      });
    },
  );

  group(
    'selectFullAiCivilianWorkOrders supplier feedstock extraction '
    '(Refs #2847 H8-extraction supplier feedstock)',
    () {
      test('supplier Builder prefers timber feedstock tile over grain', () {
        final game = twoPlayerSupplierFeedstockGame();
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: supplierGrainTile,
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: supplierTimberTile,
          ),
        ];
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: supplierBuilderView(game),
          game: game,
        );
        expect(r.workOrders, hasLength(1));
        expect(r.workOrders.single.targetTileKey, supplierTimberTile);
      });

      test('supplier keeps ordinary ordering when no peer needs the input', () {
        final game = twoPlayerSupplierFeedstockGame(
          sellerOw: kObserverConquestMinOwProvincesPerGp,
        );
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: supplierGrainTile,
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: supplierTimberTile,
          ),
        ];
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: supplierBuilderView(game),
          game: game,
        );
        // No supplier feedstock boost → ordinary deterministic ordering
        // (lexicographically smaller grain tile key wins the tie).
        expect(r.workOrders.single.targetTileKey, supplierGrainTile);
      });

      test('selection is deterministic when the supplier gate is active', () {
        final game = twoPlayerSupplierFeedstockGame();
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: supplierGrainTile,
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: supplierTimberTile,
          ),
        ];
        final view = supplierBuilderView(game);
        final a = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: view,
          game: game,
        );
        final b = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: view,
          game: game,
        );
        expect(a.workOrders, equals(b.workOrders));
      });
    },
  );
}
