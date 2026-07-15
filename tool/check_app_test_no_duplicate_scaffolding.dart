import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// PR-blocking dedup gate for the `app` min-viewport test scaffolding (#3730).
///
/// The 25 `app/test/*_320dp_min_viewport_test.dart` files previously each
/// re-declared an identical private `_pump<Thing>AtSize(...)` helper that
/// repeated the same `setSurfaceSize` + `MaterialApp(theme:
/// AppThemes.editorialMonocle, home: MediaQuery(...))` viewport shell. That
/// boilerplate now lives once in `app/test/support/min_viewport_harness.dart`
/// (`pumpAtMinViewport` / `buildMinViewportApp`). This gate keeps the
/// duplication from creeping back into that family.
///
/// **Scope (deliberately narrow).** Only the `*_320dp_min_viewport_test.dart`
/// family is governed, so the gate cannot fire on the many legitimately
/// distinct helpers elsewhere in `app/test/` (golden capture, mockup-fidelity,
/// widgetbook viewport stories, main-menu responsive `pumpAtSize`, etc.) that
/// also force a surface size and/or use the editorial theme for unrelated
/// reasons. The shared harness under `app/test/support/` is always exempt.
///
/// **Violations.** Inside a governed file, any of the following is flagged
/// because it indicates a re-introduced bespoke viewport shell instead of the
/// shared harness:
///   1. a function declaration whose name ends with `AtSize` (the
///      `_pump<Thing>AtSize` signature the harness replaced);
///   2. a `tester.binding.setSurfaceSize(...)` invocation;
///   3. a reference to `AppThemes.editorialMonocle`.
///
/// Detection is AST-based, so comments and string literals never trigger it.
int runCheckAppTestNoDuplicateScaffolding(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final appTestDir = Directory(p.join(repoRoot, 'app', 'test'));
  if (!appTestDir.existsSync()) {
    logI(
      'check_app_test_no_duplicate_scaffolding: app/test not found; nothing to '
      'scan.',
    );
    return 0;
  }

  final violations = <String>[];

  for (final entity in appTestDir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final relativePath = p
        .relative(entity.path, from: repoRoot)
        .replaceAll('\\', '/');
    final content = entity.readAsStringSync();
    final parsed = parseString(content: content, path: relativePath);
    if (_isGovernedMinViewportFile(relativePath)) {
      final visitor = _ScaffoldingVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
      );
      parsed.unit.accept(visitor);
    }
    if (_isGovernedWidgetbookUseCaseFile(relativePath)) {
      final visitor = _WidgetbookUseCaseVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
      );
      parsed.unit.accept(visitor);
    }
    if (_isGovernedTradeScreenFile(relativePath)) {
      final visitor = _TradeScreenHostVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
      );
      parsed.unit.accept(visitor);
    }
    if (_isGovernedUnitsPanelPartFile(relativePath)) {
      final visitor = _UnitsPanelInlineGameVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
      );
      parsed.unit.accept(visitor);
    }
    if (_isGovernedNavalUnitsPanelPartFile(relativePath)) {
      final visitor = _PanelPumpCloneVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
        forbiddenNames: const {'_pumpNaval', 'pumpNaval'},
        canonicalHelper: 'pumpNavalPanel',
        supportModule: 'naval_units_panel_test_support.dart',
      );
      parsed.unit.accept(visitor);
    }
    if (_isGovernedMilitaryUnitsPanelFile(relativePath)) {
      final visitor = _PanelPumpCloneVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
        forbiddenNames: const {'_pumpMilitary', 'pumpMilitary'},
        canonicalHelper: 'pumpMilitaryPanel',
        supportModule: 'military_units_panel_test_support.dart',
      );
      parsed.unit.accept(visitor);
    }
    if (_isGovernedTechnologyPanelFile(relativePath)) {
      final visitor = _PanelPumpCloneVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
        forbiddenNames: const {'_pumpPanel', 'pumpPanel'},
        canonicalHelper: 'pumpTechnologyPanel',
        supportModule: 'technology_panel_test_support.dart',
      );
      parsed.unit.accept(visitor);
    }
    if (_isGovernedAppShellHostFamilyFile(relativePath)) {
      final visitor = _InlineMaterialAppVisitor(
        relativePath: relativePath,
        lineInfo: parsed.unit.lineInfo,
        violations: violations,
      );
      parsed.unit.accept(visitor);
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_app_test_no_duplicate_scaffolding: no duplicated min-viewport, '
      'widgetbook use-case, trade-screen host, units-panel Game, naval/military/'
      'technology pump, or panel MaterialApp scaffolding found.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_test_no_duplicate_scaffolding: found ${violations.length} '
    'duplicated-scaffolding violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  logE(
    '   Min-viewport: use pumpAtMinViewport / buildMinViewportApp from '
    'app/test/support/min_viewport_harness.dart. '
    'Widgetbook: use findWidgetbookUseCase from '
    'app/test/support/widgetbook_test_harness.dart. '
    'Trade: use buildTradeTestGame / pumpTradeScreen* from '
    'app/test/support/trade_screen_test_support.dart. '
    'Units-panel: use shared factories in '
    'civilian_units_panel_test_support.dart / '
    'military_units_panel_test_support.dart / '
    'naval_units_panel_test_support.dart / units_panel_test_shared.dart. '
    'Naval part pumps: use pumpNavalPanel from '
    'naval_units_panel_test_support.dart. '
    'Military panel pumps: use pumpMilitaryPanel from '
    'military_units_panel_test_support.dart. '
    'Technology panel pumps: use pumpTechnologyPanel from '
    'technology_panel_test_support.dart. '
    'Production/naval/civilian/narrow-overlay/technology hosts: use '
    'buildProductionPanel / buildNavalPanel / buildCivilianPanel / '
    'buildMilitaryPanel / buildTechnologyPanel / '
    'buildAppShell (no inline MaterialApp).',
  );
  return 1;
}

