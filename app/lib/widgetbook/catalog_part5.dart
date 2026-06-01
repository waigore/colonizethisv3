// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
part of 'catalog.dart';

/// Pause menu panel stories. SPEC/ui/pause-menu-panel.md.
///
/// Renders the new 5-button [PauseMenuPanel] modal centered over the
/// editorial-monocle scrim ([EditorialMonoclePalette.dialogScrim]) so the
/// catalog can preview the [CtDialogShell] frame, brass divider, and
/// action stack matching the production `showDialog` host used by
/// [AppEventHandler]. (Issue #2867 R30, S11.)
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
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: EditorialMonoclePalette.dialogScrim,
        body: Center(
          child: PauseMenuPanel(bus: _bus),
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
        name: 'Default — centered modal',
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
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.black12)),
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

/// Hosts [GameMapNarrowDetailOverlaySlot] with the map panel provider opened on a
/// sample tile. SPEC/ui/game-map-narrow-detail-overlay-slot.md.
class _GameMapNarrowDetailOverlaySlotStoryHost extends ConsumerStatefulWidget {
  const _GameMapNarrowDetailOverlaySlotStoryHost();

  @override
  ConsumerState<_GameMapNarrowDetailOverlaySlotStoryHost> createState() =>
      _GameMapNarrowDetailOverlaySlotStoryHostState();
}

