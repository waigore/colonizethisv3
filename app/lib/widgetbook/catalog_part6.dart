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
class _CtDropdownSelectedRowStory extends StatefulWidget {
  const _CtDropdownSelectedRowStory();

  @override
  State<_CtDropdownSelectedRowStory> createState() =>
      _CtDropdownSelectedRowStoryState();
}

class _CtDropdownSelectedRowStoryState
    extends State<_CtDropdownSelectedRowStory> {
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
    return _CtDarkPrimitiveScaffold(
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

Game _tradeScreenStoryGame() {
  const humanId = 'gp_human';
  // Seed the world market state so the Refs #2993 E5a read-only
  // commodity table renders representative prices + previous-turn
  // aggregate volumes for a handful of commodities — the remaining
  // rows render the em-dash price glyph + `Bids 0 / Offers 0` zero
  // default so reviewers can see both code paths at a glance.
  const Map<CommodityId, double> prices = <CommodityId, double>{
    'timber': 30.0,
    'iron': 80.0,
    'grain': 50.0,
    'fabric': 120.0,
    'castIron': 175.0,
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
      Player(id: humanId, displayName: 'England', isHuman: true, treasury: 500),
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

Widget _tradeScreenDefaultStory({Orders? initialOrders}) {
  final game = _tradeScreenStoryGame();
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

/// Trade screen stories. SPEC/ui/trade-screen.md.
///
/// Refs #2993 E1+E2+E3+E4 ship the route, screen ID, left-rail button,
/// dark editorial-monocle chrome, and the durable two-tab body. Refs
/// #2993 E5a adds the Market tab's read-only commodity table sourced
/// from `Game.worldMarketState`. Refs #2993 E5b wires the per-row
/// interactive bid/offer/none direction selector and quantity stepper
/// to `currentOrdersProvider`. Refs #2993 E5c (this slice) adds the
/// persistent cross-commodity cargo indicator + cap + saturation
/// warning. The story Game seeds a representative subset of `prices`
/// + `lastTurnActivity` so reviewers can see both the populated and
/// zero-default rendering paths in one scroll; the staged-orders use
/// case additionally seeds a `Bid` on timber and an `Offer` on fabric
/// so the per-row selected chip + non-1 quantity readout render. The
/// cargo-saturated use case seeds bids totalling `defaultCargoHoldsStub`
/// (24) so the indicator reads `Cargo remaining: 0` and the dark-theme
/// `--danger` warning row mounts. The Deal Book tab body remains the
/// placeholder until Refs #2993 E6.
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
class _CtFullScreenDialogueShellStory extends StatelessWidget {
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
