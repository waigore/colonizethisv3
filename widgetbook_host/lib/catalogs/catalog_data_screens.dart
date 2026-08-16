// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// Extracted out of `catalog_part5.dart` to keep each part fragment file
// under the `repo.part_unit_size` 1000-line ceiling
// (`SPEC/program/part-unit-size.md`).
part of 'catalog.dart';

/// Showcases [CtDropdown] R5c selected-row highlight under the dark
/// editorial-monocle theme. The story preselects a non-null value so
/// opening the picker immediately demonstrates the `--accent-dim` tint
/// + 1 dp `--accent` left-edge border on the row matching that value.
/// Registered as the "CtDropdown — selected-row highlight" use case via
/// `ctDarkThemePrimitiveDirectories` in `catalog_part5.dart`; the class
/// itself lives here so `catalog_part5.dart` stays under the
/// `repo.part_unit_size` 1000-line ceiling.
/// See SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component catalog
/// (CtDropdown) and issue #2859 R5c / S6.
class CtDropdownSelectedRowStory extends StatefulWidget {
  const CtDropdownSelectedRowStory({super.key});

  @override
  State<CtDropdownSelectedRowStory> createState() =>
      CtDropdownSelectedRowStoryState();
}

class CtDropdownSelectedRowStoryState
    extends State<CtDropdownSelectedRowStory> {
  static const List<String> _options = <String>[
    // ignore: avoid_hardcoded_strings_in_widgets
    'England',
    // ignore: avoid_hardcoded_strings_in_widgets
    'France',
    // ignore: avoid_hardcoded_strings_in_widgets
    'Spain',
  ];

  // ignore: avoid_hardcoded_strings_in_widgets
  String? _value = 'France';

  @override
  Widget build(BuildContext context) {
    return CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Tap the trigger — the row matching the current value paints '
            '--accent-dim tint + 1 dp --accent left edge (R5c); other rows '
            'paint a transparent same-width left edge so the layout never '
            'shifts.',
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

Game _victoryScreenStoryGame() {
  return Game(
    id: 'wb_victory_screen',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 12),
      oldWorld: RegionData(
        provinces: [
          const Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
          const Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            ownerId: 'gp2',
          ),
          const Province(
            id: 'oldWorld|p3',
            regionId: 'oldWorld',
            ownerId: 'gp2',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'England', isHuman: true),
      Player(id: 'gp2', displayName: 'France', isHuman: false),
    ],
  );
}

Widget _victoryScreenDefaultStory() {
  final game = _victoryScreenStoryGame();
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    useScaffold: false,
    child: VictoryScreen(game: game, humanPlayerId: 'gp1'),
  );
}

Widget _victoryScreenRivalSelectedStory() {
  final game = _victoryScreenStoryGame();
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    useScaffold: false,
    child: VictoryScreen(
      game: game,
      humanPlayerId: 'gp1',
      initialSelectedPlayerId: 'gp2',
    ),
  );
}

RegionMapViewData _victoryScreenAnnotatedMinimapRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
    height: 2,
    cellSize: 8,
    cells: [
      const CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'London',
      ),
      const CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'London',
      ),
      const CellViewData(x: 0, y: 1, regionCellId: 'sea1', isSea: true),
      const CellViewData(
        x: 1,
        y: 1,
        regionCellId: 'p2',
        isSea: false,
        ownerFactionId: 'gp2',
        provinceDisplayName: 'Paris',
      ),
    ],
    capitalMarkers: const [
      CapitalMarkerView(factionId: 'gp1', displayName: 'England', x: 0, y: 0),
    ],
    portMarkers: const [],
    factionColors: const {'gp1': (180, 80, 80), 'gp2': (80, 80, 180)},
    greatPowerFactionIds: {'gp1', 'gp2'},
    terrainColors: const {},
    townMarkers: const [
      TownMarkerView(
        x: 1,
        y: 1,
        provinceId: 'p2',
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 1,
        townIconStyle: 'euro',
      ),
    ],
  );
}

Widget _victoryScreenAnnotatedMinimapStory() {
  final game = _victoryScreenStoryGame();
  return widgetbookEditorialMonocleApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    useScaffold: false,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: VictoryPoliticalMinimap(
        game: game,
        region: _victoryScreenAnnotatedMinimapRegion(),
        selectedPlayerId: 'gp2',
      ),
    ),
  );
}

const String _kDevelopmentPanelStoryGameId = 'wb_development_panel';
const String _kDevelopmentPanelFogStoryGameId = 'wb_development_panel_fog';
const String _kDevelopmentPanelAssignedStoryGameId =
    'wb_development_panel_assigned';
const String _kDevelopmentPanelAssignPreviewStoryGameId =
    'wb_development_panel_assign_preview';

