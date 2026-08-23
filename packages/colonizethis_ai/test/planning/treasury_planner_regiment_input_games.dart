// Shared scaffolding for treasury planner regiment build-input contract
// suites (Refs #2847 / #3941).
//
// Game builders and [runRegimentInputTreasuryPlanner] are shared across the
// bootstrap and supply/retention contract files so the six legacy
// `treasury_planner_regiment_input_*_test.dart` shards deduplicate fixtures
// without changing deterministic outcomes.

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'treasury_planner_regiment_input_support.dart';

Game improvementBootstrapRegimentInputGame({
  required int sellerTreasury,
  required int supplierTreasury,
  bool sellerHoldsImprovementInputs = false,
  bool sellerOwnsFeedstockTile = true,
  bool sellerWoolTileImproved = false,
  List<Unit> sellerUnits = const [],
  int supplierLumberHeld = 20,
  int sellerOwProvinces = 3,
  int supplierOwProvinces = 12,
}) {
  const ow = 'oldWorld';
  var sellerStockpile = const Stockpile().applyDelta('grain', 80);
  if (sellerHoldsImprovementInputs) {
    sellerStockpile = sellerStockpile
        .applyDelta(kRegimentInputLumberId, 1)
        .applyDelta(kRegimentInputCastIronId, 1);
  }
  var supplierStockpile = const Stockpile().applyDelta('grain', 80);
  if (supplierLumberHeld > 0) {
    supplierStockpile = supplierStockpile.applyDelta(
      kRegimentInputLumberId,
      supplierLumberHeld,
    );
  }
  final resourceByTileKey = <String, String>{
    if (sellerOwnsFeedstockTile)
      kRegimentInputSellerWoolTile: kRegimentInputWoolId,
  };
  final tileState = sellerWoolTileImproved
      ? TileMapState().setImprovement(kRegimentInputSellerWoolTile, 1)
      : TileMapState();
  return Game(
    id: 'g-h8-improvement',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < sellerOwProvinces; i++)
            Province(
              id: '$ow|seller_$i',
              regionId: ow,
              ownerId: kRegimentInputSellerId,
            ),
          for (var i = 0; i < supplierOwProvinces; i++)
            Province(
              id: '$ow|supplier_$i',
              regionId: ow,
              ownerId: kRegimentInputSupplierId,
            ),
        ],
        units: sellerUnits,
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState,
    ),
    players: [
      Player(
        id: kRegimentInputSellerId,
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        stockpile: sellerStockpile,
        treasury: sellerTreasury,
      ),
      Player(
        id: kRegimentInputSupplierId,
        displayName: 'Supplier',
        isHuman: false,
        capitalProvinceId: '$ow|supplier_0',
        stockpile: supplierStockpile,
        treasury: supplierTreasury,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'grain': 10,
      kRegimentInputWoolId: 20,
      kRegimentInputFabricId: 40,
      kRegimentInputLumberId: 15,
      kRegimentInputCastIronId: 30,
    }),
  );
}

/// castIron domestic-production fixture.
Game castIronProductionRegimentInputGame({
  required int sellerTreasury,
  int sellerLumberHeld = 0,
  int sellerCastIronHeld = 0,
  int sellerTimberHeld = 0,
  int sellerIronHeld = 0,
  bool sellerOwnsFeedstockTile = true,
  int sellerOwProvinces = 3,
  int supplierOwProvinces = 12,
}) {
  const ow = 'oldWorld';
  var sellerStockpile = const Stockpile().applyDelta('grain', 80);
  if (sellerLumberHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(
      kRegimentInputLumberId,
      sellerLumberHeld,
    );
  }
  if (sellerCastIronHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(
      kRegimentInputCastIronId,
      sellerCastIronHeld,
    );
  }
  if (sellerTimberHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(
      kRegimentInputTimberId,
      sellerTimberHeld,
    );
  }
  if (sellerIronHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(
      kRegimentInputIronId,
      sellerIronHeld,
    );
  }
  final resourceByTileKey = <String, String>{
    if (sellerOwnsFeedstockTile)
      kRegimentInputSellerWoolTile: kRegimentInputWoolId,
  };
  return Game(
    id: 'g-h8-castiron',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < sellerOwProvinces; i++)
            Province(
              id: '$ow|seller_$i',
              regionId: ow,
              ownerId: kRegimentInputSellerId,
            ),
          for (var i = 0; i < supplierOwProvinces; i++)
            Province(
              id: '$ow|supplier_$i',
              regionId: ow,
              ownerId: kRegimentInputSupplierId,
            ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: resourceByTileKey,
    ),
    players: [
      Player(
        id: kRegimentInputSellerId,
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        stockpile: sellerStockpile,
        treasury: sellerTreasury,
      ),
      Player(
        id: kRegimentInputSupplierId,
        displayName: 'Supplier',
        isHuman: false,
        capitalProvinceId: '$ow|supplier_0',
        stockpile: const Stockpile().applyDelta('grain', 80),
        treasury: sellerTreasury,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'grain': 10,
      kRegimentInputWoolId: 20,
      kRegimentInputFabricId: 40,
      kRegimentInputLumberId: 15,
      kRegimentInputCastIronId: 30,
      kRegimentInputTimberId: 8,
      kRegimentInputIronId: 12,
    }),
  );
}

List<TradeOrder> runRegimentInputTreasuryPlanner(
  Game game, {
  String playerId = kRegimentInputSingleGpId,
}) => runTreasuryPlanner(
  TreasuryPlannerInput(
    game: game,
    playerId: playerId,
    stockpile: game.players.firstWhere((p) => p.id == playerId).stockpile,
    productionAssignments: const [],
    treasury: game.players.firstWhere((p) => p.id == playerId).treasury,
  ),
);

Iterable<TradeOrder> regimentInputBidsFor(
  List<TradeOrder> orders,
  String commodityId,
) => orders.where(
  (o) => o.type == TradeOrderType.bid && o.commodityId == commodityId,
);

Iterable<TradeOrder> regimentInputOffersFor(
  List<TradeOrder> orders,
  String commodityId,
) => orders.where(
  (o) => o.type == TradeOrderType.offer && o.commodityId == commodityId,
);
