// Shared Game factories for treasury satellite pins (Refs #4104 Slice A).
// Forecasting continues to use treasuryPlannerTestGameWithStockpile in
// treasury_planner_main_support.dart.
library;

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_ai/src/planning/treasury_planner.dart'
    show kTreasuryBidPriorityEssentialInput;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_models/colonizethis_models.dart';

// --- boycott suppression ---
const kTreasuryBoycottOw = 'oldWorld';
const kTreasuryBoycottNw = 'newWorld';
const kTreasuryBoycottColonyCommodity = 'furs';

Game treasuryPlannerBoycottSuppressionGame({
  required Stockpile stockpile,
  required int treasury,
  List<BoycottState> boycottStates = const [],
}) {
  return Game(
    id: 'g_treasury_boycott',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$kTreasuryBoycottOw|p1', regionId: kTreasuryBoycottOw, ownerId: 'gpC'),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: '$kTreasuryBoycottNw|t1',
            regionId: kTreasuryBoycottNw,
            ownerId: 't1',
            townDevelopmentLevel: 1,
          ),
        ],
      ),
      tileState: TileMapState()
          .setImprovement('newWorld|t1|0|0', 1)
          .setRoadLevel('newWorld|t1|0|0', 1),
    ),
    players: [
      Player(
        id: 'gpC',
        displayName: 'Castile',
        isHuman: false,
        capitalProvinceId: '$kTreasuryBoycottOw|p1',
        stockpile: stockpile,
        treasury: treasury,
      ),
    ],
    tribes: [
      Tribe(
        id: 't1',
        capitalProvinceId: '$kTreasuryBoycottNw|t1',
        capitalTile: CapitalTile(
          regionId: kTreasuryBoycottNw,
          provinceId: '$kTreasuryBoycottNw|t1',
          x: 0,
          y: 0,
        ),
      ),
    ],
    colonyStates: const [
      ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
    ],
    boycottStates: boycottStates,
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      kTreasuryBoycottColonyCommodity: 10,
    }),
  );
}

// --- supplier castIron source ---
const kTreasurySupplierWoolId = 'wool';
const kTreasurySupplierFabricId = 'fabric';
const kTreasurySupplierLumberId = 'lumber';
const kTreasurySupplierCastIronId = 'castIron';
const kTreasurySupplierTimberId = 'timber';
const kTreasurySupplierIronId = 'iron';
const kTreasurySupplierSellerWoolTile = 'oldWorld|seller_0|1|0';

Game treasuryPlannerSupplierCastIronSourceGame({
  required int sellerTreasury,
  required int supplierTreasury,
  int sellerLumberHeld = 1,
  int sellerCastIronHeld = 0,
  int supplierCastIronHeld = 0,
  bool sellerOwnsFeedstockTile = true,
  bool supplierStandingCastIronOffer = false,
  int sellerOwProvinces = 3,
  int supplierOwProvinces = 12,
}) {
  const ow = 'oldWorld';
  var sellerStockpile = const Stockpile().applyDelta('grain', 80);
  if (sellerLumberHeld > 0) {
    sellerStockpile = sellerStockpile.applyDelta(kTreasurySupplierLumberId, sellerLumberHeld);
  }
  if (sellerCastIronHeld > 0) {
    sellerStockpile =
        sellerStockpile.applyDelta(kTreasurySupplierCastIronId, sellerCastIronHeld);
  }
  var supplierStockpile = const Stockpile().applyDelta('grain', 80);
  if (supplierCastIronHeld > 0) {
    supplierStockpile =
        supplierStockpile.applyDelta(kTreasurySupplierCastIronId, supplierCastIronHeld);
  }
  final resourceByTileKey = <String, String>{
    if (sellerOwnsFeedstockTile) kTreasurySupplierSellerWoolTile: kTreasurySupplierWoolId,
  };
  var marketState = WorldMarketState.withDefaultPrices(const {
    'grain': 10,
    kTreasurySupplierWoolId: 20,
    kTreasurySupplierFabricId: 40,
    kTreasurySupplierLumberId: 15,
    kTreasurySupplierCastIronId: 30,
    kTreasurySupplierTimberId: 8,
    kTreasurySupplierIronId: 12,
  });
  if (supplierStandingCastIronOffer) {
    marketState = marketState.copyWith(
      carryForwardOffersByFactionId: {
        'gp_supplier': [
          TradeOrder(
            commodityId: kTreasurySupplierCastIronId,
            type: TradeOrderType.offer,
            quantity: 4,
            priority: kTreasuryBidPriorityEssentialInput,
          ),
        ],
      },
    );
  }
  return Game(
    id: 'g-h8-castiron-source',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < sellerOwProvinces; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
          for (var i = 0; i < supplierOwProvinces; i++)
            Province(
              id: '$ow|supplier_$i',
              regionId: ow,
              ownerId: 'gp_supplier',
            ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: resourceByTileKey,
    ),
    players: [
      Player(
        id: 'gp_seller',
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        stockpile: sellerStockpile,
        treasury: sellerTreasury,
      ),
      Player(
        id: 'gp_supplier',
        displayName: 'Supplier',
        isHuman: false,
        capitalProvinceId: '$ow|supplier_0',
        stockpile: supplierStockpile,
        treasury: supplierTreasury,
      ),
    ],
    worldMarketState: marketState,
  );
}

