import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'config/themes.dart';
import 'features/game/widgets/civilian_units_panel.dart';
import 'features/game/widgets/diplomacy_panel.dart';
import 'features/game/widgets/military_units_panel.dart';
import 'features/game/logic/naval_fleet_split_apply.dart';
import 'features/game/widgets/naval_units_panel.dart';
import 'features/game/widgets/production_commodity_breakdown_dialog.dart';
import 'features/game/widgets/production_panel.dart';
import 'features/game/widgets/production_panel_demo_data.dart';
import 'features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'features/game/widgets/province_overlay_demo_data.dart';
import 'features/game/widgets/tech_tree_widget.dart';
import 'features/game/widgets/technology_screen.dart';
import 'features/game/widgets/train_civilians_dialog.dart';
import 'l10n/l10n.dart';
import 'providers/production_allocation_provider.dart';
import 'features/game/widgets/train_military_dialog.dart';
import 'widgets/debug_init_game.dart';
import 'widgets/ct_choice_chip.dart';
import 'widgets/debug_map_visibility_story.dart';
import 'widgets/game_setup.dart';
import 'widgets/main_menu.dart';
import 'widgets/ct_nine_patch_button.dart';
import 'widgets/ct_region_map.dart';
import 'features/game/flame/game_region_minimap.dart';
import 'features/game/flame/region_map_viewport_snapshot.dart';

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
    child: SizedBox(width: width, height: height, child: child),
  );
}

/// Widgetbook app with colonial theme. SPEC/ui/main-menu.md; UXD 03a. SPEC/ui/game-setup.md; UXD 03b. Mobile viewport: SPEC/ui/mobile-adaptation.md.
class CtWidgetbookApp extends StatelessWidget {
  const CtWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        ...buttonDirectories,
        ...mainMenuDirectories,
        ...gameSetupDirectories,
        ...mapWidgetDirectories,
        ...provinceOverlayDirectories,
        ...productionPanelDirectories,
        ...civilianUnitsPanelDirectories,
        ...trainCiviliansDialogDirectories,
        ...trainMilitaryDialogDirectories,
        ...militaryUnitsPanelDirectories,
        ...navalUnitsPanelDirectories,
        ...diplomacyPanelDirectories,
        ...techTreeDirectories,
      ],
      lightTheme: AppThemes.colonial,
      darkTheme: AppThemes.colonial,
    );
  }
}

/// Nine-patch button stories. SPEC/ui/buttons-nine-patch.md; catalog: CtNinePatchButton.
List<WidgetbookNode> get buttonDirectories => [
  WidgetbookFolder(
    name: 'Buttons',
    children: [
      WidgetbookUseCase(
        name: 'CtNinePatchButton',
        builder: (context) => Theme(
          data: AppThemes.colonial,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CtNinePatchButton(
                  onPressed: () {},
                  child: Text(appL10n(context).widgetbook_primaryAction),
                ),
                const SizedBox(height: 12),
                CtNinePatchButton(
                  onPressed: null,
                  enabled: false,
                  child: Text(appL10n(context).widgetbook_disabled),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: CtNinePatchButton(
                    onPressed: () {},
                    child: Text(appL10n(context).widgetbook_fixedWidth),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
];

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
        name: 'With resume game',
        builder: (context) => CtMainMenu(
          variant: MainMenuVariant.plain,
          state: MainMenuState.default_,
          version: 'v1.0.0',
          onNewGame: () {},
          resumeGameVisible: true,
          onResumeGame: () {},
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
          onStartGame: (_, _) {},
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
          onStartGame: (_, _) {},
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
          onStartGame: (_, _) {},
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
          onStartGame: (_, _) {},
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
            onStartGame: (_, _) {},
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
        builder: (context) =>
            const DebugMapVisibilityStory(showPoliticalOverlay: true),
      ),
      WidgetbookUseCase(
        name: 'Debug mode (political overlay off)',
        builder: (context) =>
            const DebugMapVisibilityStory(showPoliticalOverlay: false),
      ),
      WidgetbookUseCase(
        name: 'Debug mode (mobile)',
        builder: (context) => mobileViewport(
          context,
          Builder(
            builder: (context) {
              return const DebugMapVisibilityStory(showPoliticalOverlay: true);
            },
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Region minimap (mock viewport)',
        builder: (context) => const _RegionMinimapWidgetbookStory(),
      ),
    ],
  ),
];

/// Region minimap with mock viewport + Riverpod visibility. SPEC/ui/empire-overview.md § Region minimap.
class _RegionMinimapWidgetbookStory extends StatefulWidget {
  const _RegionMinimapWidgetbookStory();

  @override
  State<_RegionMinimapWidgetbookStory> createState() =>
      _RegionMinimapWidgetbookStoryState();
}

class _RegionMinimapWidgetbookStoryState
    extends State<_RegionMinimapWidgetbookStory> {
  late final AppEventBus _bus = AppEventBus.create();

  @override
  void dispose() {
    _bus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = getDebugInitGameResult();
    final region = result.mapViewData.oldWorld;
    final w = region.width * 24.0;
    final h = region.height * 24.0;
    final zFit = computeRegionMapFitMapZoom(
      viewportWidthLogical: 320,
      viewportHeightLogical: 240,
      mapWidthWorld: w,
      mapHeightWorld: h,
    );
    final viewport = RegionMapViewportSnapshot(
      regionId: region.regionId,
      cellSizePx: 24,
      mapWidthWorld: w,
      mapHeightWorld: h,
      cameraCenterX: w / 2,
      cameraCenterY: h / 2,
      zoom: zFit,
      fitMapZoom: zFit,
      viewportWidthLogical: 320,
      viewportHeightLogical: 240,
    );
    return ProviderScope(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GameRegionMinimap(
            region: region,
            viewportSnapshot: viewport,
            bus: _bus,
          ),
        ),
      ),
    );
  }
}

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
              bus: AppEventBus(),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'With map',
        builder: (context) => const _CivilianPanelWithMapStory(),
      ),
      WidgetbookUseCase(
        name: 'As bottom sheet',
        builder: (context) => const _CivilianPanelAsBottomSheetStory(),
      ),
    ],
  ),
];

