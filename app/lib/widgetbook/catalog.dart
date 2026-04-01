// coverage:ignore-file
// Dev-only Widgetbook catalog; excluded from app coverage gate via instrumentation.
import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import '../config/themes.dart';
import '../features/game/widgets/civilian_units_panel.dart';
import '../features/game/widgets/diplomacy_panel.dart';
import '../features/game/widgets/military_units_panel.dart';
import '../features/game/logic/naval_fleet_split_apply.dart';
import '../features/game/widgets/naval_units_panel.dart';
import '../features/game/widgets/production_panel.dart';
import '../features/game/widgets/production_panel_demo_data.dart';
import '../features/game/widgets/province_sea_zone_detail_overlay.dart';
import '../features/game/widgets/province_overlay_demo_data.dart';
import '../features/game/widgets/tech_tree_widget.dart';
import '../features/game/widgets/technology_screen.dart';
import '../features/game/dialogue/intervention_dialogue_overlay.dart';
import '../features/game/widgets/train_civilians_dialog.dart';
import '../features/game/widgets/train_military_dialog.dart';
import '../widgets/debug_init_game.dart';
import '../widgets/ct_choice_chip.dart';
import '../widgets/debug_map_visibility_story.dart';
import '../widgets/game_setup.dart';
import '../widgets/main_menu.dart';
import '../widgets/ct_nine_patch_button.dart';
import '../widgets/ct_region_map.dart';
import '../widgets/ct_transfer_list.dart';

/// Invoked from `lib/widgetbook.dart` [main]; safe to call from tests after binding init.
void bootstrapWidgetbook() {
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
        ...transferListDirectories,
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
        ...interventionDialogueDirectories,
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
                  child: const Text('Primary action'),
                ),
                const SizedBox(height: 12),
                CtNinePatchButton(
                  onPressed: null,
                  enabled: false,
                  child: const Text('Disabled'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: CtNinePatchButton(
                    onPressed: () {},
                    child: const Text('Fixed width'),
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

/// Transfer list stories for reusable quantity transfer behavior.
List<WidgetbookNode> get transferListDirectories => [
  WidgetbookFolder(
    name: 'Transfer List',
    children: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (context) => Theme(
          data: AppThemes.colonial,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 560,
              child: CtTransferList(
                leftTitle: 'Original Fleet',
                rightTitle: 'New Fleet',
                leftSubtitle: 'Old World - Lisbon',
                rightSubtitle: 'Old World - Lisbon',
                initialLeftCounts: const {'carrack': 2, 'fluyte': 1},
                leftEmptyLabel: 'No ships',
                rightEmptyLabel: 'No ships',
                totalLabelBuilder: (total) => 'Total: $total ships',
                confirmLabel: 'Confirm Split',
                canConfirm: (left, right) {
                  final leftTotal = left.values.fold(
                    0,
                    (sum, count) => sum + count,
                  );
                  final rightTotal = right.values.fold(
                    0,
                    (sum, count) => sum + count,
                  );
                  return leftTotal >= 1 && rightTotal > 0;
                },
                onCancel: () {},
                onConfirm: (_, __) {},
              ),
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
              onOrdersChanged: (_) {},
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
            return const Center(child: Text('No players'));
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
            return const Center(child: Text('No players'));
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
              appBar: AppBar(title: const Text('Tech Tree')),
              body: TechTreeWidget(game: midGame, player: midGamePlayer),
            ),
          );
        },
      ),
    ],
  ),
];

/// Intervention blocking dialogue. SPEC/ui/screens/pending-intervention-overlay.md.
List<WidgetbookNode> get interventionDialogueDirectories => [
  WidgetbookFolder(
    name: 'Dialogue',
    children: [
      WidgetbookUseCase(
        name: 'InterventionDialogueOverlay',
        builder: (context) {
          final game = Game(
            id: 'wb_iv',
            worldState: const WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: const [
              Player(
                id: 'spain',
                displayName: 'Spain',
                isHuman: false,
                treasury: 0,
              ),
              Player(
                id: 'portugal',
                displayName: 'Portugal',
                isHuman: true,
                treasury: 0,
              ),
            ],
            minorNations: const [
              MinorNation(id: 'minorca', displayName: 'Minorca'),
            ],
          );
          return MaterialApp(
            theme: AppThemes.colonial,
            home: Scaffold(
              body: InterventionDialogueOverlay(
                game: game,
                prompts: const [
                  InterventionPrompt(
                    aggressorGpId: 'spain',
                    defenderMinorOrTribeId: 'minorca',
                    interveningGpId: 'portugal',
                  ),
                ],
                skipIntroForTest: true,
                onDecisions: (_) {},
                child: const Center(child: Text('Game shell')),
              ),
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
    final player =
        widget.playerOverride ??
        (widget.useFullAvailability
            ? fullAvailabilityProductionPlayer()
            : partialAvailabilityProductionPlayer());
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
      child: ProductionPanel(
        game: game,
        player: player,
        desiredOutputByRecipe: _desiredOutputByRecipe,
        netDeltasByCommodity: const {},
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

  void _onLocateUnit(Unit unit) {
    final tileKey = unit.tileKey;
    if (tileKey == null) return;
    final regionId = Unit.regionIdFromTileKey(tileKey);
    setState(() {
      _secondaryHighlightTileKey = tileKey;
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
                  label: const Text('Old World'),
                  selected: _regionIndex == 0,
                  onSelected: (_) => setState(() => _regionIndex = 0),
                ),
                CtChoiceChip(
                  label: const Text('New World'),
                  selected: _regionIndex == 1,
                  onSelected: (_) => setState(() => _regionIndex = 1),
                ),
                CtChoiceChip(
                  label: const Text('Full visibility'),
                  selected: _visibilityMode == CtMapVisibilityMode.full,
                  onSelected: (_) => setState(
                    () => _visibilityMode = CtMapVisibilityMode.full,
                  ),
                ),
                CtChoiceChip(
                  label: const Text('Player-constrained'),
                  selected:
                      _visibilityMode == CtMapVisibilityMode.playerConstrained,
                  onSelected: (_) => setState(
                    () =>
                        _visibilityMode = CtMapVisibilityMode.playerConstrained,
                  ),
                ),
                CtChoiceChip(
                  label: const Text('Province names'),
                  selected: _showProvinceNames,
                  onSelected: (_) => setState(() => _showProvinceNames = true),
                ),
                CtChoiceChip(
                  label: const Text('No province names'),
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Civilian Units'),
                ],
              ),
            ),
          ),
          const Expanded(
            child: ColoredBox(
              color: Color(0xFFE0E0E0),
              child: Center(
                child: Text(
                  'Tap button to open panel from bottom',
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

  void _onLocateTile(String tileKey, String regionId) {
    setState(() {
      _secondaryHighlightTileKey = tileKey;
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
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Province names'),
                        selected: _showProvinceNames,
                        onSelected: (_) =>
                            setState(() => _showProvinceNames = true),
                      ),
                      ChoiceChip(
                        label: const Text('No names'),
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

  void _onLocateFleet(String tileKey, String regionId) {
    setState(() {
      _secondaryHighlightTileKey = tileKey;
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
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Province names'),
                        selected: _showProvinceNames,
                        onSelected: (_) =>
                            setState(() => _showProvinceNames = true),
                      ),
                      ChoiceChip(
                        label: const Text('No names'),
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
                      label: const Text('Province names'),
                      selected: _showProvinceNames,
                      onSelected: (_) =>
                          setState(() => _showProvinceNames = true),
                    ),
                    ChoiceChip(
                      label: const Text('No names'),
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
