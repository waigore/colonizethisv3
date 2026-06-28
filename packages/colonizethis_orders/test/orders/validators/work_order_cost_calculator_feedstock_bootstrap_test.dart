import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_cost_calculator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847: H8 feedstock bootstrap castIron waiver on level-0 build_improvement.

const _supplierId = 'gp1';
const _sellerId = 'gp2';
const _timberTile = 'oldWorld|gp1-s0|1|0';
const _grainTile = 'oldWorld|gp1-s0|0|0';
const _sellerWoolTile = 'oldWorld|gp2-p0|0|0';

Game _twoPlayerFeedstockGateGame({required Stockpile supplierStockpile}) {
  const supplierOw = kObserverConquestMinOwProvincesPerGp;
  const sellerOw = 5;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|gp1-s$i',
        regionId: kRegionOldWorld,
        ownerId: _supplierId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|gp2-p$i',
        regionId: kRegionOldWorld,
        ownerId: _sellerId,
      ),
  ];
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        kRegionOldWorld: {
          'oldWorld|gp1-s0': [_grainTile, _timberTile],
          'oldWorld|gp2-p0': [_sellerWoolTile],
        },
      },
      resourceByTileKey: const {
        _grainTile: 'grain',
        _timberTile: 'timber',
        _sellerWoolTile: 'wool',
      },
      tileState: const TileMapState(
        improvementByTile: {_grainTile: 0, _timberTile: 0, _sellerWoolTile: 0},
      ),
    ),
    players: [
      Player(
        id: _supplierId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        stockpile: supplierStockpile,
      ),
      Player(
        id: _sellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(quantities: {'lumber': 1}),
      ),
    ],
  );
}

void main() {
  group('WorkOrderCostCalculator feedstock bootstrap castIron waiver', () {
    test('omits castIron for unimproved feedstock tile when gate active and '
        'stockpile has lumber only', () {
      final game = _twoPlayerFeedstockGateGame(
        supplierStockpile: const Stockpile(quantities: {'lumber': 2}),
      );
      expect(
        feedstockExtractionResourceIdsForPlayer(game, _supplierId),
        contains('timber'),
      );
      expect(
        feedstockBootstrapBuildImprovementCastIronWaived(
          game,
          _supplierId,
          _timberTile,
        ),
        isTrue,
      );
      final cost = WorkOrderCostCalculator(game, playerId: _supplierId)
          .calculateCost(
            kWorkTargetBuildImprovement,
            _timberTile,
            improvementLevel: 0,
          );
      expect(cost, equals({CommodityCatalog.lumber.id: 1}));
    });

    test(
      'keeps full cost when castIron is already affordable (negative control)',
      () {
        final game = _twoPlayerFeedstockGateGame(
          supplierStockpile: const Stockpile(
            quantities: {'lumber': 2, 'castIron': 1},
          ),
        );
        expect(
          feedstockBootstrapBuildImprovementCastIronWaived(
            game,
            _supplierId,
            _timberTile,
          ),
          isFalse,
        );
        final cost = WorkOrderCostCalculator(game, playerId: _supplierId)
            .calculateCost(
              kWorkTargetBuildImprovement,
              _timberTile,
              improvementLevel: 0,
            );
        expect(cost![CommodityCatalog.lumber.id], 1);
        expect(cost[CommodityCatalog.castIron.id], 1);
      },
    );

    test(
      'keeps full cost on non-feedstock tile while gate active (negative control)',
      () {
        final game = _twoPlayerFeedstockGateGame(
          supplierStockpile: const Stockpile(quantities: {'lumber': 2}),
        );
        expect(
          feedstockBootstrapBuildImprovementCastIronWaived(
            game,
            _supplierId,
            _grainTile,
          ),
          isFalse,
        );
        final cost = WorkOrderCostCalculator(game, playerId: _supplierId)
            .calculateCost(
              kWorkTargetBuildImprovement,
              _grainTile,
              improvementLevel: 0,
            );
        expect(cost![CommodityCatalog.castIron.id], 1);
      },
    );

    test(
      'omits lumber and castIron for unimproved feedstock tile when gate active '
      'and stockpile has neither input (Refs #2847 lumber bootstrap)',
      () {
        final game = _twoPlayerFeedstockGateGame(
          supplierStockpile: Stockpile.empty,
        );
        expect(
          feedstockBootstrapBuildImprovementLumberWaived(
            game,
            _supplierId,
            _timberTile,
          ),
          isTrue,
        );
        expect(
          feedstockBootstrapBuildImprovementCastIronWaived(
            game,
            _supplierId,
            _timberTile,
          ),
          isFalse,
        );
        final cost = WorkOrderCostCalculator(game, playerId: _supplierId)
            .calculateCost(
              kWorkTargetBuildImprovement,
              _timberTile,
              improvementLevel: 0,
            );
        expect(cost, isEmpty);
      },
    );

    test(
      'does not waive lumber when castIron is already affordable (negative control)',
      () {
        final game = _twoPlayerFeedstockGateGame(
          supplierStockpile: const Stockpile(quantities: {'castIron': 1}),
        );
        expect(
          feedstockBootstrapBuildImprovementLumberWaived(
            game,
            _supplierId,
            _timberTile,
          ),
          isFalse,
        );
        final cost = WorkOrderCostCalculator(game, playerId: _supplierId)
            .calculateCost(
              kWorkTargetBuildImprovement,
              _timberTile,
              improvementLevel: 0,
            );
        expect(cost![CommodityCatalog.lumber.id], 1);
        expect(cost[CommodityCatalog.castIron.id], 1);
      },
    );
  });
}
