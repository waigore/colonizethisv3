import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

import 'world_market_test_support.dart';

const boycottColonyTradeTribeId = 'tribeT';

/// #3753 R7.3 sell-priority: two GPs bid against minor [minorSellerId] timber.
Game sellPriorityMinorTimberGame({
  required int gpHighRelation,
  required int gpLowRelation,
  required List<OvertureState> overtureStates,
  String minorSellerId = 'M1',
}) {
  return TestFixtures.minimalGame(
    players: const [
      Player(
        id: 'gpHigh',
        displayName: 'GP High',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
      Player(
        id: 'gpLow',
        displayName: 'GP Low',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: frrCreditTestMinorProvinceId,
          regionId: frrCreditTestOw,
          ownerId: 'M1',
        ),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      frrCreditTestOw: {
        frrCreditTestMinorProvinceId: [frrCreditTestTileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gpHigh',
        factionId2: minorSellerId,
        score: gpHighRelation,
      ),
      DiplomacyRelation(
        factionId1: 'gpLow',
        factionId2: minorSellerId,
        score: gpLowRelation,
      ),
    ],
    overtureStates: overtureStates,
  ).copyWith(
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: const {'timber': 10},
    ),
  );
}

/// #3753 R6 boycott: tribe colony offers; boycotted GP bids against gpD.
Game boycottColonyTradeGame({required bool boycottActive}) {
  return TestFixtures.minimalGame(
    players: const [
      Player(
        id: 'gpA',
        displayName: 'GP A',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
      Player(
        id: 'gpB',
        displayName: 'GP B (boycotted)',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
      Player(
        id: 'gpD',
        displayName: 'GP D',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
    ],
    tribes: const [Tribe(id: boycottColonyTradeTribeId, displayName: 'Tribe T')],
  ).copyWith(
    colonyStates: const [
      ColonyState(
        tribeId: boycottColonyTradeTribeId,
        colonyOfGpId: 'gpA',
        sinceTurn: 1,
      ),
    ],
    boycottStates: boycottActive
        ? const [BoycottState(gpId: 'gpA', targetGpId: 'gpB', sinceTurn: 1)]
        : const [],
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: const {'timber': 10},
    ),
  );
}

/// #3753 R3.4b subsidy surcharge: GP [gpA] subsidises minor M1.
Game subsidySurchargeGame({required int subsidyPercent}) {
  return TestFixtures.minimalGame(
    players: const [
      Player(
        id: 'gpA',
        displayName: 'GP A',
        isHuman: true,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: frrCreditTestMinorProvinceId,
          regionId: frrCreditTestOw,
          ownerId: 'M1',
        ),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      frrCreditTestOw: {
        frrCreditTestMinorProvinceId: [frrCreditTestTileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
  ).copyWith(
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: const {'timber': 20},
    ),
    subsidyStates: [
      SubsidyState(payerId: 'gpA', targetId: 'M1', percent: subsidyPercent),
    ],
  );
}

/// #3753 R7.4 GP seller unaffected by sell-priority tiebreaker.
Game sellPriorityGpSellerUnaffectedGame() {
  return TestFixtures.minimalGame(
    players: const [
      Player(
        id: 'gpA',
        displayName: 'GP A',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
      Player(
        id: 'gpSell',
        displayName: 'GP Seller',
        isHuman: false,
        treasury: 0,
        stockpile: Stockpile(quantities: {'timber': 5}),
      ),
      Player(
        id: 'gpZ',
        displayName: 'GP Z',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gpA', factionId2: 'gpSell', score: 10),
      DiplomacyRelation(factionId1: 'gpZ', factionId2: 'gpSell', score: 90),
    ],
  ).copyWith(
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: const {'timber': 10},
    ),
  );
}

/// Tribe timber offer for boycott colony-trade scenarios.
List<TradeOrder> tribeTimberOffer(int quantity) => [
      TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: quantity,
        priority: 1,
      ),
    ];

/// Runs world-market phase with trade orders keyed by faction id.
Game runWorldMarketTradePhase({
  required Game game,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
  MapTopology topology = kEmptyTopology,
  int turnNumber = 3,
}) =>
    runWorldMarketPhase(
      game: game,
      orders: Orders(tradeOrdersByPlayerId: tradeOrdersByPlayerId),
      topology: topology,
      turnNumber: turnNumber,
    );