/// Train Civilians Dialog stories. SPEC/ui/train-civilians-dialog.md.
List<WidgetbookNode> get trainCiviliansDialogDirectories => [
  WidgetbookFolder(
    name: 'Train Civilians Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Standalone',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.firstWhere((p) => p.isHuman).id
              : game.players.first.id;
          final player = game.players.firstWhere((p) => p.id == humanPlayerId);
          final richGame = game.copyWith(
            players: [
              player.copyWith(
                treasury: 10000,
                stockpile: player.stockpile.merge(
                  const Stockpile(quantities: {'paper': 100}),
                ),
              ),
              ...game.players.where((p) => p.id != humanPlayerId),
            ],
          );
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: TrainCiviliansDialog(
                  game: richGame,
                  humanPlayerId: humanPlayerId,
                  currentOrders: const Orders(),
                  bus: AppEventBus.create(),
                ),
              ),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'With locked units',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.firstWhere((p) => p.isHuman).id
              : game.players.first.id;
          final player = game.players.firstWhere((p) => p.id == humanPlayerId);
          final noTechGame = game.copyWith(
            players: [
              player.copyWith(
                treasury: 10000,
                stockpile: player.stockpile.merge(
                  const Stockpile(quantities: {'paper': 100}),
                ),
                techUnlocked: <String, bool>{},
              ),
              ...game.players.where((p) => p.id != humanPlayerId),
            ],
          );
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: TrainCiviliansDialog(
                  game: noTechGame,
                  humanPlayerId: humanPlayerId,
                  currentOrders: const Orders(),
                  bus: AppEventBus.create(),
                ),
              ),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Low resources',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.firstWhere((p) => p.isHuman).id
              : game.players.first.id;
          final player = game.players.firstWhere((p) => p.id == humanPlayerId);
          final poorGame = game.copyWith(
            players: [
              player.copyWith(
                treasury: 500,
                stockpile: player.stockpile.merge(
                  const Stockpile(quantities: {'paper': 3}),
                ),
              ),
              ...game.players.where((p) => p.id != humanPlayerId),
            ],
          );
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: TrainCiviliansDialog(
                  game: poorGame,
                  humanPlayerId: humanPlayerId,
                  currentOrders: const Orders(),
                  bus: AppEventBus.create(),
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
];