Game _developmentPanelStoryGame() {
  const human = 'gp1';
  const p1 = 'oldWorld|p1';
  const p2 = 'oldWorld|p2';
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  const tileP2 = 'oldWorld|p2|0|1';

  return Game(
    id: _kDevelopmentPanelStoryGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: 'oldWorld',
            ownerId: human,
            displayName: 'Avalon',
            townTileKey: tileA,
          ),
          Province(
            id: p2,
            regionId: 'oldWorld',
            ownerId: human,
            displayName: 'Barren',
            townTileKey: tileP2,
          ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: human,
            locationProvinceId: p1,
            tileKey: tileA,
            status: UnitStatus.idle,
          ),
          Unit(
            id: 'e1',
            type: kUnitTypeEngineer,
            ownerId: human,
            locationProvinceId: p1,
            tileKey: tileA,
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          p1: [tileA, tileB],
          p2: [tileP2],
        },
      },
      resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
      tileState: const TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
      playerVisibilityByTile: {
        human: {
          tileA: 'fullyVisible',
          tileB: 'fullyVisible',
          tileP2: 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(
        id: human,
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: p1,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'p1',
          x: 0,
          y: 0,
        ),
        stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
        techUnlocked: {kTechIdCircularSaw: true},
      ),
    ],
  );
}

Game _developmentPanelFogVisibilityStoryGame() {
  const human = 'gp1';
  const p1 = 'oldWorld|p1';
  const p2 = 'oldWorld|p2';
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  const tileHidden = 'oldWorld|p1|2|0';
  const tileP2 = 'oldWorld|p2|0|1';
  const tileP2Fog = 'oldWorld|p2|1|1';
  const tileP2Visible = 'oldWorld|p2|2|1';

  return Game(
    id: _kDevelopmentPanelFogStoryGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: 'oldWorld',
            ownerId: human,
            displayName: 'Avalon',
            townTileKey: tileA,
          ),
          Province(
            id: p2,
            regionId: 'oldWorld',
            ownerId: human,
            displayName: 'Barren',
            townTileKey: tileP2,
          ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: human,
            locationProvinceId: p1,
            tileKey: tileA,
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          p1: [tileA, tileB, tileHidden],
          p2: [tileP2, tileP2Fog, tileP2Visible],
        },
      },
      resourceByTileKey: {tileA: 'grain', tileB: 'grain', tileHidden: 'grain'},
      tileState: const TileMapState(
        improvementByTile: {tileA: 0, tileB: 0, tileHidden: 0},
      ),
      playerVisibilityByTile: {
        human: {
          tileA: 'fullyVisible',
          tileB: 'fogged',
          tileP2Fog: 'fogged',
          tileP2Visible: 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(
        id: human,
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: p1,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'p1',
          x: 0,
          y: 0,
        ),
        stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
        techUnlocked: {kTechIdCircularSaw: true},
      ),
    ],
  );
}

Game _developmentPanelAssignedCiviliansStoryGame() {
  const human = 'gp1';
  const p1 = 'oldWorld|p1';
  const p2 = 'oldWorld|p2';
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  const tileP2 = 'oldWorld|p2|0|1';

  return Game(
    id: _kDevelopmentPanelAssignedStoryGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: 'oldWorld',
            ownerId: human,
            displayName: 'Avalon',
            townTileKey: tileA,
          ),
          Province(
            id: p2,
            regionId: 'oldWorld',
            ownerId: human,
            displayName: 'Barren',
            townTileKey: tileP2,
          ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: human,
            locationProvinceId: p1,
            tileKey: tileA,
            status: UnitStatus.idle,
          ),
          Unit(
            id: 'b2',
            type: kUnitTypeBuilder,
            ownerId: human,
            locationProvinceId: p1,
            tileKey: tileA,
            status: UnitStatus.idle,
          ),
          Unit(
            id: 'e1',
            type: kUnitTypeEngineer,
            ownerId: human,
            locationProvinceId: p1,
            tileKey: tileA,
            status: UnitStatus.working,
            currentWork: const CurrentWork(
              workTarget: 'build_road',
              tileKey: tileB,
              totalTurns: 3,
              remainingTurns: 2,
            ),
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          p1: [tileA, tileB],
          p2: [tileP2],
        },
      },
      resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
      tileState: const TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
      playerVisibilityByTile: {
        human: {
          tileA: 'fullyVisible',
          tileB: 'fullyVisible',
          tileP2: 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(
        id: human,
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: p1,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'p1',
          x: 0,
          y: 0,
        ),
        stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
        techUnlocked: {kTechIdCircularSaw: true},
      ),
    ],
  );
}