/// True for `app/test/widgetbook_*_test.dart`, excluding support fixtures.
bool _isGovernedWidgetbookUseCaseFile(String relativePath) {
  final name = p.basename(relativePath);
  if (!name.startsWith('widgetbook_') || !name.endsWith('_test.dart')) {
    return false;
  }
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  return true;
}

/// True for `app/test/**/*_320dp_min_viewport_test.dart`, excluding the shared
/// harness tree under `app/test/support/` and generated Dart.
bool _isGovernedMinViewportFile(String relativePath) {
  if (!relativePath.endsWith('_320dp_min_viewport_test.dart')) {
    return false;
  }
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  if (relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.mocks.dart')) {
    return false;
  }
  return true;
}

/// True for `app/test/trade_screen_*_test.dart` (Refs #3952), excluding support.
bool _isGovernedTradeScreenFile(String relativePath) {
  final name = p.basename(relativePath);
  if (!name.startsWith('trade_screen_') || !name.endsWith('_test.dart')) {
    return false;
  }
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  return true;
}

/// True for units-panel suites that must call shared Game factories
/// (Refs #4021). Covers civilian/military/naval part + specialty suites that
/// previously re-declared private `Game(` builders.
bool _isGovernedUnitsPanelPartFile(String relativePath) {
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  final name = p.basename(relativePath);
  if (!name.endsWith('_test.dart')) {
    return false;
  }
  if (name.startsWith('civilian_units_panel_part') ||
      name.startsWith('naval_units_panel_part') ||
      name.startsWith('military_units_panel_army') ||
      name == 'military_units_panel_test.dart' ||
      name == 'military_units_panel_display_test.dart' ||
      name == 'civilian_units_panel_row_card_r30_test.dart' ||
      name == 'naval_units_panel_mockup_fidelity_test.dart') {
    return true;
  }
  return false;
}

