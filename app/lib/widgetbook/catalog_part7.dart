// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// In-game shell chrome stories for issue #2861 S12: top bar, tab bar,
// bottom-left corner controls, map display options dialog, the player
// turn-events feed card, the empire left rail (with tooltips), and the
// region minimap (visible / hidden / narrow). Stories for the wide-only
// players bar, side menu, victory overlay, exit-confirm dialog, game
// screen, pause menu panel, and the narrow detail overlay slot already
// live in the earlier catalog parts.
//
// Empire left rail and region minimap stories use stand-in providers
// scoped to this catalog file: a no-op `GameService` that returns a `null`
// map cache (so the rail's diplomacy nav payload falls back to
// `MapTopology()`) and a constant `regionMinimapVisibleProvider` override
// per use case so reviewers can compare the dark editorial-monocle chrome
// in the visible and hidden minimap states without a Hive setup.
part of 'catalog.dart';

/// Game top bar stories. SPEC/ui/in-game-shell-narrow.md § Top bar and
/// `SPEC/ui/empire-overview.md` (in-game shell). Issue #2861 S1 + S12
/// stories (1) top bar default and (2) Next turn disabled during turn
/// resolution.
List<WidgetbookNode> get gameTopBarDirectories => [
  WidgetbookFolder(
    name: 'Game Top Bar',
    children: [
      WidgetbookUseCase(
        name: 'Default — hamburger + Next turn enabled',
        builder: (context) => _gameTopBarStoryFrame(
          child: GameTopBar(
            onToggleSideMenu: () {},
            onPausePressed: () {},
            onNextTurn: () async {},
            nextTurnEnabled: true,
            turnDisplayText: 'Turn 42 / Year 1650',
            // ignore: avoid_hardcoded_strings_in_widgets
            nextTurnText: 'Next turn (42 / 1650)',
            // ignore: avoid_hardcoded_strings_in_widgets
            menuTooltip: 'Menu',
            // ignore: avoid_hardcoded_strings_in_widgets
            pauseTooltip: 'Pause menu',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Next turn disabled — turn resolution in progress',
        builder: (context) => _gameTopBarStoryFrame(
          child: GameTopBar(
            onToggleSideMenu: () {},
            onPausePressed: () {},
            onNextTurn: () async {},
            nextTurnEnabled: false,
            turnDisplayText: 'Turn 42 / Year 1650',
            // ignore: avoid_hardcoded_strings_in_widgets
            nextTurnText: 'Next turn (42 / 1650)',
            // ignore: avoid_hardcoded_strings_in_widgets
            menuTooltip: 'Menu',
            // ignore: avoid_hardcoded_strings_in_widgets
            pauseTooltip: 'Pause menu',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Observe banner — observe-mode label',
        builder: (context) => _gameTopBarStoryFrame(
          child: GameTopBar(
            onToggleSideMenu: () {},
            onPausePressed: () {},
            onNextTurn: () async {},
            nextTurnEnabled: true,
            turnDisplayText: 'Turn 42 / Year 1650',
            // ignore: avoid_hardcoded_strings_in_widgets
            nextTurnText: 'Observe — Turn 42 (1650)',
            // ignore: avoid_hardcoded_strings_in_widgets
            menuTooltip: 'Menu',
            // ignore: avoid_hardcoded_strings_in_widgets
            pauseTooltip: 'Pause menu',
            // ignore: avoid_hardcoded_strings_in_widgets
            observeBannerLabel: 'Observing (Castile)',
          ),
        ),
      ),
    ],
  ),
];

/// Game tab bar stories. SPEC/ui/empire-overview.md § Region tabs +
/// Tab bar chrome. Issue #2861 S2 + S12 story (1) top bar + tab bar
/// default, with delta variants pinning AC-mapped success/danger colours.
List<WidgetbookNode> get gameTabBarDirectories => [
  WidgetbookFolder(
    name: 'Game Tab Bar',
    children: [
      WidgetbookUseCase(
        name: 'Default — Old World active, no delta',
        builder: (context) => _gameTabBarStoryFrame(regionIndex: 0),
      ),
      WidgetbookUseCase(
        name: 'New World active',
        builder: (context) => _gameTabBarStoryFrame(regionIndex: 1),
      ),
      WidgetbookUseCase(
        name: 'Positive treasury delta (green)',
        builder: (context) => _gameTabBarStoryFrame(treasuryDelta: 250),
      ),
      WidgetbookUseCase(
        name: 'Negative treasury delta (red)',
        builder: (context) => _gameTabBarStoryFrame(treasuryDelta: -400),
      ),
      WidgetbookUseCase(
        name: 'News toggle — unread badge',
        builder: (context) => _gameTabBarStoryFrame(
          unreadBadgeCount: 5,
          showFeed: false,
        ),
      ),
      WidgetbookUseCase(
        name: 'News toggle — feed open (no badge)',
        builder: (context) => _gameTabBarStoryFrame(
          unreadBadgeCount: 0,
          showFeed: true,
        ),
      ),
    ],
  ),
];

/// Game map corner controls stories. SPEC/ui/empire-overview.md
/// § Corner controls chrome. Issue #2861 S4 + S12 story (4) corner
/// controls row, including the disabled home-to-capital variant required
/// by the AC at `homeToCapitalEnabled: false`, and the narrow-layout
/// variant added by issue #2870 S9 pinning the 24 × 24 dp + 2 dp gap
/// measurements from `SPEC/ui/empire-overview.md` § Narrow corner-control
/// measurements and `SPEC/ui/mobile-adaptation.md` § In-game shell.
List<WidgetbookNode> get gameMapCornerControlsDirectories => [
  WidgetbookFolder(
    name: 'Game Map Corner Controls',
    children: [
      WidgetbookUseCase(
        name: 'Default — all three buttons enabled',
        builder: (context) => _gameMapCornerControlsStoryFrame(
          child: GameMapCornerControls(
            onCycleBaseLayerDisplayMode: () {},
            onCenterOnHomeCapital: () {},
            onOpenMapDisplayOptions: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Home-to-capital disabled (no human capital)',
        builder: (context) => _gameMapCornerControlsStoryFrame(
          child: GameMapCornerControls(
            onCycleBaseLayerDisplayMode: () {},
            onCenterOnHomeCapital: () {},
            onOpenMapDisplayOptions: () {},
            homeToCapitalEnabled: false,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Narrow (360 dp) — 24 × 24 dp buttons, 2 dp gap',
        builder: (context) => _gameMapCornerControlsNarrowStoryFrame(
          viewportWidth: 360,
          child: GameMapCornerControls(
            narrow: true,
            onCycleBaseLayerDisplayMode: () {},
            onCenterOnHomeCapital: () {},
            onOpenMapDisplayOptions: () {},
          ),
        ),
      ),
    ],
  ),
];

/// Game map options dialog stories. SPEC/ui/empire-overview.md
/// § Map display options button and dialog. Issue #2861 S8 + S12 story
/// (11) map options dialog. The defaults variant matches the SPEC defaults
/// (`Show province overlay` ON, `Show province ownership` OFF,
/// `Show province names` ON); the all-on variant exercises the persisted
/// state where the player has turned every toggle on.
List<WidgetbookNode> get gameMapOptionsDialogDirectories => [
  WidgetbookFolder(
    name: 'Game Map Options Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Defaults — overlay on, ownership off, names on',
        builder: (context) => _gameMapOptionsDialogStoryFrame(
          initialState: MapViewState.defaults,
        ),
      ),
      WidgetbookUseCase(
        name: 'All toggles on',
        builder: (context) => _gameMapOptionsDialogStoryFrame(
          initialState: MapViewState.defaults.copyWith(
            showProvinceOwnershipTint: true,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'All toggles off',
        builder: (context) => _gameMapOptionsDialogStoryFrame(
          initialState: const MapViewState(
            showProvinceOverlay: false,
            showProvinceOwnershipTint: false,
            showProvinceNamesLayer: false,
          ),
        ),
      ),
    ],
  ),
];

/// Player turn event feed card stories.
/// SPEC/ui/player-turn-event-feed.md. Issue #2861 S7 + S12 story (10)
/// news feed open / closed. The closed variant just renders the toggle
/// (already covered by `Game Tab Bar` stories), so this folder focuses on
/// the floating card surface itself: populated and empty states.
List<WidgetbookNode> get playerTurnEventFeedCardDirectories => [
  WidgetbookFolder(
    name: 'Player Turn Event Feed Card',
    children: [
      WidgetbookUseCase(
        name: 'Populated — three entries (top entry tappable)',
        builder: (context) => _playerTurnEventFeedCardStoryFrame(
          child: PlayerTurnEventFeedCard(
            entries: [
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'Castile completed Castle in Lisbon.',
                onTap: () {},
              ),
              const PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'England declared war on France.',
              ),
              const PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'New trade route established: Lisbon ↔ Bordeaux.',
              ),
            ],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Empty — no events this turn',
        builder: (context) => _playerTurnEventFeedCardStoryFrame(
          child: const PlayerTurnEventFeedCard(
            entries: [],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Narrow (360 dp) — populated, clamp(180, 50vw, 260)',
        builder: (context) => _playerTurnEventFeedCardNarrowStoryFrame(
          viewportWidth: 360,
          child: const PlayerTurnEventFeedCard(
            entries: [
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'Castile completed Castle in Lisbon.',
              ),
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'England declared war on France.',
              ),
            ],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
            narrow: true,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Narrow (460 dp) — populated, 50vw mid-range',
        builder: (context) => _playerTurnEventFeedCardNarrowStoryFrame(
          viewportWidth: 460,
          child: const PlayerTurnEventFeedCard(
            entries: [
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'Castile completed Castle in Lisbon.',
              ),
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'England declared war on France.',
              ),
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'New trade route established: Lisbon ↔ Bordeaux.',
              ),
            ],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
            narrow: true,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Narrow (599 dp) — empty, clamp upper bound (260 dp)',
        builder: (context) => _playerTurnEventFeedCardNarrowStoryFrame(
          viewportWidth: 599,
          child: const PlayerTurnEventFeedCard(
            entries: [],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
            narrow: true,
          ),
        ),
      ),
    ],
  ),
];

/// Mounts an in-game shell chrome widget inside a `MaterialApp` configured
/// for the editorial-monocle theme + localizations. The bar stretches to
/// the full viewport width so the 36 dp chrome reads the same way it does
/// on the production shell (which mounts `GameTopBar` inside a `Column`
/// under `Scaffold.body`).
MaterialApp _gameTopBarStoryFrame({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: EditorialMonoclePalette.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[child],
          ),
        ),
      ),
    ),
  );
}

/// Tab-bar story frame: full-width chrome under the dark scaffold so the
/// row layout (region tabs + treasury/cargo cluster + news toggle) reads
/// the same way it does in production where `GameTabBar` mounts under
/// `GameTopBar` inside `GameMapControls`'s `Column`.
Widget _gameTabBarStoryFrame({
  int regionIndex = 0,
  int treasury = 12345,
  int? treasuryDelta,
  int unreadBadgeCount = 0,
  bool showFeed = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: EditorialMonoclePalette.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _GameTabBarStoryShell(
                regionIndex: regionIndex,
                treasury: treasury,
                treasuryDelta: treasuryDelta,
                unreadBadgeCount: unreadBadgeCount,
                showFeed: showFeed,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GameTabBarStoryShell extends StatefulWidget {
  const _GameTabBarStoryShell({
    required this.regionIndex,
    required this.treasury,
    required this.treasuryDelta,
    required this.unreadBadgeCount,
    required this.showFeed,
  });

  final int regionIndex;
  final int treasury;
  final int? treasuryDelta;
  final int unreadBadgeCount;
  final bool showFeed;

  @override
  State<_GameTabBarStoryShell> createState() => _GameTabBarStoryShellState();
}

class _GameTabBarStoryShellState extends State<_GameTabBarStoryShell> {
  late int _regionIndex = widget.regionIndex;
  late bool _showFeed = widget.showFeed;

  @override
  Widget build(BuildContext context) {
    final int displayedCount = _showFeed ? 0 : widget.unreadBadgeCount;
    return GameTabBar(
      regionIndex: _regionIndex,
      onRegionIndexChanged: (i) => setState(() => _regionIndex = i),
      // ignore: avoid_hardcoded_strings_in_widgets
      oldWorldLabel: 'Old World',
      // ignore: avoid_hardcoded_strings_in_widgets
      newWorldLabel: 'New World',
      treasury: widget.treasury,
      treasuryDelta: widget.treasuryDelta,
      treasuryNotDefined: false,
      cargoUsed: 3,
      cargoCapacity: 12,
      cargoNotDefined: false,
      isCargoUsedReliable: true,
      // ignore: avoid_hardcoded_strings_in_widgets
      cargoHoldLabel: '3/12',
      trailing: PlayerTurnEventsFeedToggleButton(
        eventCount: displayedCount,
        // ignore: avoid_hardcoded_strings_in_widgets
        tooltip: 'Player turn events',
        showFeed: _showFeed,
        onPressed: () => setState(() => _showFeed = !_showFeed),
      ),
    );
  }
}

/// Corner controls frame: dark scaffold with the row anchored bottom-left,
/// matching the in-game map stack position.
MaterialApp _gameMapCornerControlsStoryFrame({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: EditorialMonoclePalette.bgDeep,
      body: SizedBox(
        width: 320,
        height: 220,
        child: Stack(
          children: [
            Positioned(
              left: 8,
              bottom: 8,
              child: child,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Narrow-viewport corner controls frame: clamps the visible canvas to a
/// representative narrow viewport width via `MediaQuery.size`, anchors
/// the row bottom-left at the compressed 2 dp inset (matching the
/// production stack on narrow), and forwards the editorial-monocle theme
/// so the chrome reads identically to the wide story (issue #2870 S9;
/// SPEC `SPEC/ui/empire-overview.md` § Narrow corner-control measurements;
/// `SPEC/ui/mobile-adaptation.md` § In-game shell).
MaterialApp _gameMapCornerControlsNarrowStoryFrame({
  required double viewportWidth,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: Size(viewportWidth, 640)),
      child: Scaffold(
        backgroundColor: EditorialMonoclePalette.bgDeep,
        body: SizedBox(
          width: viewportWidth,
          height: 640,
          child: Stack(
            children: [
              Positioned(
                left: 2,
                bottom: 2,
                child: child,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Map options dialog frame: opens the dialog inside a [Builder] so the
/// `showDialog` call gets a context with the editorial-monocle theme,
/// localizations, and the canonical [EditorialMonoclePalette.dialogScrim]
/// barrier colour shared by every other modal on the dark theme.
Widget _gameMapOptionsDialogStoryFrame({required MapViewState initialState}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: _GameMapOptionsDialogStoryHost(initialState: initialState),
  );
}

class _GameMapOptionsDialogStoryHost extends StatefulWidget {
  const _GameMapOptionsDialogStoryHost({required this.initialState});

  final MapViewState initialState;

  @override
  State<_GameMapOptionsDialogStoryHost> createState() =>
      _GameMapOptionsDialogStoryHostState();
}

class _GameMapOptionsDialogStoryHostState
    extends State<_GameMapOptionsDialogStoryHost> {
  late MapViewState _state = widget.initialState;
  bool _dialogShown = false;

  void _showDialog(BuildContext hostContext) {
    if (_dialogShown) return;
    _dialogShown = true;
    showDialog<void>(
      context: hostContext,
      barrierColor: EditorialMonoclePalette.dialogScrim,
      builder: (_) => GameMapOptionsDialog(
        initialState: _state,
        onChanged: (next) => setState(() => _state = next),
      ),
    ).whenComplete(() => _dialogShown = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EditorialMonoclePalette.bgDeep,
      body: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showDialog(context);
          });
          return const SizedBox.expand();
        },
      ),
    );
  }
}

/// News feed card frame: float the card against a representative dark map
/// background scrim and keep the wide-shell width so the chrome reads the
/// same way it does pinned to the in-game map stack.
MaterialApp _playerTurnEventFeedCardStoryFrame({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: EditorialMonoclePalette.bgDeep,
      body: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
}

/// Narrow-viewport news feed card frame: clamps the visible canvas to a
/// representative narrow viewport width via `MediaQuery.size`, anchors
/// the card top-right (matching the production stack placement on
/// narrow), and forwards the editorial-monocle theme so the chrome
/// reads identically to the wide story (issue #2870 S3 / Req 11; SPEC
/// `SPEC/ui/player-turn-event-feed.md` § Card chrome — narrow layout).
MaterialApp _playerTurnEventFeedCardNarrowStoryFrame({
  required double viewportWidth,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: Size(viewportWidth, 640)),
      child: Scaffold(
        backgroundColor: EditorialMonoclePalette.bgDeep,
        body: SizedBox(
          width: viewportWidth,
          height: 640,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Empire left rail stories. SPEC/ui/empire-buttons.md § Styling (left rail)
/// and § Narrow rail measurements. Issue #2861 S3 + S12 story (3) left rail
/// with tooltips, plus a debug-console variant that exercises the seventh
/// icon and a narrow variant that pins the 26 × 26 dp narrow-layout
/// measurements from issue #2870 S3 and `SPEC/ui/mobile-adaptation.md`
/// § In-game shell.
List<WidgetbookNode> get gameMapEmpireLeftRailDirectories => [
  WidgetbookFolder(
    name: 'Game Map Empire Left Rail',
    children: [
      WidgetbookUseCase(
        name: 'Wide — six core empire buttons with tooltips',
        builder: (context) => _gameMapEmpireLeftRailStoryFrame(),
      ),
      WidgetbookUseCase(
        name: 'Wide — debug console enabled (7 icons)',
        builder: (context) => _gameMapEmpireLeftRailStoryFrame(
          debugConsoleEnabled: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Narrow (360 dp) — 26 × 26 dp buttons, tooltips suppressed',
        builder: (context) => _gameMapEmpireLeftRailStoryFrame(narrow: true),
      ),
    ],
  ),
];

/// Region minimap stories. SPEC/ui/empire-overview.md § Region minimap and
/// § Region minimap chrome (dark editorial-monocle). Issue #2861 S5 + S12
/// story (5) minimap visible / hidden, plus a narrow variant that pins the
/// 90 × 70 dp narrow-layout sizing from issue #2870 S3 and
/// `SPEC/ui/mobile-adaptation.md` § In-game shell.
List<WidgetbookNode> get gameRegionMinimapDirectories => [
  WidgetbookFolder(
    name: 'Region Minimap',
    children: [
      WidgetbookUseCase(
        name: 'Visible — wide chrome with viewport rectangle',
        builder: (context) => _gameRegionMinimapStoryFrame(visible: true),
      ),
      WidgetbookUseCase(
        name: 'Hidden — toggle-only (zoom + show button)',
        builder: (context) => _gameRegionMinimapStoryFrame(visible: false),
      ),
      WidgetbookUseCase(
        name: 'Narrow — 90 × 70 dp grid (issue #2870 S3)',
        builder: (context) => _gameRegionMinimapStoryFrame(
          visible: true,
          narrow: true,
        ),
      ),
    ],
  ),
];

/// Wide-layout province side panel stories. SPEC/ui/in-game-shell-narrow.md
/// § Province/sea zone detail overlay (wide). Issue #2861 S12 story (9).
List<WidgetbookNode> get gameMapProvinceDetailSidePanelDirectories => [
  WidgetbookFolder(
    name: 'Game Map Province Side Panel',
    children: [
      WidgetbookUseCase(
        name: 'Open — wide layout panel visible',
        builder: (context) => _gameMapProvinceDetailSidePanelProviderScope(
          initialOpen: true,
        ),
      ),
      WidgetbookUseCase(
        name: 'Closed — panel collapsed',
        builder: (context) => _gameMapProvinceDetailSidePanelProviderScope(
          initialOpen: false,
        ),
      ),
    ],
  ),
];

/// Empire left rail story frame: wires a stand-in [GameService] that
/// returns `null` from [GameService.getMapData] (so the diplomacy nav
/// payload falls back to an empty [MapTopology]) and overrides
/// [debugConsoleEnabledProvider] for the debug-icon variant. The rail
/// renders inside a dark editorial-monocle [Scaffold] with the same
/// [EditorialMonoclePalette.bgDeep] background as the production map
/// stack so reviewers compare the rail chrome against a representative
/// surface.
Widget _gameMapEmpireLeftRailStoryFrame({
  bool narrow = false,
  bool debugConsoleEnabled = false,
}) {
  final game = getDebugInitGameResult().game;
  final humanId = game.players.isNotEmpty ? game.players.first.id : 'gp_human';
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      gameServiceProvider.overrideWith((ref) => _StoryStubGameService()),
      debugConsoleEnabledProvider.overrideWithValue(debugConsoleEnabled),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: EditorialMonoclePalette.bgDeep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topLeft,
              child: GameMapEmpireLeftRail(
                game: game,
                humanPlayerId: humanId,
                narrow: narrow,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Region minimap story frame: mounts [GameRegionMinimap] inside a
/// [ProviderScope] that overrides [regionMinimapVisibleProvider] with the
/// requested visibility so the visible / hidden chrome paths are
/// exercised deterministically. A synthetic [RegionMapViewportSnapshot]
/// drives the white viewport rectangle and zoom slider so the
/// editorial-monocle chrome reads representative of the in-game stack.
Widget _gameRegionMinimapStoryFrame({
  required bool visible,
  bool narrow = false,
}) {
  final region = demoRegionForOverlay;
  final viewport = _storyMinimapViewportSnapshot(region);
  return ProviderScope(
    overrides: [
      regionMinimapVisibleProvider.overrideWith(
        _StoryRegionMinimapVisibleNotifier.new,
      ),
      _storyMinimapInitialVisibleProvider.overrideWithValue(visible),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: EditorialMonoclePalette.bgDeep,
        body: MediaQuery(
          data: MediaQueryData(size: Size(narrow ? 360 : 1500, 640)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.bottomRight,
                child: GameRegionMinimap(
                  region: region,
                  viewportSnapshot: viewport,
                  bus: AppEventBus.create(),
                  cellSizePx: region.cellSize.toDouble(),
                  narrow: narrow,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Synthetic viewport snapshot for the region minimap stories — picks a
/// world centre at the middle of [region] and a zoom slightly above the
/// fit zoom so the white viewport rectangle is visibly smaller than the
/// minimap grid (mockup `.minimap-panel` rule). Deterministic so the
/// story renders the same chrome every reload.
RegionMapViewportSnapshot _storyMinimapViewportSnapshot(
  RegionMapViewData region,
) {
  final cellSize = region.cellSize.toDouble();
  final mapWidthWorld = region.width * cellSize;
  final mapHeightWorld = region.height * cellSize;
  const viewportWidthLogical = 600.0;
  const viewportHeightLogical = 400.0;
  // Fit zoom = min(viewport / map) so the full map fits. The story zooms
  // 1.6 × beyond the fit so the white rectangle reads as a window inside
  // the minimap grid rather than spanning the whole panel.
  final fitMapZoom =
      viewportWidthLogical / mapWidthWorld < viewportHeightLogical / mapHeightWorld
          ? viewportWidthLogical / mapWidthWorld
          : viewportHeightLogical / mapHeightWorld;
  return RegionMapViewportSnapshot(
    regionId: region.regionId,
    cellSizePx: cellSize,
    mapWidthWorld: mapWidthWorld,
    mapHeightWorld: mapHeightWorld,
    cameraCenterX: mapWidthWorld / 2,
    cameraCenterY: mapHeightWorld / 2,
    zoom: fitMapZoom * 1.6,
    fitMapZoom: fitMapZoom,
    viewportWidthLogical: viewportWidthLogical,
    viewportHeightLogical: viewportHeightLogical,
  );
}

/// Story-only initial-visibility provider. The story
/// [_StoryRegionMinimapVisibleNotifier] reads this value once at build
/// time so each use case can declare its starting state without sharing
/// state across stories.
final _storyMinimapInitialVisibleProvider = Provider<bool>((ref) => true);

/// Story override for [RegionMinimapVisibleNotifier] that seeds itself
/// from [_storyMinimapInitialVisibleProvider]; the production default of
/// `true` only fires when the override is absent (which never happens in
/// the story frame). Toggle behaviour is preserved so reviewers can flip
/// the chrome live from inside a single story.
class _StoryRegionMinimapVisibleNotifier extends RegionMinimapVisibleNotifier {
  @override
  bool build() {
    return ref.read(_storyMinimapInitialVisibleProvider);
  }
}

class _GameMapProvinceDetailSidePanelStoryHost extends ConsumerStatefulWidget {
  const _GameMapProvinceDetailSidePanelStoryHost({required this.initialOpen});

  final bool initialOpen;

  @override
  ConsumerState<_GameMapProvinceDetailSidePanelStoryHost> createState() =>
      _GameMapProvinceDetailSidePanelStoryHostState();
}

class _GameMapProvinceDetailSidePanelStoryHostState
    extends ConsumerState<_GameMapProvinceDetailSidePanelStoryHost> {
  final PerPlayerWorkTargetSelectionCache _workTargetSelectionCache =
      PerPlayerWorkTargetSelectionCache();

  @override
  void initState() {
    super.initState();
    if (widget.initialOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(mapProvincePanelProvider.notifier)
            .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;
    return MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(900, 640)),
        child: Scaffold(
          backgroundColor: EditorialMonoclePalette.bgDeep,
          body: Row(
            children: [
              Expanded(
                child: ColoredBox(
                  color: EditorialMonoclePalette.bgDeep,
                  child: const Center(
                    child: Text(
                      'Map area (stand-in)',
                      // ignore: avoid_hardcoded_strings_in_widgets
                    ),
                  ),
                ),
              ),
              GameMapProvinceDetailSidePanel(
                game: game,
                region: region,
                humanPlayerId: game.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
                workTargetSelectionCache: _workTargetSelectionCache,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ProviderScope _gameMapProvinceDetailSidePanelProviderScope({
  required bool initialOpen,
}) {
  final game = demoGameForOverlay;
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      gameServiceProvider.overrideWith((ref) => _StoryStubGameService()),
    ],
    child: _GameMapProvinceDetailSidePanelStoryHost(initialOpen: initialOpen),
  );
}

/// Stand-in [GameService] for the empire-left-rail story.
///
/// The production rail reads `gameServiceProvider.getMapData(game.id)` to
/// derive the topology bundled with the diplomacy navigation event; the
/// stub returns `null` so the rail falls back to an empty `MapTopology()`
/// (matching the existing `mapData?.combinedTopology ?? MapTopology()`
/// fallback in `GameMapEmpireLeftRail.build`). All other `GameService`
/// methods route through [_StoryStubBox.noSuchMethod] which returns
/// `null`; the story never invokes them.
class _StoryStubGameService extends GameService {
  _StoryStubGameService() : super(_StoryStubBox(), GameSaveAdapter());

  @override
  GameMapData? getMapData(String gameId) => null;
}

/// Type-erased [Box] stub for [_StoryStubGameService]. The Hive box is
/// never read because [_StoryStubGameService] overrides every
/// `GameService` method that touches the box in the story path, so a
/// `noSuchMethod`-only impl is safe and avoids opening a real Hive box
/// from the Widgetbook bootstrap.
class _StoryStubBox implements Box<dynamic> {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
