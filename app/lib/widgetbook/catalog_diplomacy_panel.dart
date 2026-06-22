part of 'catalog.dart';

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
  // SPEC/ui/diplomacy-panel.md § Relative power line — isolated stories for
  // the shared `RelativePowerLine` widget covering all five tiers plus the
  // boundary percentages (±10, ±11, ±30, ±31) and the narrow-viewport wrap.
  WidgetbookFolder(
    name: 'Relative Power Line',
    children: [
      WidgetbookUseCase(
        name: 'Tiers (all five)',
        builder: (context) => _relativePowerLineStory(
          const <int>[-50, -20, 0, 20, 50],
        ),
      ),
      WidgetbookUseCase(
        name: 'Boundaries (±10, ±11, ±30, ±31)',
        builder: (context) => _relativePowerLineStory(
          const <int>[10, 11, 30, 31, -10, -11, -30, -31],
        ),
      ),
      WidgetbookUseCase(
        name: 'Narrow viewport wrap (320 dp)',
        builder: (context) => _relativePowerLineStory(
          const <int>[31, -31],
          maxWidth: 320,
        ),
      ),
    ],
  ),
];

/// Renders a vertical stack of [RelativePowerLine] widgets at the given
/// [percents] inside the editorial-monocle dark theme with full localization
/// delegates so the muted prefix and tier words resolve. SPEC/ui/diplomacy-
/// panel.md § Relative power line Widgetbook.
Widget _relativePowerLineStory(List<int> percents, {double? maxWidth}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: EditorialMonoclePalette.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final pct in percents)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: RelativePowerLine(pct: pct),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

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
