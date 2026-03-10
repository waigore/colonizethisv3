import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'config/themes.dart';
import 'features/game/widgets/civilian_units_panel.dart';
import 'features/game/widgets/production_panel.dart';
import 'features/game/widgets/production_panel_demo_data.dart';
import 'features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'features/game/widgets/province_overlay_demo_data.dart';
import 'widgets/debug_init_game.dart';
import 'widgets/debug_map_visibility_story.dart';
import 'widgets/game_setup.dart';
import 'widgets/main_menu.dart';
import 'widgets/region_map_debug.dart';

/// Widgetbook entry point. Run with: flutter run -t lib/widgetbook.dart
void main() {
  runApp(const CtWidgetbookApp());
}

/// Simulated mobile viewport (360×640 dp) for layout verification. SPEC/ui/mobile-adaptation.md.
Widget mobileViewport(BuildContext context, Widget child) {
  const double width = 360;
  const double height = 640;
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(size: Size(width, height)),
    child: SizedBox(
      width: width,
      height: height,
      child: child,
    ),
  );
}

/// Widgetbook app with colonial theme. SPEC/ui/main-menu.md; UXD 03a. SPEC/ui/game-setup.md; UXD 03b. Mobile viewport: SPEC/ui/mobile-adaptation.md.
class CtWidgetbookApp extends StatelessWidget {
  const CtWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        ...mainMenuDirectories,
        ...gameSetupDirectories,
        ...mapWidgetDirectories,
        ...provinceOverlayDirectories,
        ...productionPanelDirectories,
        ...civilianUnitsPanelDirectories,
      ],
      lightTheme: AppThemes.colonial,
      darkTheme: AppThemes.colonial,
    );
  }
}

/// Main Menu stories (plain and pixel). Register in widget_catalog.json.
List<WidgetbookNode> get mainMenuDirectories => [
      WidgetbookFolder(
        name: 'Main Menu',
        children: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.plain,
              state: MainMenuState.default_,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'After victory',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.plain,
              state: MainMenuState.afterVictory,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'No saves',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.plain,
              state: MainMenuState.noSaves,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Default (pixel)',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.pixelArt,
              state: MainMenuState.default_,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'After victory (pixel)',
            builder: (context) => CtMainMenu(
              variant: MainMenuVariant.pixelArt,
              state: MainMenuState.afterVictory,
              version: 'v1.0.0',
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Default (mobile)',
            builder: (context) => mobileViewport(
              context,
              CtMainMenu(
                variant: MainMenuVariant.plain,
                state: MainMenuState.default_,
                version: 'v1.0.0',
                onNewGame: () {},
                onLoadGame: () {},
                onSettings: () {},
                onQuit: () {},
              ),
            ),
          ),
        ],
      ),
    ];

/// All choices unselected on load. SPEC/ui/game-setup.md.
List<String> _unselectedInitialOrderedGpIds() => List.filled(6, '');

