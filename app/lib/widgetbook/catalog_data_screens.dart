// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// Extracted out of `catalog_part5.dart` to keep each part fragment file
// under the `repo.part_unit_size` 1000-line ceiling
// (`SPEC/program/part-unit-size.md`).
part of 'catalog.dart';

/// Showcases [CtDropdown] R5c selected-row highlight under the dark
/// editorial-monocle theme. The story preselects a non-null value so
/// opening the picker immediately demonstrates the `--accent-dim` tint
/// + 1 dp `--accent` left-edge border on the row matching that value.
/// Registered as the "CtDropdown — selected-row highlight" use case via
/// `ctDarkThemePrimitiveDirectories` in `catalog_part5.dart`; the class
/// itself lives here so `catalog_part5.dart` stays under the
/// `repo.part_unit_size` 1000-line ceiling.
/// See SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component catalog
/// (CtDropdown) and issue #2859 R5c / S6.
class CtDropdownSelectedRowStory extends StatefulWidget {
  const CtDropdownSelectedRowStory({super.key});

  @override
  State<CtDropdownSelectedRowStory> createState() =>
      CtDropdownSelectedRowStoryState();
}

class CtDropdownSelectedRowStoryState
    extends State<CtDropdownSelectedRowStory> {
  static const List<String> _options = <String>[
    // ignore: avoid_hardcoded_strings_in_widgets
    'England',
    // ignore: avoid_hardcoded_strings_in_widgets
    'France',
    // ignore: avoid_hardcoded_strings_in_widgets
    'Spain',
  ];

  // ignore: avoid_hardcoded_strings_in_widgets
  String? _value = 'France';

  @override
  Widget build(BuildContext context) {
    return CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Tap the trigger — the row matching the current value paints '
            '--accent-dim tint + 1 dp --accent left edge (R5c); other rows '
            'paint a transparent same-width left edge so the layout never '
            'shifts.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 220,
            child: CtDropdown<String>(
              value: _value,
              items: _options,
              // ignore: avoid_hardcoded_strings_in_widgets
              hint: 'Select nation',
              onChanged: (v) => setState(() => _value = v),
            ),
          ),
        ],
      ),
    );
  }
}

Game _diplomacyDetailStoryGame() {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  return Game(
    id: 'wb_diplomacy_detail',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 0),
      Player(id: rivalId, displayName: 'Spain', isHuman: false, treasury: 0),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: humanId,
        factionId2: rivalId,
        score: 70,
        state: RelationState.atPeace,
      ),
    ],
    diplomaticHistoryEvents: [
      DiplomaticEvent(
        turn: 2,
        intraTurnIndex: 0,
        type: DiplomaticEventType.overtureAccepted,
        participants: {humanId, rivalId},
        fromFactionId: humanId,
        toFactionId: rivalId,
        overtureStage: OvertureStage.embassy,
      ),
    ],
    dossierEvidenceEntries: [
      DossierEvidenceEntry(
        observerId: humanId,
        subjectId: rivalId,
        agendaType: 'trade_focus',
        turnNumber: 2,
        description: 'Favoured trade over military buildup.',
      ),
    ],
  );
}

ProviderScope _diplomacyDetailScreenProviderScope() {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  final game = _diplomacyDetailStoryGame();
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: rivalId,
        factionDisplayName: 'Spain',
        kind: FactionKind.greatPower,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

ProviderScope _diplomacyDetailScreenProviderScopeWar() {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  final game = Game(
    id: 'wb_diplomacy_detail_war',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 0),
      Player(id: rivalId, displayName: 'Spain', isHuman: false, treasury: 0),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: humanId,
        factionId2: rivalId,
        score: 25,
        state: RelationState.atWar,
      ),
    ],
    diplomaticHistoryEvents: [
      DiplomaticEvent(
        turn: 4,
        intraTurnIndex: 0,
        type: DiplomaticEventType.declareWar,
        participants: {humanId, rivalId},
        fromFactionId: rivalId,
        toFactionId: humanId,
      ),
      DiplomaticEvent(
        turn: 3,
        intraTurnIndex: 0,
        type: DiplomaticEventType.agreementsClearedOnWar,
        participants: {humanId, rivalId},
        fromFactionId: humanId,
        toFactionId: rivalId,
      ),
    ],
    dossierEvidenceEntries: const [],
  );
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: rivalId,
        factionDisplayName: 'Spain',
        kind: FactionKind.greatPower,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

