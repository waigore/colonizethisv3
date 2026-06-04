import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'full_ai_civilian_work_supplier_feedstock_extraction_fixtures.dart';

void main() {
  group(
    'selectFullAiCivilianWorkOrders mineral feedstock prospecting '
    '(Refs #2847 H8-extraction mineral feedstock prospecting)',
    () {
      const supplierIronTile = 'oldWorld|s0|2|0';
      const exploreTile = 'oldWorld|s1|0|0';

      Game ironGame({bool ironProspected = false, int sellerOw = 5}) {
        return twoPlayerSupplierFeedstockGame(
          sellerOw: sellerOw,
          resourceByTileKey: const {
            supplierTimberTile: 'timber',
            supplierGrainTile: 'grain',
            supplierIronTile: 'iron',
            sellerWoolTile: 'wool',
          },
        ).copyWithSupplierProspected(
          ironProspected ? const {supplierIronTile} : const {},
        );
      }

      PlayerView explorerView(Game game) => PlayerView(
            playerId: supplierFeedstockId,
            player: game.players.firstWhere((p) => p.id == supplierFeedstockId),
            ownUnitsById: {
              'e1': Unit(
                id: 'e1',
                type: kUnitTypeExplorer,
                ownerId: supplierFeedstockId,
                locationProvinceId: 'oldWorld|s0',
              ),
            },
            provincesById: const {},
            visibilityByTile: const {},
            prospectedTiles: const {},
            diplomacyByOtherId: const {},
          );

      List<WorkOrder> suggestions() => const [
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: exploreTile,
            ),
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetProspect,
              targetTileKey: supplierIronTile,
            ),
          ];

      test(
        'supplier gate active: Explorer prospects the unprospected iron '
        'feedstock tile ahead of exploring',
        () {
          final game = ironGame();
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions(),
            view: explorerView(game),
            game: game,
          );
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.target, kWorkTargetProspect);
          expect(r.workOrders.single.targetTileKey, supplierIronTile);
        },
      );

      test(
        'iron tile already prospected: no prospect boost, Explorer explores '
        '(negative control)',
        () {
          final game = ironGame(ironProspected: true);
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions(),
            view: explorerView(game),
            game: game,
          );
          expect(r.workOrders.single.target, kWorkTargetExplore);
        },
      );

      test(
        'supplier gate inactive (peer at quota): no prospect boost, Explorer '
        'explores (negative control)',
        () {
          final game = ironGame(
            sellerOw: kObserverConquestMinOwProvincesPerGp,
          );
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions(),
            view: explorerView(game),
            game: game,
          );
          expect(r.workOrders.single.target, kWorkTargetExplore);
        },
      );

      test('prospect selection is deterministic across repeated passes', () {
        final game = ironGame();
        final view = explorerView(game);
        final a = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions(),
          view: view,
          game: game,
        );
        final b = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions(),
          view: view,
          game: game,
        );
        expect(a.workOrders, equals(b.workOrders));
        expect(a.workOrders.single.targetTileKey, supplierIronTile);
      });
    },
  );
}