class _GameMapNarrowDetailOverlaySlotStoryHostState
    extends ConsumerState<_GameMapNarrowDetailOverlaySlotStoryHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
    });
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
        data: const MediaQueryData(size: Size(400, 600)),
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.black12)),
              Align(
                alignment: Alignment.bottomCenter,
                child: GameMapNarrowDetailOverlaySlot(
                  game: game,
                  region: region,
                  humanPlayerId: game.players.first.id,
                  playerView: demoHumanPlayerViewForOverlay,
                  workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ProviderScope _gameMapNarrowDetailOverlaySlotProviderScope() {
  return ProviderScope(child: const _GameMapNarrowDetailOverlaySlotStoryHost());
}

/// Game map narrow detail overlay slot stories.
List<WidgetbookNode> get gameMapNarrowDetailOverlaySlotDirectories => [
  WidgetbookFolder(
    name: 'Game Map Narrow Detail Overlay Slot',
    children: [
      WidgetbookUseCase(
        name: 'Default — province open',
        builder: (context) => _gameMapNarrowDetailOverlaySlotProviderScope(),
      ),
    ],
  ),
];

/// Stories for the dark editorial-monocle theme primitives introduced by
/// issue #2859 S1/S3/S4/S5/S7/S8/S9/S10/S11/S12/S13 (`CtGradients`, `CtPanel`,
/// `CtSlider`, `CtDialogShell`, `CtBrassDivider`, `CtToggleSwitch`,
/// `CtSectionLabel`, `CtResourceCell`, `CtProgressBar`, `CtBackButton`,
/// `CtTopBar`, `CtScreenShell`) and issue #2860 S1/S2/S4 (`CtCompassRose`,
/// `CtMainMenuCollage`, `CtFleurDeLisOrnament`).
/// SPEC/ui/pixel-art-ui-catalog.md § Editorial-monocle palette.
List<WidgetbookNode> get ctDarkThemePrimitiveDirectories => [
  WidgetbookFolder(
    name: 'Ct- Dark Theme Primitives',
    children: [
      WidgetbookUseCase(
        name: 'CtGradients — token swatches',
        builder: (context) => _CtGradientsStory(),
      ),
      WidgetbookUseCase(
        name: 'CtPanel — dark editorial-monocle banded chrome',
        builder: (context) => const _CtPanelStory(),
      ),
      WidgetbookUseCase(
        name: 'CtDialogShell — dark frame',
        builder: (context) => _CtDialogShellStory(),
      ),
      WidgetbookUseCase(
        name: 'CtFullScreenDialogueShell — scrim + framed body',
        builder: (context) => _CtFullScreenDialogueShellStory(),
      ),
      WidgetbookUseCase(
        name: 'CtSlider — value sweep',
        builder: (context) => const _CtSliderStory(),
      ),
      WidgetbookUseCase(
        name: 'CtBrassDivider — wide and narrow',
        builder: (context) => _CtBrassDividerStory(),
      ),
      WidgetbookUseCase(
        name: 'CtSectionLabel — default',
        builder: (context) => _CtSectionLabelStory(),
      ),
      WidgetbookUseCase(
        name: 'CtProgressBar — value sweep',
        builder: (context) => _CtProgressBarStory(),
      ),
      WidgetbookUseCase(
        name: 'CtToggleSwitch — interactive states',
        builder: (context) => const _CtToggleSwitchStory(),
      ),
      WidgetbookUseCase(
        name: 'CtResourceCell — delta sign sweep',
        builder: (context) => _CtResourceCellStory(),
      ),
      WidgetbookUseCase(
        name: 'CtBackButton — interactive states',
        builder: (context) => const _CtBackButtonStory(),
      ),
      WidgetbookUseCase(
        name: 'CtIconAction — glyph affordance states',
        builder: (context) => const _CtIconActionStory(),
      ),
      WidgetbookUseCase(
        name: 'CtTopBar — slot composition',
        builder: (context) => const _CtTopBarStory(),
      ),
      WidgetbookUseCase(
        name: 'CtScreenShell — with and without back button',
        builder: (context) => const _CtScreenShellStory(),
      ),
      WidgetbookUseCase(
        name: 'CtDropdown — chevron rotation',
        builder: (context) => const _CtDropdownStory(),
      ),
      WidgetbookUseCase(
        name: 'CtDropdown — selected-row highlight',
        builder: (context) => const _CtDropdownSelectedRowStory(),
      ),
      WidgetbookUseCase(
        name: 'CtCompassRose — size sweep',
        builder: (context) => _CtCompassRoseStory(),
      ),
      WidgetbookUseCase(
        name: 'CtFleurDeLisOrnament — flanking pair',
        builder: (context) => _CtFleurDeLisOrnamentStory(),
      ),
      WidgetbookUseCase(
        name: 'CtMainMenuCollage — full background',
        builder: (context) => const _CtMainMenuCollageStory(),
      ),
    ],
  ),
];

class _CtDarkPrimitiveScaffold extends StatelessWidget {
  const _CtDarkPrimitiveScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.editorialMonocle,
      child: Material(
        color: AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }
}

class _CtDialogShellStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.editorialMonocle,
      child: Material(
        color: AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: Stack(
          children: const [
            Positioned.fill(child: _CtDialogShellBackdrop()),
            Center(
              child: CtDialogShell(
                maxWidth: 360,
                maxHeight: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // ignore: avoid_hardcoded_strings_in_widgets
                      'Dialog shell preview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      // ignore: avoid_hardcoded_strings_in_widgets
                      'Frame shows the 2px --accent-dim border and panelGradient background per Refs #2859 R3 / S4.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtDialogShellBackdrop extends StatelessWidget {
  const _CtDialogShellBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemes.editorialMonocle.scaffoldBackgroundColor,
      ),
    );
  }
}

class _CtGradientsStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<({String name, Gradient gradient})> entries = [
      (name: 'buttonGradient', gradient: CtGradients.buttonGradient),
      (name: 'panelGradient', gradient: CtGradients.panelGradient),
      (name: 'rowGradient', gradient: CtGradients.rowGradient),
      (name: 'topBarGradient', gradient: CtGradients.topBarGradient),
    ];
    return _CtDarkPrimitiveScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in entries) ...[
            Text(entry.name, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Container(
              height: 36,
              decoration: BoxDecoration(gradient: entry.gradient),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _CtSliderStory extends StatefulWidget {
  const _CtSliderStory();

  @override
  State<_CtSliderStory> createState() => _CtSliderStoryState();
}

class _CtSliderStoryState extends State<_CtSliderStory> {
  double _value = 0.4;

  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Value ${_value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          CtSlider(
            value: _value,
            min: 0,
            max: 1,
            divisions: 10,
            onChanged: (v) => setState(() => _value = v),
          ),
          const SizedBox(height: 24),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Comfort headroom active',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          CtSlider(
            value: 0.3,
            min: 0,
            max: 1,
            divisions: 10,
            comfortHeadroomActive: true,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

class _CtPanelStory extends StatelessWidget {
  const _CtPanelStory();

  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Default padding',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          CtPanel(
            child: Text(
              // ignore: avoid_hardcoded_strings_in_widgets
              'Panel body — top/bottom 1.5 px --accent-dim strips and panelGradient background per Refs #2859 R2 / S3.',
            ),
          ),
          SizedBox(height: 24),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Zero padding (full-bleed body)',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          CtPanel(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  // ignore: avoid_hardcoded_strings_in_widgets
                  'EdgeInsets.zero — strips still anchor top and bottom',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtBrassDividerStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SizedBox(height: 12),
          CtBrassDivider(),
          SizedBox(height: 24),
          SizedBox(width: 120, child: CtBrassDivider()),
          SizedBox(height: 24),
          SizedBox(width: 320, child: CtBrassDivider()),
        ],
      ),
    );
  }
}

class _CtSectionLabelStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          CtSectionLabel('Production'),
          SizedBox(height: 16),
          CtSectionLabel(
            'Diplomatic Relations',
            padding: EdgeInsets.only(left: 8),
          ),
          SizedBox(height: 16),
          CtSectionLabel('Naval Units'),
        ],
      ),
    );
  }
}

