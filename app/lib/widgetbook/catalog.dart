// coverage:ignore-file
// Dev-only Widgetbook catalog; excluded from app coverage gate via instrumentation.
import 'dart:async';
import 'dart:convert';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart' show GameSaveAdapter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart' show Box;
import 'package:jenny/jenny.dart';
import 'package:widgetbook/widgetbook.dart';

import '../config/editorial_monocle_palette.dart';
import '../config/themes.dart';
import '../core/services/game_service.dart' show GameMapData, GameService;
import '../providers/app_event_bus_provider.dart';
import '../providers/debug_console_provider.dart';
import '../providers/game_service_provider.dart';
import '../providers/games_provider.dart';
import '../providers/map_province_panel_provider.dart';
import '../providers/map_view_provider.dart';
import '../providers/production_allocation_provider.dart';
import '../providers/region_minimap_provider.dart';
import '../features/game/combat/combat_mode_choice_dialog.dart';
import '../features/game/combat/quick_battle_action_selector.dart';
import '../features/game/combat/quick_battle_deployment_view.dart';
import '../features/game/combat/quick_battle_result_dialog.dart';
import '../features/game/combat/quick_battle_screen.dart';
import '../features/game/widgets/chrome/ct_action_text_button.dart';
import '../features/game/widgets/civilian_units_panel.dart';
import '../features/game/widgets/diplomacy_dialogs.dart';
import '../features/game/widgets/diplomacy_panel.dart';
import '../features/game/widgets/game_map_options_dialog.dart';
import '../features/game/widgets/game_map_players_bar.dart';
import '../features/game/widgets/game_tab_bar.dart';
import '../features/game/widgets/game_top_bar.dart';
import '../features/game/widgets/military_units_panel.dart';
import '../features/game/widgets/naval_units_panel.dart';
import '../features/game/widgets/units/shared/units_panel_viewport_constraints.dart';
import '../features/game/widgets/pause_menu_panel.dart';
import '../features/game/widgets/player_turn_event_feed.dart';
import '../features/game/widgets/production_commodity_breakdown_dialog.dart';
import '../features/game/widgets/production_labour_helpers.dart';
import '../features/game/widgets/production_panel.dart';
import '../features/game/widgets/production_panel_demo_data.dart';
import '../features/game/widgets/province_sea_zone_detail_overlay.dart';
import '../features/game/widgets/province_overlay_demo_data.dart';
import '../features/game/widgets/tech_tree_widget.dart';
import '../features/game/widgets/technology_panel.dart';
import '../features/game/screens/diplomacy_detail_screen.dart';
import '../features/game/screens/technology_screen.dart';
import '../features/game/screens/trade_screen.dart';
import '../features/game/flame/game_map_narrow_detail_overlay.dart';
import '../features/game/flame/next_turn_confirmation_dialog.dart';
import '../features/game/dialogue/call_to_arms_dialogue_overlay.dart';
import '../features/game/dialogue/ct_dialogue_view.dart';
import '../features/game/dialogue/game_start_intro_overlay.dart';
import '../features/game/dialogue/intervention_dialogue_overlay.dart';
import '../features/game/dialogue/overture_dialogue_overlay.dart';
import '../features/game/flame/game_map_province_detail_side_panel.dart';
import '../features/game/flame/per_player_work_target_selection_cache.dart';
import '../features/game/flame/game_map_corner_controls.dart';
import '../features/game/flame/game_map_empire_left_rail.dart';
import '../features/game/flame/game_region_minimap.dart';
import '../features/game/flame/game_screen.dart';
import '../features/game/flame/game_side_menu.dart';
import '../features/game/flame/exit_confirm_dialog.dart';
import '../features/game/flame/region_map_viewport_snapshot.dart';
import '../features/game/flame/victory_overlay.dart';
import '../features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import '../features/game/widgets/move_army_dialog.dart';
import '../features/game/widgets/move_fleet_dialog.dart';
import '../features/game/widgets/train_civilians_dialog.dart';
import '../features/game/widgets/train_military_dialog.dart';
import '../features/game/widgets/train_naval_dialog.dart';
import '../features/game/widgets/transfer_to_home_fleet_dialog.dart';
import '../features/game/widgets/turn_news_dialog.dart';
import '../features/shell/new_game_leader_selection_dialog.dart';
import '../features/shell/new_game_setup_flow.dart';
import '../features/shell/shell_screen.dart';
import '../l10n/l10n.dart';
import '../widgets/debug_init_game.dart';
import '../widgets/ct_back_button.dart';
import '../widgets/ct_icon_action.dart';
import '../widgets/ct_brass_divider.dart';
import '../widgets/ct_choice_chip.dart';
import '../widgets/ct_compass_rose.dart';
import '../widgets/ct_dark_scaffold.dart';
import '../widgets/ct_dialog_shell.dart';
import '../widgets/ct_dropdown.dart';
import '../widgets/ct_fleur_de_lis_ornament.dart';
import '../widgets/ct_full_screen_dialogue_shell.dart';
import '../widgets/ct_spacing.dart';
import '../widgets/ct_gradients.dart';
import '../widgets/ct_loading_indicator.dart';
import '../widgets/ct_main_menu_collage.dart';
import '../widgets/ct_panel.dart';
import '../widgets/ct_panel_with_top_bar.dart';
import '../widgets/ct_progress_bar.dart';
import '../widgets/ct_resource_cell.dart';
import '../widgets/ct_screen_shell.dart';
import '../widgets/ct_section_label.dart';
import '../widgets/ct_slider.dart';
import '../widgets/ct_toggle_switch.dart';
import '../widgets/ct_top_bar.dart';
import '../widgets/relation_meter.dart';
import '../widgets/resource_icon.dart';
import 'debug_map_visibility_story.dart';
import '../widgets/main_menu.dart';
import '../widgets/ct_nine_patch_button.dart';
import '../widgets/ct_region_map.dart';
import '../widgets/ct_transfer_list.dart';

