// coverage:ignore-file
// Dev-only Widgetbook catalog; excluded from app coverage gate via instrumentation.
import 'dart:async';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import '../config/themes.dart';
import '../providers/app_event_bus_provider.dart';
import '../providers/games_provider.dart';
import '../providers/map_view_provider.dart';
import '../features/game/combat/combat_mode_choice_dialog.dart';
import '../features/game/combat/quick_battle_action_selector.dart';
import '../features/game/combat/quick_battle_deployment_view.dart';
import '../features/game/combat/quick_battle_result_dialog.dart';
import '../features/game/combat/quick_battle_screen.dart';
import '../features/game/widgets/civilian_units_panel.dart';
import '../features/game/widgets/diplomacy_dialogs.dart';
import '../features/game/widgets/diplomacy_panel.dart';
import '../features/game/widgets/military_units_panel.dart';
import '../features/game/widgets/naval_units_panel.dart';
import '../features/game/widgets/production_commodity_breakdown_dialog.dart';
import '../features/game/widgets/production_panel.dart';
import '../features/game/widgets/production_panel_demo_data.dart';
import '../features/game/widgets/province_sea_zone_detail_overlay.dart';
import '../features/game/widgets/province_overlay_demo_data.dart';
import '../features/game/widgets/tech_tree_widget.dart';
import '../features/game/screens/technology_screen.dart';
import '../features/game/dialogue/intervention_dialogue_overlay.dart';
import '../features/game/flame/game_screen.dart';
import '../features/game/flame/victory_overlay.dart';
import '../features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import '../features/game/widgets/move_army_dialog.dart';
import '../features/game/widgets/move_fleet_dialog.dart';
import '../features/game/widgets/train_civilians_dialog.dart';
import '../features/game/widgets/train_military_dialog.dart';
import '../features/game/widgets/transfer_to_home_fleet_dialog.dart';
import '../features/game/widgets/turn_news_dialog.dart';
import '../features/shell/new_game_leader_selection_dialog.dart';
import '../features/shell/shell_screen.dart';
import '../l10n/l10n.dart';
import '../widgets/debug_init_game.dart';
import '../widgets/ct_choice_chip.dart';
import 'debug_map_visibility_story.dart';
import '../widgets/game_setup.dart';
import '../widgets/main_menu.dart';
import '../widgets/ct_nine_patch_button.dart';
import '../widgets/ct_region_map.dart';
import '../widgets/ct_transfer_list.dart';

part 'catalog_part1.dart';
part 'catalog_part2.dart';
part 'catalog_part3.dart';
part 'catalog_part4.dart';

Unit? _unitByIdForCatalog(Game game, String unitId) {
  for (final u in game.worldState.oldWorld.units) {
    if (u.id == unitId) return u;
  }
  for (final u in game.worldState.newWorld.units) {
    if (u.id == unitId) return u;
  }
  return null;
}

/// Widgetbook: [CivilianUnitsPanel] reads [availableWorkTargetIdsForUnitProvider].
Widget civilianUnitsPanelWithRiverpod({
  required Game game,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      availableWorkTargetIdsForUnitProvider.overrideWith((ref, unitId) {
        final t = _unitByIdForCatalog(game, unitId)?.type;
        return workOrderTargetsByUnitType[t] ?? const <String>[];
      }),
    ],
    child: child,
  );
}

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
        ...turnNewsDialogDirectories,
        ...victoryUiDirectories,
        ...combatUiDirectories,
        ...moveArmyDialogDirectories,
        ...moveFleetDialogDirectories,
        ...transferToHomeFleetDialogDirectories,
        ...productionCommodityBreakdownDialogDirectories,
        ...grantOrSubsidyDialogDirectories,
        ...newGameLeaderSelectionDialogDirectories,
        ...shellScreenDirectories,
        ...gameScreenDirectories,
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
                onConfirm: (_, _) {},
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
          return civilianUnitsPanelWithRiverpod(
            game: game,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
              child: CivilianUnitsPanel(
                game: game,
                humanPlayerId: humanPlayerId,
                bus: AppEventBus(),
              ),
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
          final player = game.playerById(humanPlayerId) ?? game.players.first;
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
          final player = game.playerById(humanPlayerId) ?? game.players.first;
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
          final player = game.playerById(humanPlayerId) ?? game.players.first;
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
