// Extracted from catalog_data_screens.dart to keep each part fragment file
// under the repo.part_unit_size 1000-line ceiling (SPEC/program/part-unit-size.md).
part of 'catalog.dart';

Game _tradeScreenStoryGame({
  int treasury = 500,
  Map<CommodityId, int>? stockpile,
  List<OvertureState> overtureStates = const <OvertureState>[],
  Map<String, bool>? techUnlocked,
}) {
  const humanId = 'gp_human';
  // Seed the world market state so the Refs #2993 E5a read-only
  // commodity table renders representative prices + previous-turn
  // aggregate volumes for a handful of commodities — the remaining
  // rows render the em-dash price glyph + `Bids 0 / Offers 0` zero
  // default so reviewers can see both code paths at a glance.
  // Post-#3093: WorldMarketState.prices is `Map<CommodityId, int>` (floored at
  // persistence boundary per SPEC/game/world-market.md § Price discovery).
  const Map<CommodityId, int> prices = <CommodityId, int>{
    'timber': 30,
    'iron': 80,
    'grain': 50,
    'fabric': 120,
    'castIron': 175,
  };
  const Map<CommodityId, MarketActivity> activity =
      <CommodityId, MarketActivity>{
        'timber': MarketActivity(totalBidQuantity: 12, totalOfferQuantity: 8),
        'iron': MarketActivity(totalBidQuantity: 5, totalOfferQuantity: 14),
        'grain': MarketActivity(totalBidQuantity: 18, totalOfferQuantity: 18),
      };
  return Game(
    id: 'wb_trade_screen',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(
        id: humanId,
        displayName: 'England',
        isHuman: true,
        treasury: treasury,
        techUnlocked: techUnlocked,
        stockpile: Stockpile(
          quantities: stockpile ?? const <CommodityId, int>{},
        ),
      ),
    ],
    overtureStates: overtureStates,
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: const WorldMarketState(
      prices: prices,
      lastTurnActivity: activity,
    ),
  );
}

/// Story Game with one still-valid purchased timber tile for the human GP
/// so reviewers see the Market first-right chip (Refs #4226).
Game _tradeScreenStoryFirstRightGame() {
  const String tileKey = 'oldWorld|M1|0|0';
  return Game(
    id: 'wb_trade_screen_first_right',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
      newWorld: const RegionData(),
      purchasedTilesByTileKey: const {tileKey: 'gp_human'},
      resourceByTileKey: const {tileKey: 'timber'},
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          'oldWorld|M1': [tileKey],
        },
      },
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: const [
      Player(
        id: 'gp_human',
        displayName: 'England',
        isHuman: true,
        treasury: 500,
        stockpile: Stockpile(
          quantities: <CommodityId, int>{'timber': 10},
        ),
      ),
    ],
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
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: const WorldMarketState(
      prices: <CommodityId, int>{'timber': 30},
    ),
  );
}

ProviderScope _tradeScreenProviderScope({
  required Widget child,
  Orders? initialOrders,
}) {
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
      if (initialOrders != null)
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(initialOrders),
        ),
    ],
    child: widgetbookEditorialMonocleApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      useScaffold: false,
      child: child,
    ),
  );
}

Widget _tradeScreenDefaultStory({
  Orders? initialOrders,
  int treasury = 500,
  Map<CommodityId, int>? stockpile,
  List<OvertureState> overtureStates = const <OvertureState>[],
  Map<String, bool>? techUnlocked,
  Game? gameOverride,
}) {
  final game = gameOverride ??
      _tradeScreenStoryGame(
        treasury: treasury,
        stockpile: stockpile,
        overtureStates: overtureStates,
        techUnlocked: techUnlocked,
      );
  final player = game.players.first;
  return _tradeScreenProviderScope(
    initialOrders: initialOrders,
    child: TradeScreen(game: game, player: player),
  );
}