// Widgetbook catalog parts grouped by UI domain (Refs #3546 item 6). Files are
// named by the surface family they register (panels, screens, dialogs, chrome,
// primitives, …) rather than by an arbitrary size-based `catalog_partN` index.
// Each part stays under the `repo.part_unit_size` line cap, so a single domain
// that exceeds the cap is split into clearly-named sibling parts rather than a
// numbered fragment. The `repo.app_widgetbook_file_naming` gate enforces the
// no-`catalog_partN` convention.
part 'catalog_panel_map_stories.dart';
part 'catalog_panels.dart';
part 'catalog_diplomacy_panel.dart';
part 'catalog_diplomacy_detail.dart';
part 'catalog_screens_combat.dart';
part 'catalog_dialogs.dart';
part 'catalog_primitives.dart';
part 'catalog_data_screens.dart';
part 'catalog_game_chrome.dart';
part 'catalog_shell_chrome.dart';
part 'catalog_event_feed.dart';

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
/// fallbacks. SPEC/ui/main-menu.md; UXD 03a.
/// New game leader selection: SPEC/ui/new-game-leader-selection-dialog.md.
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
  ...mapWidgetDirectories,
  ...provinceOverlayDirectories,
  ...productionPanelDirectories,
  ...civilianUnitsPanelDirectories,
  ...trainCiviliansDialogDirectories,
  ...trainMilitaryDialogDirectories,
  ...trainNavalDialogDirectories,
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
  ...gameMapEmpireLeftRailDirectories,
  ...gameMapOptionsDialogDirectories,
  ...gameRegionMinimapDirectories,
  ...gameMapProvinceDetailSidePanelDirectories,
  ...playerTurnEventFeedCardDirectories,
  ...pauseMenuPanelDirectories,
  ...nextTurnConfirmationDialogDirectories,
  ...gameInitializingDirectories,
  ...gameSideMenuDirectories,
  ...gameMapNarrowDetailOverlaySlotDirectories,
  ...diplomacyDetailScreenDirectories,
  ...tradeScreenDirectories,
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
      // CtActionTextButton — neutral secondary pill (mockup `.action-btn`)
      // and the issue #3514 primary header-pill variant (`.train-btn`
      // family). SPEC/ui/pixel-art-ui-catalog.md § CtActionTextButton.
      WidgetbookUseCase(
        name: 'CtActionTextButton',
        builder: (context) => Theme(
          data: AppThemes.editorialMonocle,
          child: ColoredBox(
            color: EditorialMonoclePalette.bg,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CtActionTextButton(onPressed: () {}, label: 'Breakdown'),
                  const SizedBox(width: 12),
                  CtActionTextButton(
                    primary: true,
                    onPressed: () {},
                    label: 'Train',
                  ),
                  const SizedBox(width: 12),
                  const CtActionTextButton(
                    primary: true,
                    onPressed: null,
                    enabled: false,
                    label: 'Tile',
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
        // SPEC/ui/main-menu.md § Variant rendering — exercises the
        // disabled Load Game tooltip in the `pixelArt` variant for
        // issue #2860 S6 (Widgetbook coverage of all four states under
        // editorial-monocle).
        name: 'No saves (pixel)',
        builder: (context) => CtMainMenu(
          variant: MainMenuVariant.pixelArt,
          state: MainMenuState.noSaves,
          version: 'v1.0.0',
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      ),
      WidgetbookUseCase(
        // SPEC/ui/main-menu.md § Widget contract — exercises the
        // `resumeGameVisible: true` branch in the `pixelArt` variant so
        // Widgetbook covers all four states across both variants per
        // issue #2860 S6.
        name: 'Resume game visible (pixel)',
        builder: (context) => CtMainMenu(
          variant: MainMenuVariant.pixelArt,
          state: MainMenuState.default_,
          version: 'v1.0.0',
          resumeGameVisible: true,
          onResumeGame: () {},
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
        builder: (context) => const CivilianPanelWithMapStory(),
      ),
      WidgetbookUseCase(
        name: 'As bottom sheet',
        builder: (context) => const CivilianPanelAsBottomSheetStory(),
      ),
      WidgetbookUseCase(
        // Narrow sizing contract (Refs #3627 AC6): full viewport width ×
        // 50% height cap from `unitsPanelSheetConstraints` at 360 × 640 dp.
        name: 'Mobile (360x640)',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.first.id
              : 'gp1';
          return civilianUnitsPanelWithRiverpod(
            game: game,
            child: mobileViewport(
              context,
              ConstrainedBox(
                constraints: unitsPanelSheetConstraints(const Size(360, 640)),
                child: CivilianUnitsPanel(
                  game: game,
                  humanPlayerId: humanPlayerId,
                  bus: AppEventBus(),
                ),
              ),
            ),
          );
        },
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
              ? game.players
                    .firstWhere(
                      (p) => p.isHuman,
                      orElse: () => game.players.first,
                    )
                    .id
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
              ? game.players
                    .firstWhere(
                      (p) => p.isHuman,
                      orElse: () => game.players.first,
                    )
                    .id
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
              ? game.players
                    .firstWhere(
                      (p) => p.isHuman,
                      orElse: () => game.players.first,
                    )
                    .id
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
