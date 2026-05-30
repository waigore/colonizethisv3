// coverage:ignore-file
// Dev-only Widgetbook catalog; excluded from app coverage gate via instrumentation.
import 'dart:async';
import 'dart:convert';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jenny/jenny.dart';
import 'package:widgetbook/widgetbook.dart';

import '../config/editorial_monocle_palette.dart';
import '../config/themes.dart';
import '../providers/app_event_bus_provider.dart';
import '../providers/games_provider.dart';
import '../providers/map_province_panel_provider.dart';
import '../providers/map_view_provider.dart';
import '../features/game/combat/combat_mode_choice_dialog.dart';
import '../features/game/combat/quick_battle_action_selector.dart';
import '../features/game/combat/quick_battle_deployment_view.dart';
import '../features/game/combat/quick_battle_result_dialog.dart';
import '../features/game/combat/quick_battle_screen.dart';
import '../features/game/widgets/civilian_units_panel.dart';
import '../features/game/widgets/diplomacy_dialogs.dart';
import '../features/game/widgets/diplomacy_panel.dart';
import '../features/game/widgets/game_map_options_dialog.dart';
import '../features/game/widgets/game_map_players_bar.dart';
import '../features/game/widgets/game_tab_bar.dart';
import '../features/game/widgets/game_top_bar.dart';
import '../features/game/widgets/military_units_panel.dart';
import '../features/game/widgets/naval_units_panel.dart';
import '../features/game/widgets/pause_menu_panel.dart';
import '../features/game/widgets/player_turn_event_feed.dart';
import '../features/game/widgets/production_commodity_breakdown_dialog.dart';
import '../features/game/widgets/production_panel.dart';
import '../features/game/widgets/production_panel_demo_data.dart';
import '../features/game/widgets/province_sea_zone_detail_overlay.dart';
import '../features/game/widgets/province_overlay_demo_data.dart';
import '../features/game/widgets/tech_tree_widget.dart';
import '../features/game/screens/diplomacy_detail_screen.dart';
import '../features/game/screens/technology_screen.dart';
import '../features/game/flame/game_map_narrow_detail_overlay.dart';
import '../features/game/dialogue/call_to_arms_dialogue_overlay.dart';
import '../features/game/dialogue/ct_dialogue_view.dart';
import '../features/game/dialogue/game_start_intro_overlay.dart';
import '../features/game/dialogue/intervention_dialogue_overlay.dart';
import '../features/game/dialogue/overture_dialogue_overlay.dart';
import '../features/game/flame/game_map_corner_controls.dart';
import '../features/game/flame/game_screen.dart';
import '../features/game/flame/game_side_menu.dart';
import '../features/game/flame/exit_confirm_dialog.dart';
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
import '../widgets/ct_back_button.dart';
import '../widgets/ct_brass_divider.dart';
import '../widgets/ct_choice_chip.dart';
import '../widgets/ct_compass_rose.dart';
import '../widgets/ct_dialog_shell.dart';
import '../widgets/ct_dropdown.dart';
import '../widgets/ct_fleur_de_lis_ornament.dart';
import '../widgets/ct_gradients.dart';
import '../widgets/ct_loading_indicator.dart';
import '../widgets/ct_main_menu_collage.dart';
import '../widgets/ct_panel.dart';
import '../widgets/ct_progress_bar.dart';
import '../widgets/ct_resource_cell.dart';
import '../widgets/ct_screen_shell.dart';
import '../widgets/ct_section_label.dart';
import '../widgets/ct_slider.dart';
import '../widgets/ct_toggle_switch.dart';
import '../widgets/ct_top_bar.dart';
import '../widgets/resource_icon.dart';
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
part 'catalog_part5.dart';
part 'catalog_part6.dart';
part 'catalog_part7.dart';

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

/// Host for Widgetbook use cases that need a nested [MaterialApp]. Without an
/// explicit [ThemeData], nested apps default to Material light and break dark
/// editorial-monocle review for unit panels and train dialogs (Refs #2866 S6).
Widget widgetbookEditorialMonocleApp({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
      body: child,
    ),
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

/// Widgetbook app: defaults to `AppThemes.editorialMonocle` (dark) per
/// `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette; the
/// MaterialThemeAddon below exposes a toolbar toggle between the
/// editorial-monocle theme and the colonial / colonialPixelArt light
/// fallbacks. SPEC/ui/main-menu.md; UXD 03a. SPEC/ui/game-setup.md; UXD 03b.
/// Mobile viewport: SPEC/ui/mobile-adaptation.md.
class CtWidgetbookApp extends StatelessWidget {
  const CtWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: _ctWidgetbookDirectories,
      addons: _ctWidgetbookAddons,
      lightTheme: AppThemes.editorialMonocle,
      darkTheme: AppThemes.editorialMonocle,
    );
  }
}

/// Aggregate Widgetbook directories shown in the chrome — split out of
/// `CtWidgetbookApp.build` to keep the build body under the
/// `widget_build_method_too_long` budget (`SPEC/program/repo-lint.md`).
List<WidgetbookNode> get _ctWidgetbookDirectories => [
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
  ...ctDialogueViewDirectories,
  ...gameStartIntroOverlayDirectories,
  ...overtureDialogueOverlayDirectories,
  ...callToArmsDialogueOverlayDirectories,
  ...turnNewsDialogDirectories,
  ...victoryUiDirectories,
  ...playersBarDirectories,
  ...exitConfirmDialogDirectories,
  ...combatUiDirectories,
  ...moveArmyDialogDirectories,
  ...moveFleetDialogDirectories,
  ...transferToHomeFleetDialogDirectories,
  ...productionCommodityBreakdownDialogDirectories,
  ...grantOrSubsidyDialogDirectories,
  ...newGameLeaderSelectionDialogDirectories,
  ...shellScreenDirectories,
  ...gameScreenDirectories,
  ...gameTopBarDirectories,
  ...gameTabBarDirectories,
  ...gameMapCornerControlsDirectories,
  ...gameMapOptionsDialogDirectories,
  ...playerTurnEventFeedCardDirectories,
  ...pauseMenuPanelDirectories,
  ...gameSideMenuDirectories,
  ...gameMapNarrowDetailOverlaySlotDirectories,
  ...diplomacyDetailScreenDirectories,
  ...ctDarkThemePrimitiveDirectories,
];

