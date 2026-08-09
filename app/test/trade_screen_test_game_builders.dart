// TradeScreen widget-test Game builders (Refs #3952, #4240 slice E).
//
// Owns parameterized `Game` factories and stockpile helpers so
// `trade_screen_test_support.dart` stays under the wave-12 support ceiling.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_fixtures/trade.dart';

/// Canonical human GP id used by Market-tab / Deal Book / E8 standalone hosts.
const String kTradeTestHumanPlayerId = 'gp_h';

/// Capital province id used when seeding a synthetic home fleet for cargo-cap
/// pins (`tradeCargoCapacityOverride == 10`).
const String kTradeTestCapitalProvinceId = 'oldWorld|cap1';

/// Purchased-tile key for first-right Market cue pins (Refs #4226).
const String kTradeTestFirstRightTileKey = 'oldWorld|M1|0|0';

/// Stockpile map covering every tradeable commodity at [quantity] (excludes
/// riches and `spices`). Used by Offer-side interactive suites so the sellable
/// clamp does not zero out default Offer taps.
Map<CommodityId, int> tradeableStockpileFilled(int quantity) {
  return <CommodityId, int>{
    for (final Commodity c in CommodityCatalog.all)
      if (c.category != CommodityCategory.riches && c.id != 'spices')
        c.id: quantity,
  };
}

/// Parameterized lightweight [Game] for TradeScreen widget tests.
///
/// Defaults match the Market-tab family (`gp_h`, treasury 500, empty regions).
/// Pass [players] / [worldMarketState] / [fleets] / [oldWorld] when a suite
/// needs foreign GPs, carry-forwards, or a home fleet for cargo capacity.
Game buildTradeTestGame({
  String id = 'test_trade_screen',
  String playerId = kTradeTestHumanPlayerId,
  String displayName = 'England',
  int treasury = 500,
  Map<CommodityId, int>? stockpile,
  Map<CommodityId, int>? prices,
  Map<CommodityId, MarketActivity>? lastTurnActivity,
  Map<String, List<TradeOrder>> carryForwardBids =
      const <String, List<TradeOrder>>{},
  Map<String, List<TradeOrder>> carryForwardOffers =
      const <String, List<TradeOrder>>{},
  List<Player>? players,
  List<Fleet> fleets = const <Fleet>[],
  RegionData oldWorld = const RegionData(),
  RegionData newWorld = const RegionData(),
  WorldMarketState? worldMarketState,
  List<OvertureState> overtureStates = const <OvertureState>[],
  Map<String, bool>? techUnlocked,
  Map<String, String> purchasedTilesByTileKey = const <String, String>{},
  Map<String, String> resourceByTileKey = const <String, String>{},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const <String, Map<String, List<String>>>{},
  List<MinorNation> minorNations = const <MinorNation>[],
  Map<String, List<OverseasProfitCreditRecord>>
      lastTurnOverseasProfitCreditsByGpId =
      const <String, List<OverseasProfitCreditRecord>>{},
  /// When `10`, seeds a galleon+fluyte home fleet (cargoHold 6+4). Other
  /// values throw — only the E5c / E8 cargo-cap mapping is supported.
  int? tradeCargoCapacityOverride,
}) {
  final List<Fleet> resolvedFleets = List<Fleet>.of(fleets);
  RegionData resolvedOldWorld = oldWorld;
  if (tradeCargoCapacityOverride != null) {
    final int galleonHolds = NavalStatsCatalog.galleon.cargoHold;
    final int fluyteHolds = NavalStatsCatalog.fluyte.cargoHold;
    if (galleonHolds + fluyteHolds != 10) {
      throw StateError(
        'NavalStatsCatalog cargoHold drift: '
        'galleon=$galleonHolds + fluyte=$fluyteHolds != 10. '
        'Update the override mapping in trade_screen_test_game_builders.dart.',
      );
    }
    if (tradeCargoCapacityOverride != 10) {
      throw StateError(
        'Only tradeCargoCapacityOverride == 10 is currently supported '
        'by trade_screen_test_game_builders.',
      );
    }
    resolvedFleets.add(
      Fleet(
        id: homeFleetIdFor(playerId),
        ownerId: playerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: kTradeTestCapitalProvinceId,
        ships: const [
          ShipInstance(id: 'h1', typeId: 'galleon'),
          ShipInstance(id: 'h2', typeId: 'fluyte'),
        ],
      ),
    );
    if (resolvedOldWorld.provinces.isEmpty) {
      resolvedOldWorld = const RegionData(
        provinces: [
          Province(
            id: 'cap1',
            regionId: 'oldWorld',
            // ignore: avoid_hardcoded_strings_in_widgets
            displayName: 'Capital',
          ),
        ],
      );
    }
  }

  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: resolvedOldWorld,
      newWorld: newWorld,
      fleets: resolvedFleets,
      purchasedTilesByTileKey: purchasedTilesByTileKey,
      resourceByTileKey: resourceByTileKey,
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players:
        players ??
        [
          Player(
            id: playerId,
            // ignore: avoid_hardcoded_strings_in_widgets
            displayName: displayName,
            isHuman: true,
            treasury: treasury,
            techUnlocked: techUnlocked,
            stockpile: Stockpile(
              quantities: stockpile ?? const <CommodityId, int>{},
            ),
          ),
        ],
    minorNations: minorNations,
    overtureStates: overtureStates,
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState:
        worldMarketState ??
        WorldMarketState(
          prices: prices ?? const <CommodityId, int>{},
          lastTurnActivity:
              lastTurnActivity ?? const <CommodityId, MarketActivity>{},
          carryForwardBidsByFactionId: carryForwardBids,
          carryForwardOffersByFactionId: carryForwardOffers,
          lastTurnOverseasProfitCreditsByGpId:
              lastTurnOverseasProfitCreditsByGpId,
        ),
  );
}

/// Game with one still-valid purchased timber tile for the human GP (Refs #4226).
Game buildTradeTestGameWithTimberFirstRight() {
  return buildTradeTestGame(
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: 'oldWorld|M1',
          regionId: 'oldWorld',
          ownerId: 'M1',
          townDevelopmentLevel: 1,
        ),
      ],
    ),
    minorNations: const [
      MinorNation(
        id: 'M1',
        displayName: 'Minor 1',
        capitalProvinceId: 'oldWorld|M1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|M1',
          x: 0,
          y: 0,
        ),
      ),
    ],
    purchasedTilesByTileKey: const {
      kTradeTestFirstRightTileKey: kTradeTestHumanPlayerId,
    },
    resourceByTileKey: const {kTradeTestFirstRightTileKey: 'timber'},
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        'oldWorld|M1': [kTradeTestFirstRightTileKey],
      },
    },
  );
}

/// Scaffold / 320 dp pin fixture — delegates to [buildTradePanelTestGame].
Game buildTradeScaffoldTestGame() => buildTradePanelTestGame();
