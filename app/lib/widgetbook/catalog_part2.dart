part of 'catalog.dart';

/// Production Panel stories. SPEC/ui/production-panel.md.
List<WidgetbookNode> get productionPanelDirectories => [
  WidgetbookFolder(
    name: 'Production Panel',
    children: [
      WidgetbookUseCase(
        name: 'Full availability',
        builder: (context) => const _ProductionPanelStory(
          playerOverride: null,
          useFullAvailability: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Partial availability',
        builder: (context) => const _ProductionPanelStory(
          playerOverride: null,
          useFullAvailability: false,
        ),
      ),
      WidgetbookUseCase(
        name: 'Full availability (mobile)',
        builder: (context) => mobileViewport(
          context,
          const _ProductionPanelStory(
            playerOverride: null,
            useFullAvailability: true,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Partial availability (mobile)',
        builder: (context) => mobileViewport(
          context,
          const _ProductionPanelStory(
            playerOverride: null,
            useFullAvailability: false,
          ),
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
        builder: (context) => const _MilitaryPanelWithMapStory(),
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
          // Mockup `UNIT30001` clamps the panel sidebar to ~340 dp;
          // 480 dp here keeps the standalone story comfortably inside
          // `_panelConstraints` (420–640 dp) so reviewers see the dense
          // R25 action cluster (Move + Split + Locate on one row), the
          // R26 `HOME` chip on the Home Fleet row, and the R28
          // `(in port)` / `(at sea)` location qualifier produced by
          // `naval_tree_builder.dart`.
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
        builder: (context) => const _NavalPanelWithMapStory(),
      ),
    ],
  ),
];

/// Diplomacy Panel stories. SPEC/ui/diplomacy-panel.md.
List<WidgetbookNode> get diplomacyPanelDirectories => [
  WidgetbookFolder(
    name: 'Diplomacy Panel',
    children: [
      WidgetbookUseCase(
        name: 'With real game',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.first.id
              : 'gp1';
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: DiplomacyPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              topology: result.combinedTopology,
              currentOrders: const Orders(),
              bus: AppEventBus(),
            ),
          );
        },
      ),
      // SPEC/ui/diplomacy-panel.md § Widgetbook — empty-state story.
      // Renders the panel against a Game whose human player has no
      // diplomacy relations with any other faction (no other Great
      // Power, Minor Nation, or Tribe), so `buildDiplomacyRows` returns
      // an empty list and the panel paints the three always-visible
      // section headings plus their per-section empty placeholders —
      // including the `diplomacy_panel_noTribes` ("No tribes contacted
      // yet.") copy — under the editorial-monocle dark chrome.
      // Refs #2863 S7 / #3341.
      WidgetbookUseCase(
        name: 'No factions discovered (empty state)',
        builder: (context) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: DiplomacyPanel(
              game: _diplomacyPanelEmptyGame,
              humanPlayerId: _diplomacyPanelEmptyHumanPlayerId,
              topology: const MapTopology(nodes: [], edges: []),
              currentOrders: const Orders(),
              bus: AppEventBus(),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        // SPEC/ui/diplomacy-panel.md § Responsive layout and
        // SPEC/ui/mobile-adaptation.md § 4 (`≤ 500 dp` column): under the
        // mobile-viewport frame (360 × 640 dp via [mobileViewport]) the
        // faction-row body adopts the narrow stacked layout — action
        // buttons drop below the info column and are left-aligned —
        // because 360 dp ≤ `kDiplomacyRowNarrowMaxWidth`. Refs #2870 R22
        // / S9 — "any other screen with responsive variants" extends the
        // R22 screen list to Diplomacy.
        name: 'Mobile viewport — narrow rows (≤ 500 dp)',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.first.id
              : 'gp1';
          return mobileViewport(
            context,
            MaterialApp(
              theme: AppThemes.editorialMonocle,
              localizationsDelegates:
                  AppLocalizationsBinding.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: DiplomacyPanel(
                  game: game,
                  humanPlayerId: humanPlayerId,
                  topology: result.combinedTopology,
                  currentOrders: const Orders(),
                  bus: AppEventBus(),
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
];

/// Stable human-player id used by the Diplomacy Panel empty-state
/// Widgetbook story. SPEC/ui/diplomacy-panel.md § Widgetbook.
const String _diplomacyPanelEmptyHumanPlayerId = 'gp1';

/// Minimal `Game` for the Diplomacy Panel empty-state Widgetbook story:
/// a single human-controlled Great Power with no other discovered
/// factions and no diplomacy relations, so `buildDiplomacyRows` returns
/// an empty list and the panel paints the three always-visible section
/// headings plus the `diplomacy_panel_noTribes` empty placeholder copy.
/// SPEC/ui/diplomacy-panel.md § Widgetbook empty state.
final Game _diplomacyPanelEmptyGame = () {
  const ow = 'oldWorld';
  final p1 = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'P1',
    ownerId: _diplomacyPanelEmptyHumanPlayerId,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [p1], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  const player = Player(
    id: _diplomacyPanelEmptyHumanPlayerId,
    displayName: 'Solo',
    isHuman: true,
  );
  return Game(
    id: 'wb-diplomacy-empty',
    worldState: world,
    players: const [player],
    diplomacyRelations: const [],
  );
}();