/// True for `naval_units_panel_part*_test.dart` — must call shared
/// [pumpNavalPanel] (Refs #4035).
bool _isGovernedNavalUnitsPanelPartFile(String relativePath) {
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  final name = p.basename(relativePath);
  return name.startsWith('naval_units_panel_part') &&
      name.endsWith('_test.dart');
}

/// True for military panel suites that must call shared [pumpMilitaryPanel]
/// (Refs #4035).
bool _isGovernedMilitaryUnitsPanelFile(String relativePath) {
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  final name = p.basename(relativePath);
  return name == 'military_units_panel_test.dart' ||
      name == 'military_units_panel_display_test.dart' ||
      name == 'military_units_panel_army_test.dart';
}

/// True for technology panel suites that must call shared
/// [pumpTechnologyPanel] (Refs #4035).
bool _isGovernedTechnologyPanelFile(String relativePath) {
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  final name = p.basename(relativePath);
  return name == 'technology_panel_test.dart' ||
      name == 'technology_panel_interaction_test.dart' ||
      name == 'technology_panel_funding_toggles_test.dart' ||
      name == 'technology_panel_choose_tech_dialog_test.dart' ||
      name == 'technology_panel_slot_occupancy_test.dart' ||
      name == 'technology_panel_dark_chrome_test.dart';
}

