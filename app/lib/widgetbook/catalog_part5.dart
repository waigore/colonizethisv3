// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
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
      theme: AppThemes.editorialMonocle,
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

/// Diplomacy detail screen stories. SPEC/ui/diplomacy-detail-screen.md.
List<WidgetbookNode> get diplomacyDetailScreenDirectories => [
  WidgetbookFolder(
    name: 'Diplomacy Detail Screen',
    children: [
      WidgetbookUseCase(
        name: 'Default — GP with history and dossier',
        builder: (context) => _diplomacyDetailScreenProviderScope(),
      ),
    ],
  ),
];

/// Stories for the dark editorial-monocle theme primitives introduced by
/// issue #2859 S1/S8/S9/S10/S11/S13: `CtGradients`, `CtBrassDivider`,
/// `CtToggleSwitch`, `CtSectionLabel`, `CtResourceCell`, and
/// `CtProgressBar`. SPEC/ui/pixel-art-ui-catalog.md
/// § Editorial-monocle palette.
List<WidgetbookNode> get ctDarkThemePrimitiveDirectories => [
  WidgetbookFolder(
    name: 'Ct- Dark Theme Primitives',
    children: [
      WidgetbookUseCase(
        name: 'CtGradients — token swatches',
        builder: (context) => _CtGradientsStory(),
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
        name: 'CtCompassRose — size sweep',
        builder: (context) => _CtCompassRoseStory(),
      ),
      WidgetbookUseCase(
        name: 'CtFleurDeLisOrnament — flanking pair',
        builder: (context) => _CtFleurDeLisOrnamentStory(),
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