/// Production Panel stories. SPEC/ui/production-panel.md.
List<WidgetbookNode> get productionPanelDirectories => [
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
            theme: AppThemes.colonial,
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
            theme: AppThemes.colonial,
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
      WidgetbookUseCase(
        name: 'Commodity breakdown dialog (standalone)',
        builder: (_) {
          final game = demoGameForOverlay;
          final player = fullAvailabilityProductionPlayer();
          return ProviderScope(
            child: MaterialApp(
              theme: AppThemes.colonial,
              home: Scaffold(
                body: Builder(
                  builder: (ctx) {
                    return Center(
                      child: TextButton(
                        onPressed: () {
                          showDialog<void>(
                            context: ctx,
                            builder: (_) => ProductionCommodityBreakdownDialog(
                              game: game,
                              player: player,
                              topology: const MapTopology(),
                              tileMapByRegion: null,
                              currentOrders: const Orders(),
                            ),
                          );
                        },
                        child: Text(
                          appL10n(ctx).widgetbook_openBreakdownDialog,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
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
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: game.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
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
              displayId: sampleSeaZoneIdForOverlay,
              selectedTileKey: null,
              humanPlayerId: game.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
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
                displayId: sampleProvinceIdForOverlay,
                selectedTileKey: sampleTileKeyForProvinceOverlay,
                humanPlayerId: game.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
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

/// Production panel for Widgetbook with Riverpod allocation state.
/// SPEC/ui/production-panel.md.
class _ProductionPanelStory extends StatelessWidget {
  const _ProductionPanelStory({
    this.playerOverride,
    this.useFullAvailability = true,
  });

  /// When set, used instead of the full/partial demo player.
  final Player? playerOverride;

  /// When true, use full-availability demo player; when false, partial.
  final bool useFullAvailability;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _ProductionPanelStoryBody(
        playerOverride: playerOverride,
        useFullAvailability: useFullAvailability,
      ),
    );
  }
}

class _ProductionPanelStoryBody extends ConsumerWidget {
  const _ProductionPanelStoryBody({
    required this.playerOverride,
    required this.useFullAvailability,
  });

  final Player? playerOverride;
  final bool useFullAvailability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = demoGameForOverlay;
    final player =
        playerOverride ??
        (useFullAvailability
            ? fullAvailabilityProductionPlayer()
            : partialAvailabilityProductionPlayer());
    final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
    final netDeltasByCommodity = previewStockpileNetDeltaByCommodityForPlayer(
      game: game,
      topology: const MapTopology(),
      playerId: player.id,
      tileMapByRegion: null,
      defaultAssignmentsByPlayerId: {
        player.id: assignedRecipesFromDesiredOutput(desiredOutputByRecipe),
      },
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
      child: ProductionPanel(
        game: game,
        player: player,
        desiredOutputByRecipe: desiredOutputByRecipe,
        netDeltasByCommodity: netDeltasByCommodity,
        onDesiredOutputChanged: (next) {
          ref.read(productionDesiredOutputProvider.notifier).replaceAll(next);
        },
        onOpenCommodityBreakdown: () {
          showDialog<void>(
            context: context,
            builder: (ctx) => ProductionCommodityBreakdownDialog(
              game: game,
              player: player,
              topology: const MapTopology(),
              tileMapByRegion: null,
              currentOrders: const Orders(),
            ),
          );
        },
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

class _CivilianPanelWithMapStoryState
    extends State<_CivilianPanelWithMapStory> {
  late Game _game;
  late AppEventBus _panelBus;
  final List<StreamSubscription<dynamic>> _sessionCommandSubs = [];
  Orders _orders = const Orders();
  int _regionIndex = 0;
  String? _secondaryHighlightTileKey;
  String? _centerOnTileKey;
  ({Unit unit, String workTarget})? _workTargetSelection;
  CtMapVisibilityMode _visibilityMode = CtMapVisibilityMode.full;
  bool _showProvinceNames = true;
  Set<String>? _cachedValidTileKeys;
  String? _cachedWorkTargetSelection;

  @override
  void initState() {
    super.initState();
    _game = getDebugInitGameResult().game;
    _panelBus = AppEventBus.create();
    _sessionCommandSubs.addAll([
      _panelBus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
        if (!mounted) return;
        setState(() {
          _orders = removePendingWorkOrderAt(_orders, e.playerId, e.index);
        });
      }),
      _panelBus.on<CancelInProgressCivilianWorkRequestedEvent>().listen((e) {
        if (!mounted) return;
        setState(() {
          _game = clearUnitCurrentWork(_game, e.unitId);
        });
      }),
    ]);
  }

  @override
  void dispose() {
    for (final sub in _sessionCommandSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  String get _humanPlayerId =>
      _game.players.isNotEmpty ? _game.players.first.id : 'gp1';

  String get _currentRegionId => _regionIndex == 0 ? 'oldWorld' : 'newWorld';

  String? get _validTileKeysCacheKey {
    if (_workTargetSelection == null) return null;
    return '${_workTargetSelection!.unit.id}|${_workTargetSelection!.workTarget}|$_visibilityMode';
  }

  Set<String>? get _validTileKeys {
    if (_workTargetSelection == null) return null;
    final cacheKey = _validTileKeysCacheKey;
    if (_cachedWorkTargetSelection == cacheKey &&
        _cachedValidTileKeys != null) {
      return _cachedValidTileKeys;
    }
    final result = getDebugInitGameResult();

    Set<String> valid;
    if (_visibilityMode == CtMapVisibilityMode.playerConstrained) {
      final view = buildPlayerView(
        _game,
        result.combinedTopology,
        _humanPlayerId,
      );
      valid = getValidWorkOrderTileKeysWithVisibility(
        game: _game,
        topology: result.combinedTopology,
        view: view,
        unitId: _workTargetSelection!.unit.id,
        workTarget: _workTargetSelection!.workTarget,
        currentOrders: _orders,
        tileMapByRegion: result.tileMapByRegion,
      );
    } else {
      valid = getValidWorkOrderTileKeys(
        _game,
        result.combinedTopology,
        _humanPlayerId,
        _workTargetSelection!.unit.id,
        _workTargetSelection!.workTarget,
        _orders,
        tileMapByRegion: result.tileMapByRegion,
      );
    }

    final filtered = valid
        .where((k) => k.startsWith('$_currentRegionId|'))
        .toSet();
    _cachedValidTileKeys = filtered;
    _cachedWorkTargetSelection = cacheKey;
    return filtered;
  }

  void _onTileSelectedForWork(String tileKey) {
    final sel = _workTargetSelection;
    if (sel == null) {
      return;
    }
    final target = sel.workTarget;
    String targetTileKey = tileKey;
    if (target == 'explore' ||
        target == 'steal_tech' ||
        target == 'counter_spy') {
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
      final existing =
          _orders.workOrdersByPlayerId[_humanPlayerId] ?? const <WorkOrder>[];
      final list = <WorkOrder>[...existing, workOrder];
      _orders = _orders.copyWith(
        workOrdersByPlayerId: {
          ..._orders.workOrdersByPlayerId,
          _humanPlayerId: list,
        },
      );
      _workTargetSelection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseResult = getDebugInitGameResult();
    final mapViewData = _visibilityMode == CtMapVisibilityMode.playerConstrained
        ? debugMapViewDataWithVisibilityForFirstPlayer()
        : baseResult.mapViewData;
    final region = _regionIndex == 0
        ? mapViewData.oldWorld
        : mapViewData.newWorld;
    // Panel at bottom, like province overlay "With map" story. SPEC/ui/civilian-units-panel.md.
    const panelHeight = 220.0;
    return SizedBox(
      width: 900,
      height: 550,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                CtChoiceChip(
                  label: Text(appL10n(context).region_oldWorld),
                  selected: _regionIndex == 0,
                  onSelected: (_) => setState(() => _regionIndex = 0),
                ),
                CtChoiceChip(
                  label: Text(appL10n(context).region_newWorld),
                  selected: _regionIndex == 1,
                  onSelected: (_) => setState(() => _regionIndex = 1),
                ),
                CtChoiceChip(
                  label: Text(appL10n(context).mapDebug_fullVisibility),
                  selected: _visibilityMode == CtMapVisibilityMode.full,
                  onSelected: (_) => setState(
                    () => _visibilityMode = CtMapVisibilityMode.full,
                  ),
                ),
                CtChoiceChip(
                  label: Text(appL10n(context).mapDebug_playerConstrained),
                  selected:
                      _visibilityMode == CtMapVisibilityMode.playerConstrained,
                  onSelected: (_) => setState(
                    () =>
                        _visibilityMode = CtMapVisibilityMode.playerConstrained,
                  ),
                ),
                CtChoiceChip(
                  label: Text(
                    appL10n(context).map_displayOptions_showProvinceNames,
                  ),
                  selected: _showProvinceNames,
                  onSelected: (_) => setState(() => _showProvinceNames = true),
                ),
                CtChoiceChip(
                  label: Text(appL10n(context).mapDebug_hideProvinceNames),
                  selected: !_showProvinceNames,
                  onSelected: (_) => setState(() => _showProvinceNames = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: CtRegionMap(
              region: region,
              cellSizePx: 24,
              visibilityMode: _visibilityMode,
              playerViewForResources:
                  _visibilityMode == CtMapVisibilityMode.playerConstrained
                  ? debugPlayerViewForFirstPlayer()
                  : null,
              showProvinceNamesLayer: _showProvinceNames,
              onProvinceSelected: (_) {},
              secondaryHighlightTileKey: _secondaryHighlightTileKey,
              centerOnTileKey: _centerOnTileKey,
              validTileKeys: _validTileKeys,
              onTileSelected: _workTargetSelection != null
                  ? _onTileSelectedForWork
                  : null,
              onWorkTargetSelectionCancelled: _workTargetSelection != null
                  ? () => setState(() => _workTargetSelection = null)
                  : null,
            ),
          ),
          SizedBox(
            height: panelHeight,
            child: CivilianUnitsPanel(
              game: _game,
              humanPlayerId: _humanPlayerId,
              currentOrders: _orders,
              availableWorkTargets: const {},
              bus: _panelBus,
            ),
          ),
        ],
      ),
    );
  }
}

/// Civilian Units Panel opened as bottom sheet (slide up from bottom). SPEC/ui/civilian-units-panel.md.
class _CivilianPanelAsBottomSheetStory extends StatelessWidget {
  const _CivilianPanelAsBottomSheetStory();

  @override
  Widget build(BuildContext context) {
    final result = getDebugInitGameResult();
    final game = result.game;
    final humanPlayerId = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
    return SizedBox(
      width: 600,
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: CtNinePatchButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    final maxHeight = MediaQuery.sizeOf(ctx).height * 0.5;
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: CivilianUnitsPanel(
                        game: game,
                        humanPlayerId: humanPlayerId,
                        availableWorkTargets: const {},
                        bus: AppEventBus(),
                      ),
                    );
                  },
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(appL10n(context).civilian_units_title),
                ],
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: Color(0xFFE0E0E0),
              child: Center(
                child: Text(
                  appL10n(context).widgetbook_bottomSheetHint,
                  style: TextStyle(color: Color(0xFF616161)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Military Units Panel + map in tandem. SPEC/ui/military-units-panel.md.
class _MilitaryPanelWithMapStory extends StatefulWidget {
  const _MilitaryPanelWithMapStory();

  @override
  State<_MilitaryPanelWithMapStory> createState() =>
      _MilitaryPanelWithMapStoryState();
}

class _MilitaryPanelWithMapStoryState
    extends State<_MilitaryPanelWithMapStory> {
  int _regionIndex = 0;
  String? _secondaryHighlightTileKey;
  String? _centerOnTileKey;
  bool _showProvinceNames = true;

  @override
  Widget build(BuildContext context) {
    final result = getDebugInitGameResult();
    final game = result.game;
    final mapViewData = result.mapViewData;
    final humanPlayerId = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
    final region = _regionIndex == 0
        ? mapViewData.oldWorld
        : mapViewData.newWorld;
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
                        label: Text(appL10n(context).region_oldWorld),
                        selected: _regionIndex == 0,
                        onSelected: (_) => setState(() => _regionIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(appL10n(context).region_newWorld),
                        selected: _regionIndex == 1,
                        onSelected: (_) => setState(() => _regionIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          appL10n(context).map_displayOptions_showProvinceNames,
                        ),
                        selected: _showProvinceNames,
                        onSelected: (_) =>
                            setState(() => _showProvinceNames = true),
                      ),
                      ChoiceChip(
                        label: Text(appL10n(context).mapDebug_noNames),
                        selected: !_showProvinceNames,
                        onSelected: (_) =>
                            setState(() => _showProvinceNames = false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CtRegionMap(
                    region: region,
                    cellSizePx: 24,
                    showProvinceNamesLayer: _showProvinceNames,
                    onProvinceSelected: (_) {},
                    secondaryHighlightTileKey: _secondaryHighlightTileKey,
                    centerOnTileKey: _centerOnTileKey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 360,
            child: MilitaryUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: AppEventBus.create(),
              topology: result.combinedTopology,
              draftOrders: const Orders(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Train Military Dialog stories. SPEC/ui/train-military-dialog.md.
List<WidgetbookNode> get trainMilitaryDialogDirectories => [
  WidgetbookFolder(
    name: 'Train Military Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Standalone',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.firstWhere((p) => p.isHuman).id
              : game.players.first.id;
          final player = game.players.firstWhere((p) => p.id == humanPlayerId);
          final richGame = game.copyWith(
            players: [
              player.copyWith(
                treasury: 10000,
                workerPool: player.workerPool.copyWith(peasants: 20),
                stockpile: player.stockpile.merge(
                  const Stockpile(
                    quantities: {
                      'fabric': 50,
                      'castIron': 50,
                      'lumber': 50,
                      'horses': 50,
                      'steel': 50,
                      'bronze': 50,
                    },
                  ),
                ),
              ),
              ...game.players.where((p) => p.id != humanPlayerId),
            ],
          );
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: TrainMilitaryDialog(
                  game: richGame,
                  humanPlayerId: humanPlayerId,
                  currentOrders: const Orders(),
                  bus: AppEventBus.create(),
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
];

/// Naval Units Panel + map in tandem. SPEC/ui/naval-units-panel.md.
class _NavalPanelWithMapStory extends StatefulWidget {
  const _NavalPanelWithMapStory();

  @override
  State<_NavalPanelWithMapStory> createState() =>
      _NavalPanelWithMapStoryState();
}

class _NavalPanelWithMapStoryState extends State<_NavalPanelWithMapStory> {
  int _regionIndex = 0;
  String? _secondaryHighlightTileKey;
  String? _centerOnTileKey;
  bool _showProvinceNames = true;
  late Game _game;
  late MapTopology _combinedTopology;
  late AppEventBus _navalBus;
  StreamSubscription<NavalFleetsUpdatedEvent>? _navalSub;
  StreamSubscription<NavalSplitFleetRequestedEvent>? _navalSplitSub;

  @override
  void initState() {
    super.initState();
    final result = getDebugInitGameResult();
    _game = result.game;
    _combinedTopology = result.combinedTopology;
    _navalBus = AppEventBus.create();
    _navalSub = _navalBus.on<NavalFleetsUpdatedEvent>().listen((e) {
      if (!mounted) return;
      setState(() => _game = e.game);
    });
    _navalSplitSub = _navalBus.on<NavalSplitFleetRequestedEvent>().listen((e) {
      final next = applyNavalSplitFleet(
        game: _game,
        humanPlayerId: e.humanPlayerId,
        originalFleetId: e.originalFleetId,
        shipInstanceIdsToNewFleet: e.shipInstanceIdsToNewFleet,
      );
      _navalBus.emit(NavalFleetsUpdatedEvent(game: next));
    });
  }

  @override
  void dispose() {
    _navalSub?.cancel();
    _navalSplitSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = getDebugInitGameResult();
    final mapViewData = result.mapViewData;
    final humanPlayerId = _game.players.isNotEmpty
        ? _game.players.first.id
        : 'gp1';
    final region = _regionIndex == 0
        ? mapViewData.oldWorld
        : mapViewData.newWorld;
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
                        label: Text(appL10n(context).region_oldWorld),
                        selected: _regionIndex == 0,
                        onSelected: (_) => setState(() => _regionIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(appL10n(context).region_newWorld),
                        selected: _regionIndex == 1,
                        onSelected: (_) => setState(() => _regionIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          appL10n(context).map_displayOptions_showProvinceNames,
                        ),
                        selected: _showProvinceNames,
                        onSelected: (_) =>
                            setState(() => _showProvinceNames = true),
                      ),
                      ChoiceChip(
                        label: Text(appL10n(context).mapDebug_noNames),
                        selected: !_showProvinceNames,
                        onSelected: (_) =>
                            setState(() => _showProvinceNames = false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CtRegionMap(
                    region: region,
                    cellSizePx: 24,
                    showProvinceNamesLayer: _showProvinceNames,
                    onProvinceSelected: (_) {},
                    secondaryHighlightTileKey: _secondaryHighlightTileKey,
                    centerOnTileKey: _centerOnTileKey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 360,
            child: NavalUnitsPanel(
              game: _game,
              humanPlayerId: humanPlayerId,
              bus: _navalBus,
              topology: _combinedTopology,
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
  late String? _selectedTileKey;
  String? _secondaryHighlightTileKey;
  var _overlayOpen = true;
  CtMapVisibilityMode _visibilityMode = CtMapVisibilityMode.full;
  bool _showProvinceNames = true;

  String? _displayIdFromTile(String? tileKey) {
    if (tileKey == null) return null;
    final parts = tileKey.split('|');
    if (parts.length < 4) return null;
    return '${parts[0]}|${parts[1]}';
  }

  @override
  void initState() {
    super.initState();
    final mapViewData = debugMapViewDataWithVisibilityForFirstPlayer();
    final region = mapViewData.oldWorld;
    final game = getDebugInitGameResult().game;
    final tiles = game
        .worldState
        .tileKeysByRegionAndProvince[region.regionId]?[widget.selectedId];
    if (tiles != null && tiles.isNotEmpty) {
      _selectedTileKey = tiles.first;
    } else {
      final cell = region.cells.firstWhere(
        (c) => '${region.regionId}|${c.regionCellId}' == widget.selectedId,
      );
      _selectedTileKey =
          '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
    }
  }

  @override
  void didUpdateWidget(covariant _MapWithOverlayStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      final mapViewData = debugMapViewDataWithVisibilityForFirstPlayer();
      final region = mapViewData.oldWorld;
      final game = getDebugInitGameResult().game;
      final tiles = game
          .worldState
          .tileKeysByRegionAndProvince[region.regionId]?[widget.selectedId];
      if (tiles != null && tiles.isNotEmpty) {
        _selectedTileKey = tiles.first;
      } else {
        final cell = region.cells.firstWhere(
          (c) => '${region.regionId}|${c.regionCellId}' == widget.selectedId,
        );
        _selectedTileKey =
            '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
      }
      _overlayOpen = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initResult = getDebugInitGameResult();
    final game = initResult.game;
    final playerView = buildPlayerView(
      game,
      initResult.combinedTopology,
      'gp1',
    );
    final mapViewData = debugMapViewDataWithVisibilityForFirstPlayer();
    final region = mapViewData.oldWorld;
    final displayId = _displayIdFromTile(_selectedTileKey) ?? widget.selectedId;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight > 0
            ? constraints.maxHeight
            : 500.0;
        final overlayHeight = totalHeight / 2;
        return SizedBox(
          width: 800,
          height: totalHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChoiceChip(
                      label: Text(appL10n(context).mapDebug_fullVisibility),
                      selected: _visibilityMode == CtMapVisibilityMode.full,
                      onSelected: (_) {
                        setState(() {
                          _visibilityMode = CtMapVisibilityMode.full;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(appL10n(context).mapDebug_playerConstrained),
                      selected:
                          _visibilityMode ==
                          CtMapVisibilityMode.playerConstrained,
                      onSelected: (_) {
                        setState(() {
                          _visibilityMode =
                              CtMapVisibilityMode.playerConstrained;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        appL10n(context).map_displayOptions_showProvinceNames,
                      ),
                      selected: _showProvinceNames,
                      onSelected: (_) =>
                          setState(() => _showProvinceNames = true),
                    ),
                    ChoiceChip(
                      label: Text(appL10n(context).mapDebug_noNames),
                      selected: !_showProvinceNames,
                      onSelected: (_) =>
                          setState(() => _showProvinceNames = false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CtRegionMap(
                        region: region,
                        cellSizePx: 28,
                        visibilityMode: _visibilityMode,
                        playerViewForResources:
                            _visibilityMode ==
                                CtMapVisibilityMode.playerConstrained
                            ? playerView
                            : null,
                        showProvinceNamesLayer: _showProvinceNames,
                        onProvinceSelected: null,
                        onMapTileTappedForDetail: (tk) => setState(() {
                          _selectedTileKey = tk;
                          _overlayOpen = true;
                        }),
                        selectedTileKey: _selectedTileKey,
                        secondaryHighlightTileKey: _secondaryHighlightTileKey,
                      ),
                    ),
                    if (_overlayOpen && _selectedTileKey != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: overlayHeight,
                          width: double.infinity,
                          child: ProvinceSeaZoneDetailOverlay(
                            game: game,
                            region: region,
                            displayId: displayId,
                            selectedTileKey: _selectedTileKey,
                            humanPlayerId: 'gp1',
                            playerView: playerView,
                            onHighlightTile: (k) =>
                                setState(() => _secondaryHighlightTileKey = k),
                            onClose: () => setState(() {
                              _overlayOpen = false;
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