/// True for panel-host families that must compose `buildAppShell` /
/// `buildProductionPanel` / `buildNavalPanel` instead of an inline
/// `MaterialApp` (Refs #4035). Filename-scoped; shrink-only. Includes
/// production specialty hosts (cotton-weaving lock, available grid, labour
/// section / step-surface / expected-lines mirror, allocation row chrome /
/// buttons, icons), military panel suites, technology panel suites that
/// already compose `buildTechnologyPanel` / `pumpTechnologyPanel`, train
/// dialog suites migrated onto `buildAppShell`, unit-order dialog suites
/// (`split_army` / `split_fleet` / `move_fleet` / `transfer_to_home_fleet`),
/// commodity-breakdown dialog suites
/// (`production_commodity_breakdown_dialog_spec` /
/// `production_commodity_breakdown_dialog_wide_full_width`), move-dialogs
/// specs part suites, `game_map_options_dialog_test`, next-turn / turn-news
/// dialog suites, pause-menu / side-menu spec suites, save/load dialog
/// suites (`save_game_name_dialog` / `load_game_list_dialog`), exit-confirm /
/// turn-resolution-processing dialog suites, `diplomacy_dialogs_test`, and
/// dialogue-overlay suites (`tribe_first_contact_overlay`,
/// `call_to_arms_dialogue_overlay_dark_chrome`, `overture_dialogue_overlay`,
/// `overture_dialogue_intro`, `intervention_dialogue_overlay`,
/// `dialogue_overlays_specs_part*`), victory overlay suites,
/// `debug_console_overlay_panel_test`, and province-overlay suites
/// (`province_overlay_test`, `province_overlay_header_l10n_test`,
/// `province_overlay_consulate_gate_tooltip_test`,
/// `province_overlay_fully_unrevealed_sea_zone_structure_test`,
/// `province_overlay_tile_inline_action_non_clickable_test`,
/// `province_overlay_section_label_material_fallback_guard_test`). Also
/// province-sea-zone overlay suites (`province_sea_zone_overlay_detail_paths`,
/// `province_sea_zone_overlay_naval_port_pending_omission`,
/// `province_sea_zone_resource_labels`), and catalog widget unit hosts
/// (`base_units_panel`, `units_combine_header_actions`,
/// `units_panel_shared_widgets`, `unit_panels_viewport_sizing`,
/// `unit_panels_widgetbook_dark_chrome`), units sheet/entity card hosts
/// (`units_panel_sheet_surface`, `units_entity_card`), catalog chrome
/// (`ct_action_text_button`, `relation_meter`), in-game shell chrome
/// (`game_top_bar`, `game_tab_bar`, `player_turn_event_feed_chrome`),
/// `ct_dark_scaffold`, `ct_screen_shell`, `ct_dialog_shell`,
/// `ct_full_screen_dialogue_shell`, `ct_game_feature_screen_shell`),
/// `game_side_menu_test`, and catalog controls (`ct_back_button`,
/// `ct_slider`, `ct_tab_strip`, `ct_confirm_dialog`, `ct_nine_patch_button`,
/// `ct_resource_cell`), game-map chrome hosts (`game_map_controls`,
/// `players_bar_toggle`, `game_map_corner_controls_dark_chrome`,
/// `game_map_corner_controls_narrow`, `game_map_players_bar`), empire left-rail
/// hosts (`game_map_empire_left_rail`, `game_map_empire_left_rail_chrome`,
/// `game_map_empire_left_rail_narrow`), region minimap hosts
/// (`game_region_minimap_widget`, `game_region_minimap_narrow`), and game-map
/// area hosts (`game_map_area_background`, `game_map_area_event_feed`,
/// `game_map_area_region_minimap`, `game_map_area_selection_mode`,
/// `game_map_area_selection_mode_lightweight`,
/// `game_map_area_shell_entry_center`), catalog/diplomacy widget hosts
/// (`ct_choice_chip`, `ct_transfer_list`, `gp_default_map_color_swatch`,
/// `diplomacy_standing_chips`, `diplomacy_relative_power_line`,
/// `tech_gp_pennant_widget`), quick-battle hosts (`quick_battle_screen`,
/// `quick_battle_deployment_view_dark_tokens`,
/// `quick_battle_action_selector_dark_tokens`), tech-tree widget hosts
/// (`tech_tree_widget_core`, `tech_tree_widget_palette`,
/// `tech_tree_widget_description_batches`), player-turn-event-feed narrow hosts
/// (`player_turn_event_feed_narrow_width`,
/// `player_turn_event_feed_narrow_inset`), and
/// `game_map_selection_prompt_dark_tokens`, diplomacy mockup / grant-subsidy /
/// dialogue acceptance / production-screen integration hosts
/// (`diplomacy_panel_mockup_fidelity`, `grant_or_subsidy_listener`,
/// `dialogue_acceptance`, `production_screen_integration`),
/// `ct_radius_adoption`, `province_detail_panel_slide_transition`, shell /
/// main-menu hosts (`shell_screen`, `shell_screen_pixelart_chrome`,
/// `main_menu_quit_chip_fidelity`, `new_game_leader_dialog_builder`,
/// `shell_player_guarded_body`), and `map_diplomacy_panel_specs`, combat
/// UI specs parts (`combat_ui_specs_part1` / `combat_ui_specs_part2`),
/// `game_to_ui_bus_listener`, `app_event_handler_scope_diplomacy`,
/// `app_event_handler_scope_civilian_work`,
/// `turn_resolution_event_blocking`, `app_event_handler`,
/// `game_session_clear_ui_path`, `new_game_setup_flow`,
/// `app_wave5_shared_helpers`, `screen_spec_acceptance_part2`,
/// `widgetbook_dlg60001_shel30001_stories`,
/// `widgetbook_main_menu_stories_editorial_monocle`,
/// `widgetbook_diplomacy_standing_chips_stories`,
/// `widgetbook_diplomacy_detail_screen_stories`,
/// `widgetbook_diplomacy_panel_empty_state`, and
/// `widgetbook_technology_slots_variants`.
bool _isGovernedAppShellHostFamilyFile(String relativePath) {
  if (relativePath.startsWith('app/test/support/')) {
    return false;
  }
  final name = p.basename(relativePath);
  if (!name.endsWith('_test.dart')) {
    return false;
  }
  return name.startsWith('production_panel_part') ||
      name == 'production_panel_cotton_weaving_lock_test.dart' ||
      name == 'production_panel_available_grid_test.dart' ||
      name == 'production_labour_section_test.dart' ||
      name == 'production_labour_section_step_surface_test.dart' ||
      name == 'production_labour_controls_expected_lines_test.dart' ||
      name == 'production_allocation_row_buttons_test.dart' ||
      name == 'production_allocation_row_chrome_test.dart' ||
      name == 'production_panel_icons_test.dart' ||
      name.startsWith('naval_units_panel_part') ||
      name.startsWith('civilian_units_panel_part') ||
      name == 'civilian_units_panel_row_card_r30_test.dart' ||
      name == 'naval_units_panel_mockup_fidelity_test.dart' ||
      name == 'game_map_narrow_detail_overlay_test.dart' ||
      name == 'military_units_panel_test.dart' ||
      name == 'military_units_panel_display_test.dart' ||
      name == 'military_units_panel_army_test.dart' ||
      name == 'technology_panel_test.dart' ||
      name == 'technology_panel_interaction_test.dart' ||
      name == 'technology_panel_funding_toggles_test.dart' ||
      name == 'technology_panel_choose_tech_dialog_test.dart' ||
      name == 'technology_panel_slot_occupancy_test.dart' ||
      name == 'technology_panel_dark_chrome_test.dart' ||
      name == 'train_dialog_chrome_test.dart' ||
      name == 'train_dialog_base_test.dart' ||
      name == 'train_dialog_inline_cost_tooltip_test.dart' ||
      name == 'train_commodity_cost_dialog_base_test.dart' ||
      name == 'train_naval_dialog_test.dart' ||
      name == 'train_military_dialog_test.dart' ||
      name == 'train_civilians_dialog_test.dart' ||
      name == 'split_army_dialog_test.dart' ||
      name == 'split_fleet_dialog_test.dart' ||
      name == 'move_fleet_dialog_test.dart' ||
      name == 'transfer_to_home_fleet_dialog_spec_test.dart' ||
      name == 'production_commodity_breakdown_dialog_spec_test.dart' ||
      name == 'production_commodity_breakdown_dialog_wide_full_width_test.dart' ||
      name.startsWith('move_dialogs_specs_part') ||
      name == 'game_map_options_dialog_test.dart' ||
      name == 'next_turn_confirmation_dialog_test.dart' ||
      name == 'turn_news_dialog_test.dart' ||
      name == 'pause_menu_panel_test.dart' ||
      name == 'pause_menu_side_menu_specs_test.dart' ||
      name == 'save_game_name_dialog_test.dart' ||
      name == 'load_game_list_dialog_test.dart' ||
      name == 'exit_confirm_dialog_test.dart' ||
      name == 'turn_resolution_processing_dialog_test.dart' ||
      name == 'diplomacy_dialogs_test.dart' ||
      name == 'tribe_first_contact_overlay_test.dart' ||
      name == 'call_to_arms_dialogue_overlay_dark_chrome_test.dart' ||
      name == 'overture_dialogue_overlay_test.dart' ||
      name == 'overture_dialogue_intro_test.dart' ||
      name == 'intervention_dialogue_overlay_test.dart' ||
      name.startsWith('dialogue_overlays_specs_part') ||
      name == 'victory_overlay_test.dart' ||
      name == 'victory_overlay_narrow_test.dart' ||
      name == 'debug_console_overlay_panel_test.dart' ||
      name == 'province_overlay_test.dart' ||
      name == 'province_overlay_header_l10n_test.dart' ||
      name == 'province_overlay_consulate_gate_tooltip_test.dart' ||
      name == 'province_overlay_fully_unrevealed_sea_zone_structure_test.dart' ||
      name == 'province_overlay_tile_inline_action_non_clickable_test.dart' ||
      name == 'province_overlay_section_label_material_fallback_guard_test.dart' ||
      name == 'province_overlay_tile_designation_test.dart' ||
      name == 'province_overlay_sea_zone_political_dark_tokens_test.dart' ||
      name == 'province_overlay_obfuscated_body_dark_tokens_test.dart' ||
      name == 'province_overlay_economic_row_order_coords_test.dart' ||
      name == 'province_overlay_economic_hover_test.dart' ||
      name == 'province_overlay_road_rail_transport_test.dart' ||
      name == 'province_overlay_narrow_side_rail_height_pin_test.dart' ||
      name == 'province_overlay_tile_resource_row_label_inline_dark_token_test.dart' ||
      name == 'province_sea_zone_overlay_detail_paths_test.dart' ||
      name == 'province_sea_zone_overlay_naval_port_pending_omission_test.dart' ||
      name == 'province_sea_zone_resource_labels_test.dart' ||
      name == 'base_units_panel_test.dart' ||
      name == 'units_combine_header_actions_test.dart' ||
      name == 'units_panel_shared_widgets_test.dart' ||
      name == 'unit_panels_viewport_sizing_test.dart' ||
      name == 'unit_panels_widgetbook_dark_chrome_test.dart' ||
      name == 'units_panel_sheet_surface_test.dart' ||
      name == 'units_entity_card_test.dart' ||
      name == 'ct_action_text_button_test.dart' ||
      name == 'relation_meter_test.dart' ||
      name == 'game_top_bar_test.dart' ||
      name == 'game_tab_bar_test.dart' ||
      name == 'player_turn_event_feed_chrome_test.dart' ||
      name == 'game_side_menu_test.dart' ||
      name == 'ct_dark_scaffold_test.dart' ||
      name == 'ct_screen_shell_test.dart' ||
      name == 'ct_dialog_shell_test.dart' ||
      name == 'ct_full_screen_dialogue_shell_test.dart' ||
      name == 'ct_game_feature_screen_shell_test.dart' ||
      name == 'ct_back_button_test.dart' ||
      name == 'ct_slider_test.dart' ||
      name == 'ct_tab_strip_test.dart' ||
      name == 'ct_confirm_dialog_test.dart' ||
      name == 'ct_nine_patch_button_test.dart' ||
      name == 'ct_resource_cell_test.dart' ||
      name == 'game_map_controls_test.dart' ||
      name == 'players_bar_toggle_test.dart' ||
      name == 'game_map_corner_controls_dark_chrome_test.dart' ||
      name == 'game_map_corner_controls_narrow_test.dart' ||
      name == 'game_map_players_bar_test.dart' ||
      name == 'game_map_empire_left_rail_test.dart' ||
      name == 'game_map_empire_left_rail_chrome_test.dart' ||
      name == 'game_map_empire_left_rail_narrow_test.dart' ||
      name == 'game_region_minimap_widget_test.dart' ||
      name == 'game_region_minimap_narrow_test.dart' ||
      name == 'game_map_area_background_test.dart' ||
      name == 'game_map_area_event_feed_test.dart' ||
      name == 'game_map_area_region_minimap_test.dart' ||
      name == 'game_map_area_selection_mode_test.dart' ||
      name == 'game_map_area_selection_mode_lightweight_test.dart' ||
      name == 'game_map_area_shell_entry_center_test.dart' ||
      name == 'ct_choice_chip_test.dart' ||
      name == 'ct_transfer_list_test.dart' ||
      name == 'gp_default_map_color_swatch_test.dart' ||
      name == 'diplomacy_standing_chips_test.dart' ||
      name == 'diplomacy_relative_power_line_test.dart' ||
      name == 'tech_gp_pennant_widget_test.dart' ||
      name == 'quick_battle_screen_test.dart' ||
      name == 'quick_battle_deployment_view_dark_tokens_test.dart' ||
      name == 'quick_battle_action_selector_dark_tokens_test.dart' ||
      name == 'tech_tree_widget_core_test.dart' ||
      name == 'tech_tree_widget_palette_test.dart' ||
      name == 'tech_tree_widget_description_batches_test.dart' ||
      name == 'player_turn_event_feed_narrow_width_test.dart' ||
      name == 'player_turn_event_feed_narrow_inset_test.dart' ||
      name == 'game_map_selection_prompt_dark_tokens_test.dart' ||
      name == 'diplomacy_panel_mockup_fidelity_test.dart' ||
      name == 'ct_radius_adoption_test.dart' ||
      name == 'grant_or_subsidy_listener_test.dart' ||
      name == 'province_detail_panel_slide_transition_test.dart' ||
      name == 'dialogue_acceptance_test.dart' ||
      name == 'production_screen_integration_test.dart' ||
      name == 'shell_screen_test.dart' ||
      name == 'shell_screen_pixelart_chrome_test.dart' ||
      name == 'main_menu_quit_chip_fidelity_test.dart' ||
      name == 'new_game_leader_dialog_builder_test.dart' ||
      name == 'shell_player_guarded_body_test.dart' ||
      name == 'map_diplomacy_panel_specs_test.dart' ||
      name == 'combat_ui_specs_part1_test.dart' ||
      name == 'combat_ui_specs_part2_test.dart' ||
      name == 'game_to_ui_bus_listener_test.dart' ||
      name == 'app_event_handler_scope_diplomacy_test.dart' ||
      name == 'app_event_handler_scope_civilian_work_test.dart' ||
      name == 'turn_resolution_event_blocking_test.dart' ||
      name == 'app_event_handler_test.dart' ||
      name == 'game_session_clear_ui_path_test.dart' ||
      name == 'new_game_setup_flow_test.dart' ||
      name == 'app_wave5_shared_helpers_test.dart' ||
      name == 'screen_spec_acceptance_part2_test.dart' ||
      name == 'widgetbook_dlg60001_shel30001_stories_test.dart' ||
      name == 'widgetbook_main_menu_stories_editorial_monocle_test.dart' ||
      name == 'widgetbook_diplomacy_standing_chips_stories_test.dart' ||
      name == 'widgetbook_diplomacy_detail_screen_stories_test.dart' ||
      name == 'widgetbook_diplomacy_panel_empty_state_test.dart' ||
      name == 'widgetbook_technology_slots_variants_test.dart';
}