class _CtCompassRoseStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          CtCompassRose(size: 32),
          SizedBox(height: 16),
          CtCompassRose(size: 48),
          SizedBox(height: 16),
          CtCompassRose(size: 72),
        ],
      ),
    );
  }
}

class _CtFleurDeLisOrnamentStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          CtFleurDeLisOrnament(),
          SizedBox(width: 16),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'ColonizeThis',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 16),
          CtFleurDeLisOrnament(),
        ],
      ),
    );
  }
}

class _CtProgressBarStory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: const [
          // ignore: avoid_hardcoded_strings_in_widgets
          Text('0%'),
          SizedBox(height: 4),
          CtProgressBar(value: 0),
          SizedBox(height: 16),
          // ignore: avoid_hardcoded_strings_in_widgets
          Text('30% with label'),
          SizedBox(height: 4),
          CtProgressBar(value: 0.3, label: '30%'),
          SizedBox(height: 16),
          // ignore: avoid_hardcoded_strings_in_widgets
          Text('70% (clamped from 1.2)'),
          SizedBox(height: 4),
          CtProgressBar(value: 1.2, label: '100%'),
          SizedBox(height: 16),
          // ignore: avoid_hardcoded_strings_in_widgets
          Text('Disabled (40%)'),
          SizedBox(height: 4),
          CtProgressBar(value: 0.4, enabled: false, label: '40%'),
        ],
      ),
    );
  }
}

class _CtToggleSwitchStory extends StatefulWidget {
  const _CtToggleSwitchStory();

  @override
  State<_CtToggleSwitchStory> createState() => _CtToggleSwitchStoryState();
}

class _CtToggleSwitchStoryState extends State<_CtToggleSwitchStory> {
  bool _interactive = false;

  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Off (static)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          CtToggleSwitch(value: false, onChanged: (_) {}),
          const SizedBox(height: 16),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'On (static)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          CtToggleSwitch(value: true, onChanged: (_) {}),
          const SizedBox(height: 16),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Interactive (tap to toggle)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          CtToggleSwitch(
            value: _interactive,
            onChanged: (v) => setState(() => _interactive = v),
          ),
          const SizedBox(height: 16),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Disabled off (onChanged: null)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          const CtToggleSwitch(value: false, onChanged: null),
          const SizedBox(height: 16),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Disabled on (onChanged: null)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          const CtToggleSwitch(value: true, onChanged: null),
        ],
      ),
    );
  }
}

