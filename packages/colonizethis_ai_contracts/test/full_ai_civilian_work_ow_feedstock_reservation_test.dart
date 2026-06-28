import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'full_ai_civilian_work_supplier_feedstock_extraction_fixtures.dart';

// Refs #2847 § H8-extraction supplier Old World feedstock unit reservation.
//
// The affluent supplier owns an unimproved Old World `iron` (mineral) tile and
// `timber` tile on every gate-active turn, but its idle Builders / Explorers
// migrate to higher-scoring New World colonial work, so the feedstock tile is
// never prospected / improved. `selectFullAiCivilianWorkOrders` must hold one
// idle Builder and one idle Explorer out of New World work so they stay
// available for the Old World feedstock `prospect` / `build_improvement`.

const _supplierIronTile = 'oldWorld|s0|2|0';
const _newWorldTile = 'newWorld|n0|0|0';

Game _ironFeedstockGame({
  int sellerOw = 5,
  TileMapState? tileState,
}) {
  return twoPlayerSupplierFeedstockGame(
    sellerOw: sellerOw,
    resourceByTileKey: const {
      supplierTimberTile: 'timber',
      _supplierIronTile: 'iron',
      supplierGrainTile: 'grain',
      sellerWoolTile: 'wool',
      _newWorldTile: 'iron',
    },
    tileState: tileState,
  );
}

PlayerView _supplierView(Game game, List<Unit> units) {
  return PlayerView(
    playerId: supplierFeedstockId,
    player: game.players.firstWhere((p) => p.id == supplierFeedstockId),
    ownUnitsById: {for (final u in units) u.id: u},
    provincesById: const {},
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Unit _idleBuilder(String id) => Unit(
  id: id,
  type: kUnitTypeBuilder,
  ownerId: supplierFeedstockId,
  locationProvinceId: 'oldWorld|s0',
);

Unit _idleExplorer(String id) => Unit(
  id: id,
  type: kUnitTypeExplorer,
  ownerId: supplierFeedstockId,
  locationProvinceId: 'oldWorld|s0',
);

void main() {
  group(
    'selectFullAiCivilianWorkOrders Old World feedstock unit reservation '
    '(Refs #2847 H8-extraction)',
    () {
      test(
        'reserved Builder routes to Old World feedstock tile, not New World',
        () {
          final game = _ironFeedstockGame();
          final view = _supplierView(game, [_idleBuilder('b1')]);
          final suggestions = [
            const WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: _newWorldTile,
            ),
            const WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: _supplierIronTile,
            ),
          ];
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions,
            view: view,
            game: game,
          );
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.targetTileKey, _supplierIronTile);
        },
      );

      test(
        'lex-first idle Builder is held out of New World; the next Builder '
        'still takes New World work',
        () {
          final game = _ironFeedstockGame();
          final view = _supplierView(game, [
            _idleBuilder('b1'),
            _idleBuilder('b2'),
          ]);
          final suggestions = [
            const WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: _newWorldTile,
            ),
            const WorkOrder(
              unitId: 'b2',
              target: kWorkTargetBuildImprovement,
              targetTileKey: _newWorldTile,
            ),
          ];
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions,
            view: view,
            game: game,
          );
          // b1 (reserved) drops its only (New World) candidate and goes idle;
          // b2 keeps the New World improvement.
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.unitId, 'b2');
          expect(r.workOrders.single.targetTileKey, _newWorldTile);
          expect(
            r.idleEvents.map((e) => e.unitId),
            contains('b1'),
          );
        },
      );

      test(
        'reserved Explorer prospects Old World mineral feedstock tile, not '
        'New World explore',
        () {
          final game = _ironFeedstockGame();
          final view = _supplierView(game, [_idleExplorer('e1')]);
          final suggestions = [
            const WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: _newWorldTile,
            ),
            const WorkOrder(
              unitId: 'e1',
              target: kWorkTargetProspect,
              targetTileKey: _supplierIronTile,
            ),
          ];
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions,
            view: view,
            game: game,
          );
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.target, kWorkTargetProspect);
          expect(r.workOrders.single.targetTileKey, _supplierIronTile);
        },
      );

      test(
        'lex-first idle Explorer is held out of New World; the next Explorer '
        'still explores New World',
        () {
          final game = _ironFeedstockGame();
          final view = _supplierView(game, [
            _idleExplorer('e1'),
            _idleExplorer('e2'),
          ]);
          final suggestions = [
            const WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: _newWorldTile,
            ),
            const WorkOrder(
              unitId: 'e2',
              target: kWorkTargetExplore,
              targetTileKey: _newWorldTile,
            ),
          ];
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions,
            view: view,
            game: game,
          );
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.unitId, 'e2');
          expect(r.workOrders.single.targetTileKey, _newWorldTile);
          expect(r.idleEvents.map((e) => e.unitId), contains('e1'));
        },
      );

      test(
        'off-gate (no peer demand): no reservation, Builder takes New World '
        'work',
        () {
          // Seller at quota → not a below-quota lock-recovery seller → the
          // supplier feedstock gate is inactive, so no reservation applies.
          final game = _ironFeedstockGame(
            sellerOw: kObserverConquestMinOwProvincesPerGp,
          );
          final view = _supplierView(game, [_idleBuilder('b1')]);
          final suggestions = [
            const WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: _newWorldTile,
            ),
          ];
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions,
            view: view,
            game: game,
          );
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.unitId, 'b1');
          expect(r.workOrders.single.targetTileKey, _newWorldTile);
        },
      );

      test(
        'no reservation when the supplier Old World feedstock tiles are all '
        'improved (gate self-clears)',
        () {
          final improved = TileMapState()
              .setImprovement(supplierTimberTile, 1)
              .setImprovement(_supplierIronTile, 1);
          final game = _ironFeedstockGame(tileState: improved);
          final view = _supplierView(game, [_idleBuilder('b1')]);
          final suggestions = [
            const WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: _newWorldTile,
            ),
          ];
          final r = selectFullAiCivilianWorkOrders(
            workSuggestions: suggestions,
            view: view,
            game: game,
          );
          expect(r.workOrders, hasLength(1));
          expect(r.workOrders.single.unitId, 'b1');
          expect(r.workOrders.single.targetTileKey, _newWorldTile);
        },
      );

      test('reservation selection is deterministic', () {
        final game = _ironFeedstockGame();
        final view = _supplierView(game, [
          _idleBuilder('b1'),
          _idleBuilder('b2'),
          _idleExplorer('e1'),
          _idleExplorer('e2'),
        ]);
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _supplierIronTile,
          ),
          const WorkOrder(
            unitId: 'b2',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _newWorldTile,
          ),
          const WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: _supplierIronTile,
          ),
          const WorkOrder(
            unitId: 'e2',
            target: kWorkTargetExplore,
            targetTileKey: _newWorldTile,
          ),
        ];
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
