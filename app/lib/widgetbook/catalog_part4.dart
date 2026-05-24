part of 'catalog.dart';

/// Pause menu panel stories. SPEC/ui/pause-menu-panel.md.
///
/// Renders [PauseMenuPanel] inside a plain [Scaffold] body so the catalog can
/// preview the row layout without the modal bottom-sheet scrim that
/// [AppEventHandler] uses in production.
class _PauseMenuPanelStoryHost extends StatefulWidget {
  const _PauseMenuPanelStoryHost();

  @override
  State<_PauseMenuPanelStoryHost> createState() =>
      _PauseMenuPanelStoryHostState();
}

class _PauseMenuPanelStoryHostState extends State<_PauseMenuPanelStoryHost> {
  late final AppEventBus _bus;

  @override
  void initState() {
    super.initState();
    _bus = AppEventBus.create();
  }

  @override
  void dispose() {
    _bus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.colonial,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: PauseMenuPanel(bus: _bus),
          ),
        ),
      ),
    );
  }
}

/// Pause menu panel stories. SPEC/ui/pause-menu-panel.md.
List<WidgetbookNode> get pauseMenuPanelDirectories => [
  WidgetbookFolder(
    name: 'Pause Menu Panel',
    children: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (context) => const _PauseMenuPanelStoryHost(),
      ),
    ],
  ),
];

/// Hosts [GameSideMenu] in a [Stack] so the [Positioned] body has bounded
/// constraints, matching how [GameMapArea] mounts the drawer in production.
class _GameSideMenuStoryHost extends StatefulWidget {
  const _GameSideMenuStoryHost({required this.initialOpen});

  final bool initialOpen;

  @override
  State<_GameSideMenuStoryHost> createState() => _GameSideMenuStoryHostState();
}

class _GameSideMenuStoryHostState extends State<_GameSideMenuStoryHost> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.colonial,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black12),
            ),
            GameSideMenu(
              sideMenuOpen: _open,
              onClose: () => setState(() => _open = false),
            ),
          ],
        ),
      ),
    );
  }
}

ProviderScope _gameSideMenuProviderScope({required bool initialOpen}) {
  final game = getDebugInitGameResult().game;
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    ],
    child: _GameSideMenuStoryHost(initialOpen: initialOpen),
  );
}

/// Game side menu stories. SPEC/ui/game-side-menu.md.
List<WidgetbookNode> get gameSideMenuDirectories => [
  WidgetbookFolder(
    name: 'Game Side Menu',
    children: [
      WidgetbookUseCase(
        name: 'Default — open',
        builder: (context) => _gameSideMenuProviderScope(initialOpen: true),
      ),
      WidgetbookUseCase(
        name: 'Closed',
        builder: (context) => _gameSideMenuProviderScope(initialOpen: false),
      ),
    ],
  ),
];