Orders _developmentPanelAssignedCiviliansStoryOrders() {
  return Orders(
    workOrdersByPlayerId: {
      'gp1': [
        WorkOrder(
          unitId: 'b1',
          target: 'build_improvement',
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      ],
    },
  );
}

class _DevelopmentPanelStoryGameService extends StoryStubGameService {
  static final Map<String, MapTopology> _topologyByRegion = {
    'oldWorld': MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'p2',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
    ),
    'newWorld': const MapTopology(nodes: [], edges: []),
  };

  static final Map<String, TileMapResult> _tileMapByRegion2x2 = {
    'oldWorld': TileMapResult(
      width: 2,
      height: 2,
      grid: const [
        ['p1', 'p1'],
        ['p2', 'p2'],
      ],
      terrainGrid: const [
        [TerrainType.plains, TerrainType.plains],
        [TerrainType.plains, TerrainType.plains],
      ],
      resourceGrid: [
        [Resource.grain, Resource.grain],
        [null, null],
      ],
    ),
    'newWorld': TileMapResult(
      width: 1,
      height: 1,
      grid: const [
        ['nw1'],
      ],
      terrainGrid: const [
        [TerrainType.plains],
      ],
    ),
  };

  static final Map<String, TileMapResult> _tileMapByRegion3x2 = {
    'oldWorld': TileMapResult(
      width: 3,
      height: 2,
      grid: const [
        ['p1', 'p1', 'p1'],
        ['p2', 'p2', 'p2'],
      ],
      terrainGrid: const [
        [TerrainType.plains, TerrainType.plains, TerrainType.plains],
        [TerrainType.plains, TerrainType.plains, TerrainType.plains],
      ],
      resourceGrid: [
        [Resource.grain, Resource.grain, Resource.grain],
        [null, null, null],
      ],
    ),
    'newWorld': TileMapResult(
      width: 1,
      height: 1,
      grid: const [
        ['nw1'],
      ],
      terrainGrid: const [
        [TerrainType.plains],
      ],
    ),
  };

  static final MapTopology _combinedTopology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
  );

  @override
  GameMapData? getMapData(String gameId) {
    final tileMapByRegion = switch (gameId) {
      _kDevelopmentPanelFogStoryGameId => _tileMapByRegion3x2,
      _kDevelopmentPanelStoryGameId ||
      _kDevelopmentPanelAssignedStoryGameId ||
      _kDevelopmentPanelAssignPreviewStoryGameId => _tileMapByRegion2x2,
      _ => null,
    };
    if (tileMapByRegion == null) return null;
    return (
      combinedTopology: _combinedTopology,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: _topologyByRegion,
      warpLinks: null,
    );
  }
}

Widget _developmentPanelStoryHost({
  required Game game,
  required Orders orders,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(orders)),
      gameServiceProvider.overrideWith(
        (ref) => _DevelopmentPanelStoryGameService(),
      ),
    ],
    child: widgetbookEditorialMonocleApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      useScaffold: false,
      child: child,
    ),
  );
}

Widget _developmentPanelStory({required Game game, required Orders orders}) {
  return _developmentPanelStoryHost(
    game: game,
    orders: orders,
    child: DevelopmentScreen(game: game, humanPlayerId: 'gp1'),
  );
}

Widget _developmentPanelDefaultStory() {
  final game = _developmentPanelStoryGame();
  return _developmentPanelStory(game: game, orders: const Orders());
}

Widget _developmentPanelFogVisibilityStory() {
  final game = _developmentPanelFogVisibilityStoryGame();
  return _developmentPanelStory(game: game, orders: const Orders());
}

Widget _developmentPanelAssignedCiviliansStory() {
  final game = _developmentPanelAssignedCiviliansStoryGame();
  return _developmentPanelStory(
    game: game,
    orders: _developmentPanelAssignedCiviliansStoryOrders(),
  );
}

Game _developmentPanelAssignPreviewStoryGame() {
  final base = _developmentPanelStoryGame();
  return base.copyWith(
    id: _kDevelopmentPanelAssignPreviewStoryGameId,
    worldState: base.worldState.copyWith(
      tileState: const TileMapState(
        improvementByTile: {'oldWorld|p1|0|0': 1, 'oldWorld|p1|1|0': 1},
      ),
    ),
    players: [
      base.players.first.copyWith(
        techUnlocked: const {
          kTechIdCircularSaw: true,
          kTechIdLandEnclosure: true,
        },
      ),
    ],
  );
}

Widget _developmentPanelAssignPreviewStory() {
  return _developmentPanelStory(
    game: _developmentPanelAssignPreviewStoryGame(),
    orders: const Orders(),
  );
}

