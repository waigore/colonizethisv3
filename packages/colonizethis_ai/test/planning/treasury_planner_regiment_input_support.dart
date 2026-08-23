// Shared scaffolding for treasury planner regiment build-input contract
// suites (Refs #2847 / #3941).
//
// Game builders and [runRegimentInputTreasuryPlanner] are shared across the
// bootstrap and supply/retention contract files so the six legacy
// `treasury_planner_regiment_input_*_test.dart` shards deduplicate fixtures
// without changing deterministic outcomes.

import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/cheapest_regiment_build_treasury_cost.dart';

export 'treasury_planner_regiment_input_games.dart';

const String kRegimentInputFabricId = 'fabric';
const String kRegimentInputWoolId = 'wool';
const String kRegimentInputTimberId = 'timber';
const String kRegimentInputIronId = 'iron';
const String kRegimentInputLumberId = 'lumber';
const String kRegimentInputCastIronId = 'castIron';

const String kRegimentInputSellerId = 'gp_seller';
const String kRegimentInputSupplierId = 'gp_supplier';
const String kRegimentInputSingleGpId = 'gp1';

/// Wool resource tile in the seller's capital province, unimproved by default so
/// the build_improvement (and therefore the improvement-input gate) is needed.
const String kRegimentInputSellerWoolTile = 'oldWorld|seller_0|1|0';

int regimentInputThreshold() => cheapestRegimentBuildTreasuryCost();

/// Single-GP lock-recovery seller fixture shared by bootstrap / retention /
/// feedstock pins.
Game lockRecoverySellerRegimentInputGame({
  required int treasury,
  required int fabricHeld,
  int woolHeld = 20,
  int owProvinces = 3,
  bool hasRegiment = false,
  bool zeroNewWorld = true,
}) {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  var stockpile = const Stockpile().applyDelta('grain', 80);
  if (woolHeld > 0) {
    stockpile = stockpile.applyDelta(kRegimentInputWoolId, woolHeld);
  }
  if (fabricHeld > 0) {
    stockpile = stockpile.applyDelta(kRegimentInputFabricId, fabricHeld);
  }
  return Game(
    id: 'g-regiment-input-seller',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < owProvinces; i++)
            Province(
              id: '$ow|p_$i',
              regionId: ow,
              ownerId: kRegimentInputSingleGpId,
            ),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          if (!zeroNewWorld)
            Province(
              id: '$nw|n_0',
              regionId: nw,
              ownerId: kRegimentInputSingleGpId,
            ),
        ],
      ),
      armies: [
        if (hasRegiment)
          const Army(
            id: 'army-gp1-field',
            ownerId: kRegimentInputSingleGpId,
            regionId: ow,
            stationedProvinceId: '$ow|p_0',
            regimentUnitIds: ['reg-1'],
          ),
      ],
    ),
    players: [
      Player(
        id: kRegimentInputSingleGpId,
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p_0',
        stockpile: stockpile,
        treasury: treasury,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'grain': 10,
      'timber': 20,
      kRegimentInputFabricId: 40,
      kRegimentInputWoolId: 20,
    }),
  );
}

/// Two-GP seller/supplier fixture for market-supply and improvement pins.
Game twoGpRegimentInputGame({
  required int sellerTreasury,
  required int supplierTreasury,
  required int sellerFabricHeld,
  required int sellerWoolHeld,
  required int supplierWoolHeld,
  int supplierTimberHeld = 0,
  int sellerOwProvinces = 3,
  int supplierOwProvinces = 12,
}) {
  const ow = 'oldWorld';
  var sellerStockpile = const Stockpile().applyDelta('grain', 80);
  if (sellerWoolHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(
      kRegimentInputWoolId,
      sellerWoolHeld,
    );
  }
  if (sellerFabricHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(
      kRegimentInputFabricId,
      sellerFabricHeld,
    );
  }
  var supplierStockpile = const Stockpile().applyDelta('grain', 80);
  if (supplierWoolHeld > 0) {
    supplierStockpile = supplierStockpile.applyDelta(
      kRegimentInputWoolId,
      supplierWoolHeld,
    );
  }
  if (supplierTimberHeld > 0) {
    supplierStockpile = supplierStockpile.applyDelta(
      kRegimentInputTimberId,
      supplierTimberHeld,
    );
  }
  return Game(
    id: 'g-h8-supply-market',
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
      kRegimentInputTimberId: 30,
    }),
  );
}

/// Improvement-input bootstrap fixture with optional feedstock tile state.