/// Toolbar addons for the Widgetbook chrome — exposes the editorial-monocle
/// dark default with light-fallback toggles per
/// `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette.
List<WidgetbookAddon<dynamic>> get _ctWidgetbookAddons => [
  MaterialThemeAddon(
    themes: [
      WidgetbookTheme(
        name: 'Editorial Monocle (dark)',
        data: AppThemes.editorialMonocle,
      ),
      WidgetbookTheme(
        name: 'Colonial (light fallback)',
        data: AppThemes.colonial,
      ),
      WidgetbookTheme(
        name: 'Colonial Pixel Art (light fallback)',
        data: AppThemes.colonialPixelArt,
      ),
    ],
    initialTheme: WidgetbookTheme(
      name: 'Editorial Monocle (dark)',
      data: AppThemes.editorialMonocle,
    ),
  ),
];

/// Nine-patch button stories. SPEC/ui/buttons-nine-patch.md; catalog: CtNinePatchButton.
///
/// Refs #2859 R1 / S2 — gradient surface, brass corner brackets, engraved
/// label text, hover/disabled states.
List<WidgetbookNode> get buttonDirectories => [
  WidgetbookFolder(
    name: 'Buttons',
    children: [
      WidgetbookUseCase(
        name: 'CtNinePatchButton',
        builder: (context) => Theme(
          data: AppThemes.editorialMonocle,
          child: ColoredBox(
            color: EditorialMonoclePalette.bg,
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
          data: AppThemes.editorialMonocle,
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
      WidgetbookUseCase(
        // SPEC/ui/main-menu.md § Responsive rules — exercises the
        // `≤ 430 dp` narrow override (compact padding + reduced button
        // letter-spacing) against the `pixelArt` variant on a 360 dp
        // viewport.
        name: 'Pixel art (mobile)',
        builder: (context) => mobileViewport(
          context,
          CtMainMenu(
            variant: MainMenuVariant.pixelArt,
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

/// Six distinct GP ids drawn from [defaultNamingConfig] — the same default
/// six powers used by `GameSetupConfig.defaultConfig`. Powers the
/// "All slots selected (pixel)" Widgetbook story below so reviewers can
/// see the happy-path swatch row + Start Game enabled state without
/// having to manually fill every slot (SPEC/ui/game-setup.md § Slot-row
/// chrome and swatch dots; R9).
List<String> _allSelectedInitialOrderedGpIds() =>
    defaultNamingConfig.greatPowers.map((g) => g.id).take(6).toList();

/// Default leader variant per gp id for [_allSelectedInitialOrderedGpIds].
Map<String, String> _allSelectedInitialLeaderVariantByGpId() {
  final Map<String, String> map = <String, String>{};
  for (final String id in _allSelectedInitialOrderedGpIds()) {
    final gp = defaultNamingConfig.gpById(id);
    if (gp != null && gp.leaderVariants.isNotEmpty) {
      map[id] = gp.defaultLeaderVariantId;
    }
  }
  return map;
}

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
      WidgetbookUseCase(
        name: 'Default (mobile, pixel)',
        builder: (context) => mobileViewport(
          context,
          CtGameSetup(
            variant: GameSetupVariant.pixelArt,
            state: GameSetupState.default_,
            naming: defaultNamingConfig,
            initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
            initialLeaderVariantByGpId: const {},
            onStartGame: (_, _) {},
            onBack: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Loading (mobile, pixel)',
        builder: (context) => mobileViewport(
          context,
          CtGameSetup(
            variant: GameSetupVariant.pixelArt,
            state: GameSetupState.loading,
            naming: defaultNamingConfig,
            initialOrderedGpIds: _unselectedInitialOrderedGpIds(),
            initialLeaderVariantByGpId: const {},
            onStartGame: (_, _) {},
            onBack: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'All slots selected (pixel)',
        builder: (context) => CtGameSetup(
          variant: GameSetupVariant.pixelArt,
          state: GameSetupState.default_,
          naming: defaultNamingConfig,
          initialOrderedGpIds: _allSelectedInitialOrderedGpIds(),
          initialLeaderVariantByGpId: _allSelectedInitialLeaderVariantByGpId(),
          onStartGame: (_, _) {},
          onBack: () {},
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
          return widgetbookEditorialMonocleApp(
            child: Center(
              child: TrainCiviliansDialog(
                game: richGame,
                humanPlayerId: humanPlayerId,
                currentOrders: const Orders(),
                bus: AppEventBus.create(),
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
          return widgetbookEditorialMonocleApp(
            child: Center(
              child: TrainCiviliansDialog(
                game: noTechGame,
                humanPlayerId: humanPlayerId,
                currentOrders: const Orders(),
                bus: AppEventBus.create(),
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
          return widgetbookEditorialMonocleApp(
            child: Center(
              child: TrainCiviliansDialog(
                game: poorGame,
                humanPlayerId: humanPlayerId,
                currentOrders: const Orders(),
                bus: AppEventBus.create(),
              ),
            ),
          );
        },
      ),
    ],
  ),
];