class _ScaffoldingVisitor extends RecursiveAstVisitor<void> {
  _ScaffoldingVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  void _report(int offset, String detail) {
    final line = lineInfo.getLocation(offset).lineNumber;
    violations.add('$relativePath:$line: $detail');
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (name.endsWith('AtSize')) {
      _report(
        node.name.offset,
        'function "$name" re-declares a per-file min-viewport pump helper',
      );
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setSurfaceSize') {
      _report(
        node.methodName.offset,
        'direct "setSurfaceSize" call duplicates the harness viewport setup',
      );
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'editorialMonocle') {
      _report(
        node.offset,
        'reference to "AppThemes.editorialMonocle" duplicates the harness shell',
      );
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'editorialMonocle') {
      _report(
        node.offset,
        'reference to "AppThemes.editorialMonocle" duplicates the harness shell',
      );
    }
    super.visitPropertyAccess(node);
  }
}

class _WidgetbookUseCaseVisitor extends RecursiveAstVisitor<void> {
  _WidgetbookUseCaseVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  void _report(int offset, String detail) {
    final line = lineInfo.getLocation(offset).lineNumber;
    violations.add('$relativePath:$line: $detail');
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (name != '_useCase') {
      super.visitFunctionDeclaration(node);
      return;
    }
    final returnType = node.returnType;
    if (returnType != null &&
        returnType.toString().contains('WidgetbookUseCase')) {
      _report(
        node.name.offset,
        'function "_useCase" duplicates widgetbook_test_harness.dart',
      );
    }
    super.visitFunctionDeclaration(node);
  }
}