// --- trade-deal relation boost ---
const kTreasuryTradeDealOw = 'oldWorld';
const kTreasuryTradeDealGp = 'gpC';
const kTreasuryTradeDealDefaultAdmitted = 'copper';
const kTreasuryTradeDealDefaultDropped = 'tin';
const kTreasuryTradeDealDefaultDroppedAlt = 'wool';

Game treasuryPlannerTradeDealRelationBoostGame({
  required List<MinorNation> minors,
  required Map<String, List<TradeOrder>> standingOffers,
  List<SubsidyState> subsidyStates = const [],
  List<OvertureState> overtureStates = const [],
}) {
  return Game(
    id: 'g_trade_deal_pref',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$kTreasuryTradeDealOw|p1', regionId: kTreasuryTradeDealOw, ownerId: kTreasuryTradeDealGp),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: kTreasuryTradeDealGp,
        displayName: 'Castile',
        isHuman: false,
        capitalProvinceId: '$kTreasuryTradeDealOw|p1',
        // Empty stockpile: the bronze recipe's copper + tin inputs are an
        // unmet deficit, so both surface as bid needs (F1–F3 input path).
        stockpile: const Stockpile(),
        treasury: cheapestRegimentBuildTreasuryCost() + 50000,
      ),
    ],
    minorNations: minors,
    subsidyStates: subsidyStates,
    overtureStates: overtureStates,
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      kTreasuryTradeDealDefaultAdmitted: 100,
      kTreasuryTradeDealDefaultDropped: 100,
      kTreasuryTradeDealDefaultDroppedAlt: 100,
    }).copyWith(carryForwardOffersByFactionId: standingOffers),
  );
}

// --- offerable fabric ---
typedef TreasuryOfferableFabricGp = ({String id, int ow, int fabric, bool regiment});

Game treasuryPlannerOfferableFabricGame(List<TreasuryOfferableFabricGp> gps) {
  final provinces = <Province>[];
  final armies = <Army>[];
  for (final gp in gps) {
    for (var i = 0; i < gp.ow; i++) {
      provinces.add(
        Province(id: 'oldWorld|${gp.id}_$i', regionId: 'oldWorld', ownerId: gp.id),
      );
    }
    if (gp.regiment) {
      armies.add(
        Army(
          id: 'army-${gp.id}',
          ownerId: gp.id,
          regionId: 'oldWorld',
          stationedProvinceId: 'oldWorld|${gp.id}_0',
          regimentUnitIds: ['reg-${gp.id}'],
        ),
      );
    }
  }
  return Game(
    id: 'g-offerable-fabric',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(provinces: []),
      armies: armies,
    ),
    players: [
      for (final gp in gps)
        Player(
          id: gp.id,
          displayName: gp.id,
          isHuman: false,
          stockpile: gp.fabric > 0
              ? Stockpile.empty.applyDelta(
                  CommodityCatalog.fabric.id,
                  gp.fabric,
                )
              : Stockpile.empty,
        ),
    ],
  );
}