/// Pre-staged Orders snapshot used by the "Market tab — staged bid +
/// offer (Refs #2993 E5b)" use case so reviewers see both an active
/// `Bid` direction and an active `Offer` direction with non-default
/// quantities, mirroring what a player who has interacted with the
/// row controls would see when they re-open the screen.
Orders _tradeScreenStoryStagedOrders() {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp_human': <TradeOrder>[
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 4,
          priority: 1,
        ),
        TradeOrder(
          commodityId: 'fabric',
          type: TradeOrderType.offer,
          quantity: 7,
          priority: 1,
        ),
      ],
    },
  );
}

/// Pre-staged Orders snapshot used by the "Market tab — cargo
/// saturated (Refs #2993 E5c)" use case so reviewers see the
/// `Cargo remaining: 0` indicator alongside the dark-theme `--danger`
/// warning row without having to drive the stepper themselves. The
/// story Game has no home fleet so `cargoHoldsForHomeFleet` falls back
/// to `defaultCargoHoldsStub = 24`; saturating bids therefore total
/// 24 across four commodities to leave room for offers on the rest.
/// Stockpile snapshot for the "Market tab — sectioned grouping (Refs
/// #3093)" use case: non-zero quantities in each category so reviewers
/// see Food / Raw Materials / Manufactured headers with populated rows.
Map<CommodityId, int> _tradeScreenStorySectionedStockpile() {
  return const <CommodityId, int>{
    'grain': 42,
    'meat': 18,
    'timber': 10,
    'iron': 25,
    'fabric': 50,
    'lumber': 12,
  };
}

/// Pre-staged Orders for the "Market tab — sellable clamp (Refs #3093)"
/// use case: timber offer qty 2 against stockpile 10 → `(8)` readout;
/// grain stockpile 0 → disabled Offer chip.
Orders _tradeScreenStorySellableClampOrders() {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp_human': <TradeOrder>[
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 2,
          priority: 1,
        ),
      ],
    },
  );
}

Map<CommodityId, int> _tradeScreenStorySellableClampStockpile() {
  return const <CommodityId, int>{'timber': 10, 'grain': 0, 'iron': 5};
}

/// Pre-staged Orders for the "Market tab — treasury bid cap (Refs #3093)"
/// use case: treasury 100 with a timber bid consuming 90 of the budget so
/// a fresh iron bid (price 80) cannot stage — mirrors the widget test pin.
Orders _tradeScreenStoryTreasuryBidCapOrders() {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp_human': <TradeOrder>[
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 3,
          priority: 1,
        ),
      ],
    },
  );
}

/// Pre-staged Orders for the "Market tab — bid budget saturated (Refs
/// #4186)" use case: treasury 90 with a timber bid consuming the full
/// budget so reviewers see `Bid budget: 0 of 90` and the treasury
/// bid-limit warning — mirrors the widget test pin.
Orders _tradeScreenStoryBidBudgetSaturatedOrders() {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp_human': <TradeOrder>[
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 3,
          priority: 1,
        ),
      ],
    },
  );
}

/// Pre-staged Orders for the "Market tab — bid-type saturated (Refs
/// #4170)" use case: cap `3` with three distinct bids so reviewers see
/// `Bid goods: 3 of 3`, the neutral warning, and disabled fresh Bid
/// chips on other commodities.
Orders _tradeScreenStoryBidTypeSaturatedOrders() {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp_human': <TradeOrder>[
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 2,
          priority: 1,
        ),
        TradeOrder(
          commodityId: 'iron',
          type: TradeOrderType.bid,
          quantity: 1,
          priority: 1,
        ),
        TradeOrder(
          commodityId: 'grain',
          type: TradeOrderType.bid,
          quantity: 1,
          priority: 1,
        ),
      ],
    },
  );
}