class _TradeScreenHostVisitor extends RecursiveAstVisitor<void> {
  _TradeScreenHostVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  static const Set<String> _forbiddenNames = {
    '_buildGame',
    '_buildGameForTradeScreen',
    '_buildStandaloneGame',
    '_pumpTradeScreen',
    '_pumpTradeScreenObserveMode',
    '_pumpTradeScreenStandalone',
    '_pumpDealBookTab',
  };

  void _report(int offset, String detail) {
    final line = lineInfo.getLocation(offset).lineNumber;
    violations.add('$relativePath:$line: $detail');
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (_forbiddenNames.contains(name)) {
      _report(
        node.name.offset,
        'function "$name" duplicates trade_screen_test_support.dart',
      );
    }
    super.visitFunctionDeclaration(node);
  }
}

/// Flags inline `Game(` construction in units-panel part suites (Refs #4021).
///
/// Unresolved `Game(...)` is a [MethodInvocation] under `parseString` without
/// package resolution; `const Game(...)` / `new Game(...)` remain
/// [InstanceCreationExpression]. Catch both.
class _UnitsPanelInlineGameVisitor extends RecursiveAstVisitor<void> {
  _UnitsPanelInlineGameVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  void _report(int offset, String detail) {
    final line = lineInfo.getLocation(offset).lineNumber;
    violations.add('$relativePath:$line: $detail');
  }