/// Development screen stories. SPEC/ui/development-panel.md.
List<WidgetbookNode> get developmentScreenDirectories => [
  WidgetbookFolder(
    name: 'Development Panel',
    children: [
      WidgetbookUseCase(
        name: 'Default — Old World',
        builder: (context) => _developmentPanelDefaultStory(),
      ),
      WidgetbookUseCase(
        name: 'Default — Old World (mobile)',
        builder: (context) =>
            mobileViewport(context, _developmentPanelDefaultStory()),
      ),
      WidgetbookUseCase(
        name: 'Default — Old World (wide)',
        builder: (context) =>
            wideViewport(context, _developmentPanelDefaultStory()),
      ),
      WidgetbookUseCase(
        name: 'Fog map — player-constrained visibility',
        builder: (context) => _developmentPanelFogVisibilityStory(),
      ),
      WidgetbookUseCase(
        name: 'Fog map — player-constrained visibility (wide)',
        builder: (context) =>
            wideViewport(context, _developmentPanelFogVisibilityStory()),
      ),
      WidgetbookUseCase(
        name: 'Assigned civilians — overview rows',
        builder: (context) => _developmentPanelAssignedCiviliansStory(),
      ),
      WidgetbookUseCase(
        name: 'Assigned civilians — overview rows (wide)',
        builder: (context) =>
            wideViewport(context, _developmentPanelAssignedCiviliansStory()),
      ),
      WidgetbookUseCase(
        name: 'Assign preview enabled',
        builder: (context) => _developmentPanelAssignPreviewStory(),
      ),
      WidgetbookUseCase(
        name: 'Assign preview enabled (mobile)',
        builder: (context) =>
            mobileViewport(context, _developmentPanelAssignPreviewStory()),
      ),
    ],
  ),
];

/// Victory screen stories. SPEC/ui/victory-panel.md.
List<WidgetbookNode> get victoryScreenDirectories => [
  WidgetbookFolder(
    name: 'Victory Screen',
    children: [
      WidgetbookUseCase(
        name: 'Scaffold (default)',
        builder: (context) => _victoryScreenDefaultStory(),
      ),
      WidgetbookUseCase(
        name: 'Scaffold (mobile)',
        builder: (context) =>
            mobileViewport(context, _victoryScreenDefaultStory()),
      ),
      WidgetbookUseCase(
        name: 'Scaffold (wide side-by-side)',
        builder: (context) =>
            wideViewport(context, _victoryScreenDefaultStory()),
      ),
      WidgetbookUseCase(
        name: 'Scaffold (rival GP selected)',
        builder: (context) => _victoryScreenRivalSelectedStory(),
      ),
      WidgetbookUseCase(
        name: 'Scaffold (rival GP selected, wide)',
        builder: (context) =>
            wideViewport(context, _victoryScreenRivalSelectedStory()),
      ),
      WidgetbookUseCase(
        name: 'Political minimap (annotated)',
        builder: (context) => _victoryScreenAnnotatedMinimapStory(),
      ),
    ],
  ),
];

/// Story for [CtFullScreenDialogueShell] (issue #2914 S2).
///
/// Demonstrates the reusable scrim + centered [CtDialogShell] shell that
/// the four blocking dialogue overlays (overture, call-to-arms,
/// intervention, game-start intro) now share. The backdrop slot mirrors
/// a "fake game canvas" the scrim dims; the body slot composes a
/// representative title + brass divider + body content stack so the
/// catalog can preview the canonical scrim token, frame, and inner
/// padding from `SPEC/ui/pixel-art-ui-catalog.md` §
/// *CtFullScreenDialogueShell*. Registered as the "CtFullScreenDialogueShell
/// — scrim + framed body" use case via `ctDarkThemePrimitiveDirectories`
/// in `catalog_part5.dart`; the class itself lives here so
/// `catalog_part5.dart` stays under the `repo.part_unit_size` 1000-line
/// ceiling.
class CtFullScreenDialogueShellStory extends StatelessWidget {
  const CtFullScreenDialogueShellStory({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.editorialMonocle,
      child: CtFullScreenDialogueShell(
        backdrop: ColoredBox(
          color: AppThemes.editorialMonocle.scaffoldBackgroundColor,
          child: Center(
            child: Text(
              // ignore: avoid_hardcoded_strings_in_widgets
              'underlying canvas / app shell',
              style: TextStyle(color: EditorialMonoclePalette.muted),
            ),
          ),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              // ignore: avoid_hardcoded_strings_in_widgets
              'Overlay title',
              style: TextStyle(
                color: EditorialMonoclePalette.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05 * 16,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const CtBrassDivider(),
            const SizedBox(height: 12),
            const Text(
              // ignore: avoid_hardcoded_strings_in_widgets
              'Reusable scrim + framed body shared by overture, call-to-arms, intervention, and game-start intro overlays (Refs #2914 S2).',
            ),
          ],
        ),
      ),
    );
  }
}