class _CtResourceCellStory extends StatelessWidget {
  Widget _icon(String commodityId) {
    return ResourceIcon(commodityId: commodityId, size: 20);
  }

  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CtResourceCell(
              iconBuilder: (_) => _icon('grain'),
              // ignore: avoid_hardcoded_strings_in_widgets
              name: 'Grain',
              quantity: 1240,
              delta: 45,
            ),
            const SizedBox(height: 6),
            CtResourceCell(
              iconBuilder: (_) => _icon('meat'),
              // ignore: avoid_hardcoded_strings_in_widgets
              name: 'Meat',
              quantity: 870,
            ),
            const SizedBox(height: 6),
            CtResourceCell(
              iconBuilder: (_) => _icon('timber'),
              // ignore: avoid_hardcoded_strings_in_widgets
              name: 'Timber',
              quantity: 920,
              delta: -40,
            ),
            const SizedBox(height: 6),
            CtResourceCell(
              iconBuilder: (_) => _icon('iron'),
              // ignore: avoid_hardcoded_strings_in_widgets
              name: 'Iron',
              quantity: 430,
              delta: 0,
            ),
            const SizedBox(height: 6),
            CtResourceCell(
              iconBuilder: (_) => _icon('refinedSugar'),
              // ignore: avoid_hardcoded_strings_in_widgets
              name: 'Refined Sugar — long label demo',
              quantity: 1234567,
              delta: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _CtBackButtonStory extends StatefulWidget {
  const _CtBackButtonStory();

  @override
  State<_CtBackButtonStory> createState() => _CtBackButtonStoryState();
}

class _CtBackButtonStoryState extends State<_CtBackButtonStory> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Default (hover / press to inspect states)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          CtBackButton(onPressed: () => setState(() => _taps++)),
          const SizedBox(height: 16),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Disabled',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          const CtBackButton(enabled: false),
          const SizedBox(height: 16),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'taps: $_taps',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// _CtIconActionStory is hosted in catalog_part8.dart to keep this part file
// under the 1000-line repo-lint cap (`repo.part_unit_size`).

class _CtTopBarStory extends StatelessWidget {
  const _CtTopBarStory();

  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Title only',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 4),
          CtTopBar(
            // ignore: avoid_hardcoded_strings_in_widgets
            title: 'Production',
          ),
          SizedBox(height: 16),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Back-label + icon + title',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 4),
          CtTopBar(
            // ignore: avoid_hardcoded_strings_in_widgets
            title: 'Production',
            // ignore: avoid_hardcoded_strings_in_widgets
            backButtonLabel: 'Map',
            icon: Icon(Icons.factory_outlined, size: 18, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Disabled back affordance',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 4),
          CtTopBar(
            // ignore: avoid_hardcoded_strings_in_widgets
            title: 'Production',
            // ignore: avoid_hardcoded_strings_in_widgets
            backButtonLabel: 'Map',
            backButtonEnabled: false,
          ),
        ],
      ),
    );
  }
}

/// Showcases [CtScreenShell] in both its default (no back button) and
/// `showBackButton: true` modes so reviewers can confirm the 36 px
/// [CtTopBar] chrome + framed body composition under the
/// `editorialMonocle` theme (Refs #2859 R4 / S5). The host inflates the
/// shells inside a `MaterialApp` so [Navigator.maybePop] is valid when the
/// chevron is tapped.
class _CtScreenShellStory extends StatelessWidget {
  const _CtScreenShellStory();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      home: Scaffold(
        backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
        body: Row(
          children: <Widget>[
            Expanded(
              child: CtScreenShell(
                // ignore: avoid_hardcoded_strings_in_widgets
                title: 'Default (no back button)',
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      // ignore: avoid_hardcoded_strings_in_widgets
                      'CtTopBar omits the leading CtBackButton when '
                      'showBackButton is false.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: CtScreenShell(
                // ignore: avoid_hardcoded_strings_in_widgets
                title: 'With back button',
                showBackButton: true,
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      // ignore: avoid_hardcoded_strings_in_widgets
                      'CtTopBar renders the leading CtBackButton chevron '
                      'and wires it through to Navigator.maybePop().',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Showcases [CtDropdown] R5d chevron rotation under the dark
/// editorial-monocle theme. See SPEC/ui/pixel-art-ui-catalog.md
/// § Pixel-art component catalog (CtDropdown) and issue #2859 R5d / S6.
class _CtDropdownStory extends StatefulWidget {
  const _CtDropdownStory();

  @override
  State<_CtDropdownStory> createState() => _CtDropdownStoryState();
}

class _CtDropdownStoryState extends State<_CtDropdownStory> {
  static const List<String> _options = <String>[
    // ignore: avoid_hardcoded_strings_in_widgets
    'England',
    // ignore: avoid_hardcoded_strings_in_widgets
    'France',
    // ignore: avoid_hardcoded_strings_in_widgets
    'Spain',
  ];

  String? _value;

  @override
  Widget build(BuildContext context) {
    return _CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Tap the trigger — chevron rotates 180° over 120ms '
            '(open), and rotates back when the picker closes.',
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

/// Showcases the [CtMainMenuCollage] painter at full background scale
/// (mirrors how `CtMainMenu` consumes it via `Positioned.fill`). The host
/// uses the `editorialMonocle` scaffold color underneath so reviewers see
/// the collage's `--accent` glyphs against the canonical `--bg` token.
class _CtMainMenuCollageStory extends StatelessWidget {
  const _CtMainMenuCollageStory();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.editorialMonocle,
      child: Material(
        color: AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: const SizedBox.expand(child: CtMainMenuCollage()),
      ),
    );
  }
}