  void _flagIfGame(String typeName, int offset) {
    if (typeName == 'Game') {
      _report(
        offset,
        'inline Game( construction; use civilian/military/naval units-panel '
        'test support factories',
      );
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // ignore: deprecated_member_use
    _flagIfGame(node.constructorName.type.name.lexeme, node.offset);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null) {
      _flagIfGame(node.methodName.name, node.methodName.offset);
    }
    super.visitMethodInvocation(node);
  }
}

/// Flags local panel pump clones (`_pumpNaval` / `_pumpMilitary`, …)
/// (Refs #4035). Call the named support helper instead.
class _PanelPumpCloneVisitor extends RecursiveAstVisitor<void> {
  _PanelPumpCloneVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
    required this.forbiddenNames,
    required this.canonicalHelper,
    required this.supportModule,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;
  final Set<String> forbiddenNames;
  final String canonicalHelper;
  final String supportModule;

  void _report(int offset, String detail) {
    final line = lineInfo.getLocation(offset).lineNumber;
    violations.add('$relativePath:$line: $detail');
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    if (forbiddenNames.contains(name)) {
      _report(
        node.name.offset,
        'function "$name" duplicates $canonicalHelper in $supportModule',
      );
    }
    super.visitFunctionDeclaration(node);
  }
}