/// Game Setup stories. SPEC/ui/game-setup.md; UXD 03b.
List<WidgetbookNode> get gameSetupDirectories => [
      WidgetbookFolder(
        name: 'Game Setup',
        children: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => CtGameSetup(
              variant: GameSetupVariant.plain,
              state: GameSetupState.default_,
              naming: defaultNamingConfig,
              initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
              initialLeaderVariantByGpId: {},
              onStartGame: (_, __) {},
              onBack: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Loading',
            builder: (context) => CtGameSetup(
              variant: GameSetupVariant.plain,
              state: GameSetupState.loading,
              naming: defaultNamingConfig,
              initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
              initialLeaderVariantByGpId: {},
              onStartGame: (_, __) {},
              onBack: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Default (pixel)',
            builder: (context) => CtGameSetup(
              variant: GameSetupVariant.pixelArt,
              state: GameSetupState.default_,
              naming: defaultNamingConfig,
              initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
              initialLeaderVariantByGpId: {},
              onStartGame: (_, __) {},
              onBack: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Loading (pixel)',
            builder: (context) => CtGameSetup(
              variant: GameSetupVariant.pixelArt,
              state: GameSetupState.loading,
              naming: defaultNamingConfig,
              initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
              initialLeaderVariantByGpId: {},
              onStartGame: (_, __) {},
              onBack: () {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Default (mobile)',
            builder: (context) => mobileViewport(
              context,
              CtGameSetup(
                variant: GameSetupVariant.plain,
                state: GameSetupState.default_,
                naming: defaultNamingConfig,
                initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
                initialLeaderVariantByGpId: {},
                onStartGame: (_, __) {},
                onBack: () {},
              ),
            ),
          ),
        ],
      ),
    ];

/// Map Widget stories (debug mode). SPEC/ui/map-widget.md.
List<WidgetbookNode> get mapWidgetDirectories => [
      WidgetbookFolder(
        name: 'Map Widget',
        children: [
          WidgetbookUseCase(
            name: 'Debug mode (visibility toggle)',
            builder: (context) => const DebugMapVisibilityStory(
              showPoliticalOverlay: true,
            ),
          ),
          WidgetbookUseCase(
            name: 'Debug mode (political overlay off)',
            builder: (context) => const DebugMapVisibilityStory(
              showPoliticalOverlay: false,
            ),
          ),
          WidgetbookUseCase(
            name: 'Debug mode (mobile)',
            builder: (context) => mobileViewport(
              context,
              Builder(
                builder: (context) {
                  return const DebugMapVisibilityStory(
                    showPoliticalOverlay: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ];

/// Civilian Units Panel stories. SPEC/ui/civilian-units-panel.md.
List<WidgetbookNode> get civilianUnitsPanelDirectories => [
  WidgetbookFolder(
    name: 'Civilian Units Panel',
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
            child: CivilianUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'With map',
        builder: (context) => const _CivilianPanelWithMapStory(),
      ),
    ],
  ),
];

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

/// Province/Sea Zone Detail Overlay stories. SPEC/ui/province-sea-zone-detail-overlay.md.
List<WidgetbookNode> get provinceOverlayDirectories => [
      WidgetbookFolder(
        name: 'Province Overlay',
        children: [
          WidgetbookUseCase(
            name: 'Standalone — province',
            builder: (context) {
              final game = demoGameForOverlay;
              final region = demoRegionForOverlay;
              return SizedBox(
                width: 320,
                height: 400,
                child: ProvinceSeaZoneDetailOverlay(
                  game: game,
                  region: region,
                  selectedId: sampleProvinceIdForOverlay,
                  displayId: sampleProvinceIdForOverlay,
                  humanPlayerId: game.players.first.id,
                  onClose: () {},
                ),
              );
            },
          ),
          WidgetbookUseCase(
            name: 'Standalone — sea zone',
            builder: (context) {
              final game = demoGameForOverlay;
              final region = demoRegionForOverlay;
              return SizedBox(
                width: 320,
                height: 280,
                child: ProvinceSeaZoneDetailOverlay(
                  game: game,
                  region: region,
                  selectedId: sampleSeaZoneIdForOverlay,
                  displayId: sampleSeaZoneIdForOverlay,
                  humanPlayerId: game.players.first.id,
                  onClose: () {},
                ),
              );
            },
          ),
          WidgetbookUseCase(
            name: 'Standalone (mobile)',
            builder: (context) => mobileViewport(
              context,
              Builder(
                builder: (context) {
                  final game = demoGameForOverlay;
                  final region = demoRegionForOverlay;
                  return ProvinceSeaZoneDetailOverlay(
                    game: game,
                    region: region,
                    selectedId: sampleProvinceIdForOverlay,
                    displayId: sampleProvinceIdForOverlay,
                    humanPlayerId: game.players.first.id,
                    onClose: () {},
                  );
                },
              ),
            ),
          ),
          WidgetbookUseCase(
            name: 'With map — province selected',
            builder: (context) =>
                _MapWithOverlayStory(selectedId: sampleProvinceIdForOverlay),
          ),
          WidgetbookUseCase(
            name: 'With map — sea zone selected',
            builder: (context) =>
                _MapWithOverlayStory(selectedId: sampleSeaZoneIdForOverlay),
          ),
        ],
      ),
    ];

/// Production panel with local state for Widgetbook. SPEC/ui/production-panel.md.
class _ProductionPanelStory extends StatefulWidget {
  const _ProductionPanelStory({
    this.playerOverride,
    this.useFullAvailability = true,
  });

  /// When set, used instead of the full/partial demo player.
  final Player? playerOverride;
  /// When true, use full-availability demo player; when false, partial.
  final bool useFullAvailability;

  @override
  State<_ProductionPanelStory> createState() => _ProductionPanelStoryState();
}

class _ProductionPanelStoryState extends State<_ProductionPanelStory> {
  Map<String, int> _desiredOutputByRecipe = const {};

  @override
  Widget build(BuildContext context) {
    final game = demoGameForOverlay;
    final player = widget.playerOverride ??
        (widget.useFullAvailability
            ? fullAvailabilityProductionPlayer()
            : partialAvailabilityProductionPlayer());
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
      child: ProductionPanel(
        game: game,
        player: player,
        desiredOutputByRecipe: _desiredOutputByRecipe,
        onDesiredOutputChanged: (next) =>
            setState(() => _desiredOutputByRecipe = next),
      ),
    );
  }
}

/// Civilian Units Panel + map in tandem. SPEC/ui/civilian-units-panel.md.
/// Demonstrates assign (order menu → valid tiles glow → tile click) and cancel with real game/map.
class _CivilianPanelWithMapStory extends StatefulWidget {
  const _CivilianPanelWithMapStory();

  @override
  State<_CivilianPanelWithMapStory> createState() =>
      _CivilianPanelWithMapStoryState();
}

class _CivilianPanelWithMapStoryState extends State<_CivilianPanelWithMapStory> {
  late Game _game;
  Orders _orders = const Orders();
  int _regionIndex = 0;
  String? _highlightedTileKey;
  String? _centerOnTileKey;
  ({Unit unit, String workTarget})? _workTargetSelection;

  @override
  void initState() {
    super.initState();
    _game = getDebugInitGameResult().game;
  }

  String get _humanPlayerId =>
      _game.players.isNotEmpty ? _game.players.first.id : 'gp1';

  String get _currentRegionId => _regionIndex == 0 ? 'oldWorld' : 'newWorld';

  Set<String>? get _validTileKeys {
    if (_workTargetSelection == null) return null;
    final result = getDebugInitGameResult();
    final valid = getValidWorkOrderTileKeys(
      _game,
      result.combinedTopology,
      _humanPlayerId,
      _workTargetSelection!.unit.id,
      _workTargetSelection!.workTarget,
      _orders,
    );
    return valid.where((k) => k.startsWith('$_currentRegionId|')).toSet();
  }

  void _onLocateUnit(Unit unit) {
    final tileKey = unit.tileKey;
    if (tileKey == null) return;
    final regionId = Unit.regionIdFromTileKey(tileKey);
    setState(() {
      _highlightedTileKey = tileKey;
      _centerOnTileKey = tileKey;
      if (regionId == 'newWorld') {
        _regionIndex = 1;
      } else if (regionId == 'oldWorld') {
        _regionIndex = 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _centerOnTileKey = null);
    });
  }

  void _onTileSelectedForWork(String tileKey) {
    final sel = _workTargetSelection;
    if (sel == null) return;
    final target = sel.workTarget;
    String targetTileKey = tileKey;
    if (target == 'explore' || target == 'steal_tech' || target == 'counter_spy') {
      final parts = tileKey.split('|');
      if (parts.length >= 2) {
        targetTileKey = '${parts[0]}|${parts[1]}|0|0';
      }
    }
    final workOrder = WorkOrder(
      unitId: sel.unit.id,
      target: target,
      targetTileKey: targetTileKey,
    );
    setState(() {
      final list = [...(_orders.workOrdersByPlayerId[_humanPlayerId] ?? []), workOrder];
      _orders = _orders.copyWith(
        workOrdersByPlayerId: {..._orders.workOrdersByPlayerId, _humanPlayerId: list},
      );
      _workTargetSelection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = getDebugInitGameResult();
    final mapViewData = result.mapViewData;
    final region = _regionIndex == 0 ? mapViewData.oldWorld : mapViewData.newWorld;
    return SizedBox(
      width: 900,
      height: 550,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: const Text('Old World'),
                        selected: _regionIndex == 0,
                        onSelected: (_) => setState(() => _regionIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('New World'),
                        selected: _regionIndex == 1,
                        onSelected: (_) => setState(() => _regionIndex = 1),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CtRegionMapDebug(
                    region: region,
                    cellSizePx: 24,
                    onProvinceSelected: (_) {},
                    highlightedTileKey: _highlightedTileKey,
                    centerOnTileKey: _centerOnTileKey,
                    validTileKeys: _validTileKeys,
                    onTileSelected: _workTargetSelection != null ? _onTileSelectedForWork : null,
                    onWorkTargetSelectionCancelled: _workTargetSelection != null
                        ? () => setState(() => _workTargetSelection = null)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 360,
            child: CivilianUnitsPanel(
              game: _game,
              humanPlayerId: _humanPlayerId,
              currentOrders: _orders,
              onLocateUnit: _onLocateUnit,
              onRemoveWorkOrder: (playerId, index) {
                setState(() {
                  final list = List<WorkOrder>.from(
                    _orders.workOrdersByPlayerId[playerId] ?? [],
                  )..removeAt(index);
                  _orders = _orders.copyWith(
                    workOrdersByPlayerId: {..._orders.workOrdersByPlayerId, playerId: list},
                  );
                });
              },
              onCancelUnitWork: (unitId) {
                setState(() => _game = clearUnitCurrentWork(_game, unitId));
              },
              onStartWorkTargetSelection: (unit, workTarget) {
                setState(() => _workTargetSelection = (unit: unit, workTarget: workTarget));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Map + overlay in tandem for Widgetbook. SPEC/ui/province-sea-zone-detail-overlay.md.
class _MapWithOverlayStory extends StatefulWidget {
  const _MapWithOverlayStory({required this.selectedId});

  final String selectedId;

  @override
  State<_MapWithOverlayStory> createState() => _MapWithOverlayStoryState();
}

class _MapWithOverlayStoryState extends State<_MapWithOverlayStory> {
  late String _selectedId;
  String? _hoveredDetailId;
  String? _hoveredTileKey;
  String? _highlightedTileKey;
  CtMapVisibilityMode _visibilityMode = CtMapVisibilityMode.full;

  String get _displayId {
    if (_hoveredTileKey != null) {
      final parts = _hoveredTileKey!.split('|');
      if (parts.length >= 2) {
        return '${parts[0]}|${parts[1]}';
      }
    }
    return _hoveredDetailId ?? _selectedId;
  }

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
  }

  @override
  void didUpdateWidget(covariant _MapWithOverlayStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      _selectedId = widget.selectedId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initResult = getDebugInitGameResult();
    final game = initResult.game;
    final mapViewData = debugMapViewDataWithVisibilityForFirstPlayer();
    final region = mapViewData.oldWorld;
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return SizedBox(
      width: 800,
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChoiceChip(
                  label: const Text('Full visibility'),
                  selected: _visibilityMode == CtMapVisibilityMode.full,
                  onSelected: (_) {
                    setState(() {
                      _visibilityMode = CtMapVisibilityMode.full;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Player-constrained'),
                  selected:
                      _visibilityMode == CtMapVisibilityMode.playerConstrained,
                  onSelected: (_) {
                    setState(() {
                      _visibilityMode = CtMapVisibilityMode.playerConstrained;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CtRegionMapDebug(
                    region: region,
                    cellSizePx: 28,
                    visibilityMode: _visibilityMode,
                    onProvinceSelected: (id) =>
                        setState(() => _selectedId = _selectedId == id ? '' : id),
                    onProvinceHovered: (id) =>
                        setState(() => _hoveredDetailId = id),
                    onTileHovered: (key) =>
                        setState(() => _hoveredTileKey = key),
                    highlightedTileKey: _highlightedTileKey,
                  ),
                ),
                if (!isNarrow && _selectedId.isNotEmpty)
                  SizedBox(
                    width: 320,
                    child: ProvinceSeaZoneDetailOverlay(
                      game: game,
                      region: region,
                      selectedId: _selectedId,
                      displayId: _displayId,
                      humanPlayerId: 'gp1',
                      hoveredTileKey: _hoveredTileKey,
                      onHighlightTile: (k) =>
                          setState(() => _highlightedTileKey = k),
                      onClose: () => setState(() => _selectedId = ''),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
