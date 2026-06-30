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
  // SPEC/ui/components/relation-meter.md — isolated stories for the shared
  // 10-step gradient `RelationMeter`: the full ladder (one meter per step) and
  // the half-open band boundary scores. Refs #3753 R13.
  WidgetbookFolder(
    name: 'Relation Meter',
    children: [
      WidgetbookUseCase(
        name: 'Ladder (all 10 steps)',
        builder: (context) => _relationMeterStory(
          const <num>[5, 15, 25, 35, 45, 55, 65, 75, 85, 95],
        ),
      ),
      WidgetbookUseCase(
        name: 'Band boundaries (0, 50, 90, 100)',
        builder: (context) => _relationMeterStory(const <num>[0, 50, 90, 100]),
      ),
    ],
  ),
  // SPEC/ui/diplomacy-panel.md § Diplomatic standing chip cluster (Refs #3753
  // R12) — isolated stories for `DiplomacyStandingChipCluster` covering the
  // colony-Tribe standing (treaty + colony + boycott chips), an independent
  // Minor with overseas holdings, and the empty (no-footprint) negative case.
  WidgetbookFolder(
    name: 'Diplomatic Standing Chips',
    children: [
      WidgetbookUseCase(
        name: 'Colony Tribe (treaty + Colony + Boycott vs)',
        builder: (context) => _standingChipsStory(
          const DiplomaticStandingChips(
            treatyLabels: [
              kDiplomacyChipConsulate,
              kDiplomacyChipEmbassy,
              kDiplomacyChipNap,
              kDiplomacyChipColony,
            ],
            boycottVsNames: ['Castile'],
            overseasTileCount: 3,
            overseasSharePercent: 60,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Minor overseas holdings (Overseas chip)',
        builder: (context) => _standingChipsStory(
          const DiplomaticStandingChips(
            treatyLabels: [kDiplomacyChipConsulate, kDiplomacyChipEmbassy],
            overseasTileCount: 2,
            overseasSharePercent: 80,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Empty standing (no chips, zero footprint)',
        builder: (context) =>
            _standingChipsStory(const DiplomaticStandingChips()),
      ),
    ],
  ),
];

/// Renders a [DiplomacyStandingChipCluster] inside the editorial-monocle dark
/// theme so reviewers can confirm the treaty / colony / boycott / overseas chip
/// chrome and run-wrapping. SPEC/ui/diplomacy-panel.md § Diplomatic standing
/// chip cluster (Refs #3753 R12).
Widget _standingChipsStory(DiplomaticStandingChips chips) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: EditorialMonoclePalette.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DiplomacyStandingChipCluster(chips: chips),
        ),
      ),
    ),
  );
}

/// Renders a vertical stack of [RelationMeter] widgets at the given [scores]
/// inside the editorial-monocle dark theme, each beside its hidden-score
/// ladder label so reviewers can confirm the gradient + indicator alignment.
/// SPEC/ui/components/relation-meter.md § Widgetbook.
Widget _relationMeterStory(List<num> scores) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: EditorialMonoclePalette.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final score in scores)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RelationMeter(score: score),
                      const SizedBox(width: 12),
                      Text(
                        relationScoreToDisplayLabel(score),
                        style: TextStyle(
                          color: relationMeterStepColor(
                            relationScoreToMeterStep(score),
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

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
