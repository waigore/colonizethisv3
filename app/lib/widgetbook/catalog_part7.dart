// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// In-game shell chrome stories for issue #2861 S12: top bar, tab bar,
// bottom-left corner controls, map display options dialog, and the player
// turn-events feed card. Stories for the wide-only players bar, side menu,
// victory overlay, exit-confirm dialog, game screen, pause menu panel, and
// the narrow detail overlay slot already live in the earlier catalog parts.
// Empire left rail and region minimap stories are deferred to a follow-up
// PR because both widgets read `gameServiceProvider` / region map view data
// that require a `Hive.box`/topology setup outside the simple chrome
// previews collected here.
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
            onNextTurn: () async {},
            nextTurnEnabled: true,
            // ignore: avoid_hardcoded_strings_in_widgets
            nextTurnText: 'Next turn (42 / 1650)',
            // ignore: avoid_hardcoded_strings_in_widgets
            menuTooltip: 'Menu',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Next turn disabled — turn resolution in progress',
        builder: (context) => _gameTopBarStoryFrame(
          child: GameTopBar(
            onToggleSideMenu: () {},
            onNextTurn: () async {},
            nextTurnEnabled: false,
            // ignore: avoid_hardcoded_strings_in_widgets
            nextTurnText: 'Next turn (42 / 1650)',
            // ignore: avoid_hardcoded_strings_in_widgets
            menuTooltip: 'Menu',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Observe banner — observe-mode label',
        builder: (context) => _gameTopBarStoryFrame(
          child: GameTopBar(
            onToggleSideMenu: () {},
            onNextTurn: () async {},
            nextTurnEnabled: true,
            // ignore: avoid_hardcoded_strings_in_widgets
            nextTurnText: 'Observe — Turn 42 (1650)',
            // ignore: avoid_hardcoded_strings_in_widgets
            menuTooltip: 'Menu',
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
/// by the AC at `homeToCapitalEnabled: false`.
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
