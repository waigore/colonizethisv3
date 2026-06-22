part of 'catalog.dart';

/// Production Panel stories. SPEC/ui/production-panel.md.
List<WidgetbookNode> get productionPanelDirectories => [
  WidgetbookFolder(
    name: 'Production Panel',
    children: [
      WidgetbookUseCase(
        name: 'Full availability',
        builder: (context) => const ProductionPanelStory(
          playerOverride: null,
          useFullAvailability: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Partial availability',
        builder: (context) => const ProductionPanelStory(
          playerOverride: null,
          useFullAvailability: false,
        ),
      ),
      WidgetbookUseCase(
        name: 'Full availability (mobile)',
        builder: (context) => mobileViewport(
          context,
          const ProductionPanelStory(
            playerOverride: null,
            useFullAvailability: true,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Partial availability (mobile)',
        builder: (context) => mobileViewport(
          context,
          const ProductionPanelStory(
            playerOverride: null,
            useFullAvailability: false,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Cotton weaving locked',
        builder: (context) => ProductionPanelStory(
          playerOverride: cottonWeavingLockedProductionPlayer(),
        ),
      ),
      WidgetbookUseCase(
        name: 'Cotton weaving unlocked',
        builder: (context) => ProductionPanelStory(
          playerOverride: cottonWeavingUnlockedProductionPlayer(),
        ),
      ),
    ],
  ),
];

/// Mid-game [TechnologyScreen] fixture (Slots tab default) for Widgetbook.
/// SPEC/ui/technology-panel.md § Widgetbook; Refs #2870 R22 / S9.
Widget _midGameTechnologyScreenStory(BuildContext context) {
  final result = getDebugInitGameResult();
  final game = result.game;
  if (game.players.isEmpty) {
    return Center(child: Text(appL10n(context).widgetbook_noPlayers));
  }
  final basePlayer = game.players.first;
  // Unlock roughly half of all techs (first 22 from catalog order).
  final allIds = techCatalog.keys.toList()..sort();
  final half = (allIds.length / 2).floor();
  final unlockedIds = allIds.take(half).toList();
  final techUnlocked = Map<String, bool>.fromEntries(
    unlockedIds.map((id) => MapEntry(id, true)),
  );
  // One tech in progress (first not-yet-unlocked tech at 60 RP).
  final inProgressId = allIds.length > half ? allIds[half] : null;
  final researchProgressByTechId = inProgressId != null
      ? <String, int>{inProgressId: 60}
      : <String, int>{};
  final midGamePlayer = basePlayer.copyWith(
    techUnlocked: techUnlocked,
    researchProgressByTechId: researchProgressByTechId,
  );
  final midGame = game.copyWith(
    players: [midGamePlayer, ...game.players.skip(1)],
  );
  return TechnologyScreen(game: midGame, player: midGamePlayer);
}

/// Tech Tree Widget stories. SPEC/ui/tech-tree-widget.md.
List<WidgetbookNode> get techTreeDirectories => [
  WidgetbookFolder(
    name: 'Tech Tree',
    children: [
      WidgetbookUseCase(
        name: 'Mid-game (half researched)',
        builder: (context) {
          return MaterialApp(
            theme: AppThemes.editorialMonocle,
            home: Scaffold(body: _midGameTechnologyScreenStory(context)),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Mid-game slots (mobile)',
        builder: (context) => mobileViewport(
          context,
          MaterialApp(
            theme: AppThemes.editorialMonocle,
            home: Scaffold(body: _midGameTechnologyScreenStory(context)),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Tech tree only (mid-game)',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          if (game.players.isEmpty) {
            return Center(child: Text(appL10n(context).widgetbook_noPlayers));
          }
          final basePlayer = game.players.first;
          final allIds = techCatalog.keys.toList()..sort();
          final half = (allIds.length / 2).floor();
          final techUnlocked = Map<String, bool>.fromEntries(
            allIds.take(half).map((id) => MapEntry(id, true)),
          );
          final midGamePlayer = basePlayer.copyWith(techUnlocked: techUnlocked);
          final midGame = game.copyWith(
            players: [midGamePlayer, ...game.players.skip(1)],
          );
          return MaterialApp(
            theme: AppThemes.editorialMonocle,
            home: Scaffold(
              appBar: AppBar(
                title: Text(appL10n(context).widgetbook_techTreeTitle),
              ),
              body: TechTreeWidget(game: midGame, player: midGamePlayer),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Slots — default (3 slots, 4th locked)',
        builder: (context) => _technologySlotsStoryHost(
          context: context,
          variant: _TechnologySlotsStoryVariant.threeActiveFourthLocked,
        ),
      ),
      WidgetbookUseCase(
        name: 'Slots — all 4 slots active',
        builder: (context) => _technologySlotsStoryHost(
          context: context,
          variant: _TechnologySlotsStoryVariant.allFourActive,
        ),
      ),
      WidgetbookUseCase(
        name: 'Slots — no researchable techs',
        builder: (context) => _technologySlotsStoryHost(
          context: context,
          variant: _TechnologySlotsStoryVariant.noResearchableTechs,
        ),
      ),
      WidgetbookUseCase(
        name: 'Slots — funding & turn preview',
        builder: (context) => _technologyFundingPreviewStoryHost(context),
      ),
      WidgetbookUseCase(
        name: 'Slots — funding & turn preview (mobile)',
        builder: (context) => mobileViewport(
          context,
          _technologyFundingPreviewStoryHost(context),
        ),
      ),
      WidgetbookUseCase(
        name: 'Slots — persisted in-progress (no fresh orders)',
        builder: (context) => _technologyPersistedSlotStoryHost(context),
      ),
    ],
  ),
];

/// SPEC/ui/technology-panel.md Slots tab variant selector for Widgetbook
/// stories (Refs #2864 S5). Each variant is mockup-anchored against
/// `SPEC/ui/mockups/GAME40001-technology-panel.html`.
enum _TechnologySlotsStoryVariant {
  /// SPEC § Slot behaviour — locked slot 4 rule: `player.researchSlots = 3`
  /// renders three active slot cards plus a dimmed `Slot 4 (University)`
  /// placeholder.
  threeActiveFourthLocked,

  /// SPEC § Slot behaviour — full unlock: `player.researchSlots = 4` after
  /// University tech renders four active slot cards.
  allFourActive,

  /// SPEC § Choose-tech dialog empty state — every tech is already in
  /// `techUnlocked`, so `researchableTechIds` returns the empty set and the
  /// Choose-tech list collapses to the muted `"No techs available to
  /// research"` line.
  noResearchableTechs,
}

/// Builds the `Tech Tree` Widgetbook host that exercises the dark editorial-
/// monocle `TechnologyScreen` Slots tab for one of the SPEC variants tracked
/// by #2864 S5 / S0. The host pins:
///
///   * `AppThemes.editorialMonocle` — every story renders the dark theme.
///   * `ProviderScope` — `TechnologyScreen` reads `currentOrdersProvider`.
///   * `TechnologyScreen` (not the inner `TechnologyPanel`) — covers both
///     the dark `CtTopBar` chrome and the Slots tab body in one tree.
Widget _technologySlotsStoryHost({
  required BuildContext context,
  required _TechnologySlotsStoryVariant variant,
}) {
  final result = getDebugInitGameResult();
  final game = result.game;
  if (game.players.isEmpty) {
    return Center(child: Text(appL10n(context).widgetbook_noPlayers));
  }
  final basePlayer = game.players.first;
  final (Player storyPlayer, Game storyGame) = _technologySlotsStoryFixture(
    baseGame: game,
    basePlayer: basePlayer,
    variant: variant,
  );
  return ProviderScope(
    child: MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
        body: TechnologyScreen(game: storyGame, player: storyPlayer),
      ),
    ),
  );
}

/// Builds the `(Player, Game)` fixture for a single Slots-tab variant. Kept
/// separate from `_technologySlotsStoryHost` so the same fixture can drive
/// the Widgetbook story renderer and a widget-level regression test without
/// duplicating tech-catalog seeding logic.
(Player, Game) _technologySlotsStoryFixture({
  required Game baseGame,
  required Player basePlayer,
  required _TechnologySlotsStoryVariant variant,
}) {
  final allIds = techCatalog.keys.toList()..sort();
  switch (variant) {
    case _TechnologySlotsStoryVariant.threeActiveFourthLocked:
      // Mid-game-style fixture (~half catalog unlocked, one tech mid-progress)
      // with researchSlots=3 so the fourth slot card renders as the
      // `Slot 4 (University)` locked placeholder per SPEC § Slot behaviour.
      final half = (allIds.length / 2).floor();
      final unlocked = Map<String, bool>.fromEntries(
        allIds.take(half).map((id) => MapEntry(id, true)),
      );
      final inProgressId = allIds.length > half ? allIds[half] : null;
      final progress = inProgressId != null
          ? <String, int>{inProgressId: 60}
          : <String, int>{};
      final player = basePlayer.copyWith(
        techUnlocked: unlocked,
        researchProgressByTechId: progress,
        researchSlots: 3,
      );
      final game = baseGame.copyWith(
        players: [player, ...baseGame.players.skip(1)],
      );
      return (player, game);
    case _TechnologySlotsStoryVariant.allFourActive:
      // Mid-game-style fixture with researchSlots=4 to exercise the
      // SPEC § Slot behaviour "fourth slot fully active" branch (post-
      // University tech).
      final half = (allIds.length / 2).floor();
      final unlocked = Map<String, bool>.fromEntries(
        allIds.take(half).map((id) => MapEntry(id, true)),
      );
      final inProgressId = allIds.length > half ? allIds[half] : null;
      final progress = inProgressId != null
          ? <String, int>{inProgressId: 60}
          : <String, int>{};
      final player = basePlayer.copyWith(
        techUnlocked: unlocked,
        researchProgressByTechId: progress,
        researchSlots: 4,
      );
      final game = baseGame.copyWith(
        players: [player, ...baseGame.players.skip(1)],
      );
      return (player, game);
    case _TechnologySlotsStoryVariant.noResearchableTechs:
      // SPEC § Choose-tech dialog empty state — every tech is already in
      // `techUnlocked`, so `researchableTechIds` is empty. Each slot card
      // renders as an empty `Slot N` row; opening the Choose-tech dialog
      // would show the muted `"No techs available to research"` line.
      final allUnlocked = Map<String, bool>.fromEntries(
        allIds.map((id) => MapEntry(id, true)),
      );
      final player = basePlayer.copyWith(
        techUnlocked: allUnlocked,
        researchSlots: 3,
      );
      final game = baseGame.copyWith(
        players: [player, ...baseGame.players.skip(1)],
      );
      return (player, game);
  }
}

/// Tier-1, prerequisite-free techs assigned to slots 0–2 by the funding /
/// turn-preview story so each active slot renders the funding toggles and the
/// dual-segment (committed + anticipated) progress bar with an RP delta and a
/// gold row. SPEC/ui/technology-panel.md § Widgetbook + § Slot turn preview.
const List<String> _kFundingPreviewTechIds = <String>[
  kTechIdCropRotation,
  kTechIdSawMill,
  kTechIdLandEnclosure,
];

/// Per-slot committed RP for the funding-preview fixture, chosen so each bar
/// shows a non-trivial committed segment A plus headroom for the anticipated
/// segment B (all techs cost 1800 RP at tier 1).
const List<int> _kFundingPreviewCommittedRp = <int>[600, 300, 0];

/// Per-slot funding levels for the funding-preview fixture, exercising the
/// Low / Medium / High toggle-selected chrome and three distinct
/// dual-segment / RP-delta / gold-row renderings.
const List<ResearchFundingLevel> _kFundingPreviewLevels =
    <ResearchFundingLevel>[
      ResearchFundingLevel.medium,
      ResearchFundingLevel.high,
      ResearchFundingLevel.low,
    ];

/// Builds the editable `(Player, Game, Orders)` fixture for the funding /
/// turn-preview story: a player with ample treasury (no debt block) whose
/// first three research slots are assigned prerequisite-free tier-1 techs at
/// varied funding levels with committed progress. Kept separate from the host
/// so the same fixture can drive the Widgetbook story and a widget regression
/// test. SPEC/ui/technology-panel.md § Widgetbook.
({Player player, Game game, Orders orders}) technologyFundingPreviewFixture({
  required Game baseGame,
  required Player basePlayer,
}) {
  final progress = <String, int>{
    for (var i = 0; i < _kFundingPreviewTechIds.length; i++)
      _kFundingPreviewTechIds[i]: _kFundingPreviewCommittedRp[i],
  };
  // Ample treasury keeps every slot above the research debt floor so the
  // anticipated segment B, RP delta, and gold spend all render (no debt block).
  final player = basePlayer.copyWith(
    treasury: 8000,
    researchSlots: 3,
    researchProgressByTechId: progress,
  );
  final game = baseGame.copyWith(
    players: [player, ...baseGame.players.skip(1)],
  );
  final orders = Orders(
    researchOrdersByPlayerId: <String, List<ResearchOrder>>{
      player.id: <ResearchOrder>[
        for (var i = 0; i < _kFundingPreviewTechIds.length; i++)
          ResearchOrder(
            slotIndex: i,
            techId: _kFundingPreviewTechIds[i],
            funding: _kFundingPreviewLevels[i],
          ),
      ],
    },
  );
  return (player: player, game: game, orders: orders);
}

/// Builds the editable `(Player, Game)` fixture for the persisted-occupancy
/// story: a player whose first three research slots are occupied by persisted
/// `researchSlotAssignments` (with accrued progress) but who has **no** fresh
/// `Orders` this turn. Proves an in-progress tech keeps rendering in its slot
/// from the persisted baseline alone (no orphaned "In progress" list).
/// SPEC/ui/technology-panel.md § Slot occupancy + § Widgetbook. Refs #3512.
({Player player, Game game}) technologyPersistedSlotFixture({
  required Game baseGame,
  required Player basePlayer,
}) {
  final progress = <String, int>{
    for (var i = 0; i < _kFundingPreviewTechIds.length; i++)
      _kFundingPreviewTechIds[i]: _kFundingPreviewCommittedRp[i],
  };
  final assignments = <int, ResearchSlotAssignment>{
    for (var i = 0; i < _kFundingPreviewTechIds.length; i++)
      i: ResearchSlotAssignment(
        techId: _kFundingPreviewTechIds[i],
        funding: _kFundingPreviewLevels[i],
      ),
  };
  final player = basePlayer.copyWith(
    treasury: 8000,
    researchSlots: 3,
    researchProgressByTechId: progress,
    researchSlotAssignments: assignments,
  );
  final game = baseGame.copyWith(
    players: [player, ...baseGame.players.skip(1)],
  );
  return (player: player, game: game);
}

/// Builds the persisted-occupancy Widgetbook story host. Renders the inner
/// [TechnologyPanel] with an **empty** `currentOrders` and a non-null
/// `onOrdersChanged`, so the slot cards are populated purely from the
/// persisted `researchSlotAssignments`. SPEC/ui/technology-panel.md
/// § Slot occupancy + § Widgetbook. Refs #3512.
Widget _technologyPersistedSlotStoryHost(BuildContext context) {
  final result = getDebugInitGameResult();
  final game = result.game;
  if (game.players.isEmpty) {
    return Center(child: Text(appL10n(context).widgetbook_noPlayers));
  }
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
      body: _TechnologyPersistedSlotStory(
        baseGame: game,
        basePlayer: game.players.first,
      ),
    ),
  );
}

/// Stateful wrapper holding the (initially empty) [Orders] so cancel / funding
/// interactions on the persisted-occupancy story re-render the panel.
class _TechnologyPersistedSlotStory extends StatefulWidget {
  const _TechnologyPersistedSlotStory({
    required this.baseGame,
    required this.basePlayer,
  });

  final Game baseGame;
  final Player basePlayer;

  @override
  State<_TechnologyPersistedSlotStory> createState() =>
      _TechnologyPersistedSlotStoryState();
}

class _TechnologyPersistedSlotStoryState
    extends State<_TechnologyPersistedSlotStory> {
  late Player _player;
  late Game _game;
  Orders _orders = const Orders();

  @override
  void initState() {
    super.initState();
    final fixture = technologyPersistedSlotFixture(
      baseGame: widget.baseGame,
      basePlayer: widget.basePlayer,
    );
    _player = fixture.player;
    _game = fixture.game;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: TechnologyPanel(
        game: _game,
        player: _player,
        currentOrders: _orders,
        onOrdersChanged: (next) => setState(() => _orders = next),
      ),
    );
  }
}

/// Builds the editable funding / turn-preview Widgetbook story host. Renders
/// the inner [TechnologyPanel] (not the full `TechnologyScreen`) with a
/// non-null `onOrdersChanged`, so the funding toggles and dual-segment turn
/// preview render and respond to taps. SPEC/ui/technology-panel.md
/// § Widgetbook. Refs #3512.
Widget _technologyFundingPreviewStoryHost(BuildContext context) {
  final result = getDebugInitGameResult();
  final game = result.game;
  if (game.players.isEmpty) {
    return Center(child: Text(appL10n(context).widgetbook_noPlayers));
  }
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
      body: _TechnologyFundingPreviewStory(
        baseGame: game,
        basePlayer: game.players.first,
      ),
    ),
  );
}

/// Stateful wrapper that holds the seeded [Orders] so the funding toggles in
/// the Widgetbook story are interactive (tapping a toggle re-renders the slot
/// with the new funding level and refreshed turn preview).
class _TechnologyFundingPreviewStory extends StatefulWidget {
  const _TechnologyFundingPreviewStory({
    required this.baseGame,
    required this.basePlayer,
  });

  final Game baseGame;
  final Player basePlayer;

  @override
  State<_TechnologyFundingPreviewStory> createState() =>
      _TechnologyFundingPreviewStoryState();
}

class _TechnologyFundingPreviewStoryState
    extends State<_TechnologyFundingPreviewStory> {
  late Player _player;
  late Game _game;
  late Orders _orders;

  @override
  void initState() {
    super.initState();
    final fixture = technologyFundingPreviewFixture(
      baseGame: widget.baseGame,
      basePlayer: widget.basePlayer,
    );
    _player = fixture.player;
    _game = fixture.game;
    _orders = fixture.orders;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: TechnologyPanel(
        game: _game,
        player: _player,
        currentOrders: _orders,
        onOrdersChanged: (next) => setState(() => _orders = next),
      ),
    );
  }
}

/// Intervention blocking dialogue. SPEC/ui/screens/pending-intervention-overlay.md.
List<WidgetbookNode> get interventionDialogueDirectories => [
  WidgetbookFolder(
    name: 'Dialogue',
    children: [
      WidgetbookUseCase(
        name: 'InterventionDialogueOverlay',
        builder: (context) {
          final game = Game(
            id: 'wb_iv',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'spain',
                displayName: 'Spain',
                isHuman: false,
                treasury: 0,
              ),
              Player(
                id: 'portugal',
                displayName: 'Portugal',
                isHuman: true,
                treasury: 0,
              ),
            ],
            minorNations: const [
              MinorNation(id: 'minorca', displayName: 'Minorca'),
            ],
          );
          return MaterialApp(
            theme: AppThemes.editorialMonocle,
            home: Scaffold(
              body: InterventionDialogueOverlay(
                game: game,
                prompts: const [
                  InterventionPrompt(
                    aggressorGpId: 'spain',
                    defenderMinorOrTribeId: 'minorca',
                    interveningGpId: 'portugal',
                  ),
                ],
                skipIntroForTest: true,
                onDecisions: (_) {},
                child: Center(
                  child: Text(appL10n(context).widgetbook_gameShell),
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
];

/// Turn news dialog. SPEC/ui/turn-news-dialog.md.
List<WidgetbookNode> get turnNewsDialogDirectories => [
  WidgetbookFolder(
    name: 'Turn news',
    children: [
      WidgetbookUseCase(
        name: 'Sample lines',
        builder: (context) {
          final game = Game(
            id: 'wb_news',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: 'oldWorld|P1',
                    regionId: 'oldWorld',
                    ownerId: 'gp1',
                    displayName: 'Sample Province',
                  ),
                ],
              ),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                treasury: 0,
              ),
              Player(
                id: 'gp2',
                displayName: 'Portugal',
                isHuman: false,
                treasury: 0,
              ),
            ],
          );
          final digest = TurnNewsDigest(
            resolvedTurnNumber: 2,
            lines: [
              const TurnNewsDiplomacyLine(
                factionIdA: 'gp1',
                factionIdB: 'gp2',
                kind: TurnNewsDiplomacyKind.war,
              ),
              const TurnNewsProvinceDiscoveredLine(provinceId: 'oldWorld|P1'),
            ],
          );
          return MaterialApp(
            theme: AppThemes.editorialMonocle,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: TurnNewsDialog(
                  game: game,
                  digest: digest,
                  newTurnNumber: 3,
                ),
              ),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Empty digest',
        builder: (context) {
          final game = Game(
            id: 'wb_news_e',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                treasury: 0,
              ),
            ],
          );
          return MaterialApp(
            theme: AppThemes.editorialMonocle,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: TurnNewsDialog(
                  game: game,
                  digest: const TurnNewsDigest(
                    resolvedTurnNumber: 1,
                    lines: [],
                  ),
                  newTurnNumber: 2,
                ),
              ),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Mobile viewport',
        builder: (context) {
          final game = Game(
            id: 'wb_news_m',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'gp1',
                displayName: 'Spain',
                isHuman: true,
                treasury: 0,
              ),
            ],
          );
          return mobileViewport(
            context,
            MaterialApp(
              theme: AppThemes.editorialMonocle,
              localizationsDelegates:
                  AppLocalizationsBinding.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Center(
                  child: TurnNewsDialog(
                    game: game,
                    digest: const TurnNewsDigest(
                      resolvedTurnNumber: 1,
                      lines: [],
                    ),
                    newTurnNumber: 2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
];

/// Military Units Panel stories. SPEC/ui/military-units-panel.md.
List<WidgetbookNode> get militaryUnitsPanelDirectories => [
  WidgetbookFolder(
    name: 'Military Units Panel',
    children: [
      WidgetbookUseCase(
        name: 'Standalone',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.first.id
              : 'gp1';
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: MilitaryUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: AppEventBus.create(),
              topology: result.combinedTopology,
              draftOrders: const Orders(),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'With map',
        builder: (context) => const MilitaryPanelWithMapStory(),
      ),
      WidgetbookUseCase(
        // Narrow sizing contract (Refs #3627 AC6): full viewport width ×
        // 50% height cap from `unitsPanelSheetConstraints` at 360 × 640 dp.
        name: 'Mobile (360x640)',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.first.id
              : 'gp1';
          return mobileViewport(
            context,
            ConstrainedBox(
              constraints: unitsPanelSheetConstraints(const Size(360, 640)),
              child: MilitaryUnitsPanel(
                game: game,
                humanPlayerId: humanPlayerId,
                bus: AppEventBus.create(),
                topology: result.combinedTopology,
                draftOrders: const Orders(),
              ),
            ),
          );
        },
      ),
    ],
  ),
];

/// Naval Units Panel stories. SPEC/ui/naval-units-panel.md.
List<WidgetbookNode> get navalUnitsPanelDirectories => [
  WidgetbookFolder(
    name: 'Naval Units Panel',
    children: [
      WidgetbookUseCase(
        name: 'Standalone',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.first.id
              : 'gp1';
          // The naval panel width is host-governed in production via
          // `unitsPanelSheetConstraints` (70% wide / full-width narrow,
          // Refs #3627); this standalone story pins a 480 dp host so
          // reviewers see the dense R25 action cluster (Move + Split +
          // Locate on one row), the R26 `HOME` chip on the Home Fleet row,
          // and the R28 `(in port)` / `(at sea)` location qualifier produced
          // by `naval_tree_builder.dart`.
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
            child: NavalUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: AppEventBus.create(),
              topology: result.combinedTopology,
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'With map',
        builder: (context) => const NavalPanelWithMapStory(),
      ),
      WidgetbookUseCase(
        // Narrow sizing contract (Refs #3627 AC6): full viewport width ×
        // 50% height cap from `unitsPanelSheetConstraints` at 360 × 640 dp
        // (naval shares the same rule, no fixed sidebar).
        name: 'Mobile (360x640)',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.first.id
              : 'gp1';
          return mobileViewport(
            context,
            ConstrainedBox(
              constraints: unitsPanelSheetConstraints(const Size(360, 640)),
              child: NavalUnitsPanel(
                game: game,
                humanPlayerId: humanPlayerId,
                bus: AppEventBus.create(),
                topology: result.combinedTopology,
              ),
            ),
          );
        },
      ),
    ],
  ),
];