/// Flags inline `MaterialApp(` hosts in families that already have canonical
/// `buildAppShell` / panel host helpers (Refs #4035).
class _InlineMaterialAppVisitor extends RecursiveAstVisitor<void> {
  _InlineMaterialAppVisitor({
    required this.relativePath,
    required this.lineInfo,
    required this.violations,
  });

  final String relativePath;
  final LineInfo lineInfo;
  final List<String> violations;

  void _report(int offset, String detail) {
    final line = lineInfo.getLocation(offset).lineNumber;
    violations.add('$relativePath:$line: $detail');
  }

  void _flagIfMaterialApp(String typeName, int offset) {
    if (typeName == 'MaterialApp') {
      _report(
        offset,
        'inline MaterialApp( host; use buildProductionPanel / '
        'buildNavalPanel / buildCivilianPanel / buildMilitaryPanel / '
        'buildTechnologyPanel / buildAppShell / buildAppShellWithContainer '
        'from app/test/support/',
      );
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // ignore: deprecated_member_use
    _flagIfMaterialApp(node.constructorName.type.name.lexeme, node.offset);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null) {
      _flagIfMaterialApp(node.methodName.name, node.methodName.offset);
    }
    super.visitMethodInvocation(node);
  }
}

void main() {
  exit(runCheckAppTestNoDuplicateScaffolding(Directory.current.path));
}