Orders _tradeScreenStoryCargoSaturatedOrders() {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp_human': <TradeOrder>[
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 8,
          priority: 1,
        ),
        TradeOrder(
          commodityId: 'iron',
          type: TradeOrderType.bid,
          quantity: 6,
          priority: 1,
        ),
        TradeOrder(
          commodityId: 'grain',
          type: TradeOrderType.bid,
          quantity: 6,
          priority: 1,
        ),
        TradeOrder(
          commodityId: 'castIron',
          type: TradeOrderType.bid,
          quantity: 4,
          priority: 1,
        ),
        TradeOrder(
          commodityId: 'fabric',
          type: TradeOrderType.offer,
          quantity: 7,
          priority: 1,
        ),
      ],
    },
  );
}

/// Synthetic [Game] for the Deal Book tab Widgetbook stories
/// (Refs #2993 E7). Mirrors the real-game shape used by the trade
/// screen runtime: the human player `gp_human` plus a foreign GP
/// `gp_aragon` so deals can carry distinct buyer/seller faction ids
/// without leaking foreign carry-forwards into the human Deal Book
/// (per `SPEC/ui/trade-screen.md` § Deal Book tab — live two-panel
/// ledger). Callers supply the `worldMarketState` payload so each
/// story pins the scenario it cares about (empty / mixed) without
/// duplicating the player setup boilerplate.
Game _tradeScreenDealBookStoryGame({
  required WorldMarketState worldMarketState,
}) {
  return Game(
    id: 'wb_trade_screen_deal_book',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(
        id: 'gp_human',
        // ignore: avoid_hardcoded_strings_in_widgets
        displayName: 'England',
        isHuman: true,
        treasury: 500,
      ),
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(
        id: 'gp_aragon',
        // ignore: avoid_hardcoded_strings_in_widgets
        displayName: 'Aragon',
        isHuman: false,
        treasury: 500,
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: worldMarketState,
  );
}

/// `WorldMarketState` for the empty Deal Book story — no filled deals
/// and no carry-forwards. Proves the per-side empty-state copy
/// (`dealBookBidsEmpty` / `dealBookOffersEmpty`) renders together with
/// the always-mounted `Total spent: 0` / `Total received: 0` rows
/// (Refs #2993 E6).
WorldMarketState _tradeScreenDealBookEmptyState() {
  return const WorldMarketState();
}

/// `WorldMarketState` for the overseas-profit Deal Book story (Refs #4226).
WorldMarketState _tradeScreenDealBookOverseasProfitState() {
  return const WorldMarketState(
    lastTurnOverseasProfitCreditsByGpId: <String, List<OverseasProfitCreditRecord>>{
      'gp_human': <OverseasProfitCreditRecord>[
        OverseasProfitCreditRecord(
          creditKind: OverseasProfitCreditKind.tileOwnerShare,
          commodityId: 'timber',
          quantity: 5,
          profitTreasury: 15,
          buyerFactionId: 'gp_aragon',
          sourceFactionId: 'M1',
        ),
      ],
    },
  );
}

/// `WorldMarketState` for the mixed Deal Book story — one FRR-tagged
/// buy, one FTP-tagged buy, two filled sales, and a mix of carry
/// forward bids/offers on both sides. Mirrors the realistic resolved
/// turn shape so reviewers can verify the dark-theme tag rendering,
/// the totals math (`qty × price`), and the player-isolation filter
/// (the foreign carry-forward on `gp_aragon` must not appear in the
/// human Deal Book).
WorldMarketState _tradeScreenDealBookMixedState() {
  const String human = 'gp_human';
  const String foreign = 'gp_aragon';
  const Map<CommodityId, MarketActivity> activity =
      <CommodityId, MarketActivity>{
        'timber': MarketActivity(
          totalBidQuantity: 6,
          totalOfferQuantity: 0,
          filledQuantity: 6,
          deals: <FilledDeal>[
            FilledDeal(
              sellerFactionId: foreign,
              buyerFactionId: human,
              commodityId: 'timber',
              quantity: 3,
              pricePerUnit: 30.0,
              isFirstRightOfRefusalMatch: true,
            ),
            FilledDeal(
              sellerFactionId: foreign,
              buyerFactionId: human,
              commodityId: 'timber',
              quantity: 3,
              pricePerUnit: 30.0,
              isFtpMatch: true,
            ),
          ],
        ),
        'iron': MarketActivity(
          totalBidQuantity: 4,
          totalOfferQuantity: 4,
          filledQuantity: 4,
          deals: <FilledDeal>[
            FilledDeal(
              sellerFactionId: human,
              buyerFactionId: foreign,
              commodityId: 'iron',
              quantity: 4,
              pricePerUnit: 80.0,
            ),
          ],
        ),
        'fabric': MarketActivity(
          totalBidQuantity: 0,
          totalOfferQuantity: 7,
          filledQuantity: 7,
          deals: <FilledDeal>[
            FilledDeal(
              sellerFactionId: human,
              buyerFactionId: foreign,
              commodityId: 'fabric',
              quantity: 7,
              pricePerUnit: 120.0,
              isFtpMatch: true,
            ),
          ],
        ),
      };
  // `TradeOrder` runs runtime validation in its constructor so its
  // instances are not `const`. The carry-forward maps therefore must
  // be plain (non-const) literals; `lastTurnActivity` stays `const`
  // because `FilledDeal` and `MarketActivity` both expose `const`
  // constructors.
  return WorldMarketState(
    lastTurnActivity: activity,
    carryForwardBidsByFactionId: <String, List<TradeOrder>>{
      human: <TradeOrder>[
        TradeOrder(
          commodityId: 'grain',
          type: TradeOrderType.bid,
          quantity: 8,
          priority: 2,
        ),
      ],
    },
    carryForwardOffersByFactionId: <String, List<TradeOrder>>{
      human: <TradeOrder>[
        TradeOrder(
          commodityId: 'castIron',
          type: TradeOrderType.offer,
          quantity: 4,
          priority: 1,
        ),
      ],
      // Foreign carry-forward — must not surface in the human Deal Book
      // because `_DealBookViewData.build` keys by playerId. Included
      // here so reviewers can verify the player-isolation filter.
      foreign: <TradeOrder>[
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 99,
          priority: 1,
        ),
      ],
    },
  );
}

