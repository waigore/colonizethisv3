import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/h8_below_quota_zero_nw_seller_game.dart';

// Refs #2847 § H8-extraction seller feedstock. Single-player fixture: a
// below-quota zero-NW lock-recovery seller that needs its own level-0
// `build_improvement` inputs (`lumber` / `castIron`) and owns an unimproved
// `timber` feedstock tile to extract them from. The seller also owns an
// unimproved `wool` tile (the `peasant_levies` regiment-build-input feedstock)
// so the improvement-cost gate (`regimentBuildInputFeedstockImprovementInputCost`)
// is active — the precondition for the seller improvement-input gate.
// The grain tile key is lexicographically smaller than the timber tile key, so
// ordinary build-improvement ordering (equal base score, lexicographic
// tie-break) selects grain; only the active seller feedstock score boost flips
// the Builder onto the timber tile.
const _grainTile = h8BelowQuotaGrainTile;
const _timberTile = 'oldWorld|p0|1|0';
const _woolTile = 'oldWorld|p0|2|0';

void main() {
  group('sellerImprovementInputFeedstockExtractionResourceIds '
      '(Refs #2847 H8-extraction seller feedstock)', () {
    test('active gate returns improvement-input feedstock {timber, iron}', () {
      final game = belowQuotaActiveGateSellerGame(
        resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
      );
      expect(
        sellerImprovementInputFeedstockExtractionResourceIds(game, h8BelowQuotaSellerId),
        containsAll(<String>['timber', 'iron']),
      );
    });

    test('returns empty for a player at the conquest quota', () {
      final game = belowQuotaActiveGateSellerGame(
        owOwned: kObserverConquestMinOwProvincesPerGp,
        resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
      );
      expect(
        sellerImprovementInputFeedstockExtractionResourceIds(game, h8BelowQuotaSellerId),
        isEmpty,
      );
    });

    test('returns empty when the seller owns a regiment', () {
      final game = belowQuotaActiveGateSellerGame(
        extraUnits: [
          Unit(
            id: 'r1',
            type: 'peasant_levies',
            ownerId: h8BelowQuotaSellerId,
            locationProvinceId: 'oldWorld|p0',
          ),
        ],
        resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
      );
      expect(
        sellerImprovementInputFeedstockExtractionResourceIds(game, h8BelowQuotaSellerId),
        isEmpty,
      );
    });

    test(
      'returns empty when the seller already holds both improvement inputs',
      () {
        final game = belowQuotaActiveGateSellerGame(
          stockpile: const Stockpile(quantities: {'lumber': 1, 'castIron': 1}),
          resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
        );
        expect(
          sellerImprovementInputFeedstockExtractionResourceIds(game, h8BelowQuotaSellerId),
          isEmpty,
        );
      },
    );

    test(
      'returns empty when the seller owns no unimproved timber/iron tile',
      () {
        // Only wool + grain tiles: the regiment / improvement-cost gates stay
        // active, but the seller owns no feedstock tile for lumber / castIron.
        final game = belowQuotaActiveGateSellerGame(
          resourceByTileKey: const {_grainTile: 'grain', _woolTile: 'wool'},
        );
        expect(
          sellerImprovementInputFeedstockExtractionResourceIds(game, h8BelowQuotaSellerId),
          isEmpty,
        );
      },
    );

    test('returns empty when the only timber tile is already improved', () {
      final game = belowQuotaActiveGateSellerGame(
        tileState: TileMapState().setImprovement(_timberTile, 1),
        resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
      );
      expect(
        sellerImprovementInputFeedstockExtractionResourceIds(game, h8BelowQuotaSellerId),
        isEmpty,
      );
    });

    test('evaluation is deterministic', () {
      final game = belowQuotaActiveGateSellerGame(
        resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
      );
      final a = sellerImprovementInputFeedstockExtractionResourceIds(
        game,
        h8BelowQuotaSellerId,
      );
      final b = sellerImprovementInputFeedstockExtractionResourceIds(
        game,
        h8BelowQuotaSellerId,
      );
      expect(a, equals(b));
    });
  });

  group('selectFullAiCivilianWorkOrders seller improvement-input feedstock '
      'extraction (Refs #2847 H8-extraction seller feedstock)', () {
    test('seller Builder prefers timber feedstock tile over grain', () {
      final game = belowQuotaActiveGateSellerGame(
        resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
      );
      final suggestions = [
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _grainTile,
        ),
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _timberTile,
        ),
      ];
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: belowQuotaSellerBuilderView(game),
        game: game,
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.targetTileKey, _timberTile);
    });

    test(
      'seller keeps ordinary ordering when the gate is inactive (at quota)',
      () {
        final game = belowQuotaActiveGateSellerGame(
          owOwned: kObserverConquestMinOwProvincesPerGp,
          resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
        );
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _grainTile,
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: _timberTile,
          ),
        ];
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: belowQuotaSellerBuilderView(game),
          game: game,
        );
        // No feedstock boost → ordinary deterministic ordering selects the
        // lexicographically smaller grain tile key.
        expect(r.workOrders.single.targetTileKey, _grainTile);
      },
    );

    test('selection is deterministic when the seller gate is active', () {
      final game = belowQuotaActiveGateSellerGame(
        resourceByTileKey: h8BelowQuotaTimberImprovementInputResources,
      );
      final suggestions = [
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _grainTile,
        ),
        const WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: _timberTile,
        ),
      ];
      final view = belowQuotaSellerBuilderView(game);
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
  });
}