ProviderScope _diplomacyDetailScreenProviderScopeMinor() {
  const humanId = 'gp_human';
  const minorId = 'minor_venice';
  final game = Game(
    id: 'wb_diplomacy_detail_minor',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 0),
    ],
    minorNations: [MinorNation(id: minorId, displayName: 'Venice')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: humanId,
        factionId2: minorId,
        score: 55,
        state: RelationState.atPeace,
      ),
    ],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
  );
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: minorId,
        factionDisplayName: 'Venice',
        kind: FactionKind.minor,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

/// Diplomacy detail screen stories. SPEC/ui/diplomacy-detail-screen.md.
List<WidgetbookNode> get diplomacyDetailScreenDirectories => [
  WidgetbookFolder(
    name: 'Diplomacy Detail Screen',
    children: [
      WidgetbookUseCase(
        name: 'Default — GP with history and dossier',
        builder: (context) => _diplomacyDetailScreenProviderScope(),
      ),
      WidgetbookUseCase(
        name: 'At war — GP, no dossier',
        builder: (context) => _diplomacyDetailScreenProviderScopeWar(),
      ),
      WidgetbookUseCase(
        name: 'Minor nation — no dossier, empty history',
        builder: (context) => _diplomacyDetailScreenProviderScopeMinor(),
      ),
    ],
  ),
];

Game _tradeScreenStoryGame({
  int treasury = 500,
  Map<CommodityId, int>? stockpile,
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
        stockpile: Stockpile(quantities: stockpile ?? const <CommodityId, int>{}),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: const WorldMarketState(
      prices: prices,
      lastTurnActivity: activity,
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
        currentOrdersProvider
            .overrideWith(() => CurrentOrdersNotifier(initialOrders)),
    ],
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Widget _tradeScreenDefaultStory({
  Orders? initialOrders,
  int treasury = 500,
  Map<CommodityId, int>? stockpile,
}) {
  final game = _tradeScreenStoryGame(treasury: treasury, stockpile: stockpile);
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
  return const <CommodityId, int>{
    'timber': 10,
    'grain': 0,
    'iron': 5,
  };
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
  final Game game =
      _tradeScreenDealBookStoryGame(worldMarketState: worldMarketState);
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
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // initialTabIndex: 1 → Deal Book tab is foregrounded on first
      // mount. Backed by `CtTabStrip.initialTabIndex` (Refs #2993 E7);
      // the production route still uses the default `0` so the
      // existing Market-default contract (E4 ACs) is preserved.
      home: TradeScreen(game: game, player: player, initialTabIndex: 1),
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

/// Story for [CtFullScreenDialogueShell] (issue #2914 S2).
///
/// Demonstrates the reusable scrim + centered [CtDialogShell] shell that
/// the four blocking dialogue overlays (overture, call-to-arms,
/// intervention, game-start intro) now share. The backdrop slot mirrors
/// a "fake game canvas" the scrim dims; the body slot composes a
/// representative title + brass divider + body content stack so the
/// catalog can preview the canonical scrim token, frame, and inner
/// padding from `SPEC/ui/pixel-art-ui-catalog.md` §
/// *CtFullScreenDialogueShell*. Registered as the "CtFullScreenDialogueShell
/// — scrim + framed body" use case via `ctDarkThemePrimitiveDirectories`
/// in `catalog_part5.dart`; the class itself lives here so
/// `catalog_part5.dart` stays under the `repo.part_unit_size` 1000-line
/// ceiling.
class CtFullScreenDialogueShellStory extends StatelessWidget {
  const CtFullScreenDialogueShellStory({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.editorialMonocle,
      child: CtFullScreenDialogueShell(
        backdrop: ColoredBox(
          color: AppThemes.editorialMonocle.scaffoldBackgroundColor,
          child: Center(
            child: Text(
              // ignore: avoid_hardcoded_strings_in_widgets
              'underlying canvas / app shell',
              style: TextStyle(color: EditorialMonoclePalette.muted),
            ),
          ),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              // ignore: avoid_hardcoded_strings_in_widgets
              'Overlay title',
              style: TextStyle(
                color: EditorialMonoclePalette.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05 * 16,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const CtBrassDivider(),
            const SizedBox(height: 12),
            const Text(
              // ignore: avoid_hardcoded_strings_in_widgets
              'Reusable scrim + framed body shared by overture, call-to-arms, intervention, and game-start intro overlays (Refs #2914 S2).',
            ),
          ],
        ),
      ),
    );
  }
}
