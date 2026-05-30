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

/// Tech Tree Widget stories. SPEC/ui/tech-tree-widget.md.
List<WidgetbookNode> get techTreeDirectories => [
  WidgetbookFolder(
    name: 'Tech Tree',
    children: [
      WidgetbookUseCase(
        name: 'Mid-game (half researched)',
        builder: (context) {
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
          return MaterialApp(
            theme: AppThemes.editorialMonocle,
            home: Scaffold(
              body: TechnologyScreen(game: midGame, player: midGamePlayer),
            ),
          );
        },
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
    ],
  ),
];

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
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
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
      // an empty list and the panel paints the
      // `diplomacy_panel_noFactions` empty-state copy under the
      // editorial-monocle dark chrome. Refs #2863 S7.
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
/// an empty list and the panel paints the `diplomacy_panel_noFactions`
/// empty-state copy. SPEC/ui/diplomacy-panel.md § Widgetbook empty
/// state.
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