ProviderScope _tradeScreenDealBookProviderScope({
  required WorldMarketState worldMarketState,
}) {
  final Game game = _tradeScreenDealBookStoryGame(
    worldMarketState: worldMarketState,
  );
  final Player player = game.players.firstWhere(
    (p) => p.isHuman,
    orElse: () => game.players.first,
  );
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: widgetbookEditorialMonocleApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      useScaffold: false,
      // initialTabIndex: 1 → Deal Book tab is foregrounded on first
      // mount. Backed by `CtTabStrip.initialTabIndex` (Refs #2993 E7);
      // the production route still uses the default `0` so the
      // existing Market-default contract (E4 ACs) is preserved.
      child: TradeScreen(game: game, player: player, initialTabIndex: 1),
    ),
  );
}

/// Trade screen stories. SPEC/ui/trade-screen.md.
///
/// Refs #2993 E1+E2+E3+E4 ship the route, screen ID, left-rail button,
/// dark editorial-monocle chrome, and the durable two-tab body. Refs
/// #2993 E5a adds the Market tab's read-only commodity table sourced
/// from `Game.worldMarketState`. Refs #2993 E5b wires the per-row
/// interactive bid/offer/none direction selector and quantity stepper
/// to `currentOrdersProvider`. Refs #2993 E5c adds the persistent
/// cross-commodity cargo indicator + cap + saturation warning. Refs
/// #2993 E6 swaps the Deal Book placeholder for the live two-panel
/// ledger sourced from `Game.worldMarketState.lastTurnActivity[*].deals`
/// and `carryForward{Bids,Offers}ByFactionId[playerId]`. Refs #2993 E7
/// (this slice) registers the recommended Deal Book Widgetbook stories
/// — empty, mixed fills + carry-forwards, and mobile (stacked) — so
/// reviewers can audit the live ledger chrome without driving the tab
/// strip themselves; each Deal Book use case opts into the secondary
/// tab via `TradeScreen.initialTabIndex: 1` rather than simulating a
/// label tap.
List<WidgetbookNode> get tradeScreenDirectories => [
  WidgetbookFolder(
    name: 'Trade Screen',
    children: [
      WidgetbookUseCase(
        name: 'Scaffold (Market tab)',
        builder: (context) => _tradeScreenDefaultStory(),
      ),
      WidgetbookUseCase(
        name: 'Scaffold (mobile)',
        builder: (context) =>
            mobileViewport(context, _tradeScreenDefaultStory()),
      ),
      WidgetbookUseCase(
        name: 'Market tab — staged bid + offer (Refs #2993 E5b)',
        builder: (context) => _tradeScreenDefaultStory(
          initialOrders: _tradeScreenStoryStagedOrders(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — cargo saturated (Refs #2993 E5c)',
        builder: (context) => _tradeScreenDefaultStory(
          initialOrders: _tradeScreenStoryCargoSaturatedOrders(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — sectioned grouping (Refs #3093)',
        builder: (context) => _tradeScreenDefaultStory(
          stockpile: _tradeScreenStorySectionedStockpile(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — wide two-column (Refs #4227)',
        builder: (context) => _tradeScreenDefaultStory(
          stockpile: _tradeScreenStorySectionedStockpile(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — narrow stacked rows (Refs #4227)',
        builder: (context) => mobileViewport(
          context,
          _tradeScreenDefaultStory(
            stockpile: _tradeScreenStorySectionedStockpile(),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — first-right chip (Refs #4226)',
        builder: (context) => _tradeScreenDefaultStory(
          gameOverride: _tradeScreenStoryFirstRightGame(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — sellable clamp (Refs #3093)',
        builder: (context) => _tradeScreenDefaultStory(
          stockpile: _tradeScreenStorySellableClampStockpile(),
          initialOrders: _tradeScreenStorySellableClampOrders(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — treasury bid cap (Refs #3093)',
        builder: (context) => _tradeScreenDefaultStory(
          treasury: 100,
          initialOrders: _tradeScreenStoryTreasuryBidCapOrders(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — bid budget saturated (Refs #4186)',
        builder: (context) => _tradeScreenDefaultStory(
          treasury: 90,
          initialOrders: _tradeScreenStoryBidBudgetSaturatedOrders(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — bid-type saturated (Refs #4170)',
        builder: (context) => _tradeScreenDefaultStory(
          initialOrders: _tradeScreenStoryBidTypeSaturatedOrders(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — bid-type cap 3 baseline (Refs #4170, #4186)',
        builder: (context) => _tradeScreenDefaultStory(),
      ),
      WidgetbookUseCase(
        name: 'Market tab — bid-type cap 6 Trade Fairs (Refs #4170, #4186)',
        builder: (context) => _tradeScreenDefaultStory(
          techUnlocked: const <String, bool>{kTechIdTradeFairs: true},
        ),
      ),
      WidgetbookUseCase(
        name: 'Market tab — trade counsel stars (Refs #4282)',
        builder: (context) => _tradeScreenDefaultStory(
          stockpile: const <CommodityId, int>{'timber': 80},
        ),
      ),
      WidgetbookUseCase(
        name: 'Deal Book tab — empty (Refs #2993 E7)',
        builder: (context) => _tradeScreenDealBookProviderScope(
          worldMarketState: _tradeScreenDealBookEmptyState(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Deal Book tab — mixed fills + carry-forwards (Refs #2993 E7)',
        builder: (context) => _tradeScreenDealBookProviderScope(
          worldMarketState: _tradeScreenDealBookMixedState(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Deal Book tab — overseas profit ledger (Refs #4226)',
        builder: (context) => _tradeScreenDealBookProviderScope(
          worldMarketState: _tradeScreenDealBookOverseasProfitState(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Deal Book tab — mobile (stacked) (Refs #2993 E7)',
        builder: (context) => mobileViewport(
          context,
          _tradeScreenDealBookProviderScope(
            worldMarketState: _tradeScreenDealBookMixedState(),
          ),
        ),
      ),
    ],
  ),
];
