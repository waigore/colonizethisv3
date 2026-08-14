// Migrated feature-file paths for CtSpacing adoption pins (Refs #4352).

const List<String> ctSpacingMigratedFeatureFiles = <String>[
  'lib/features/game/widgets/combat/quick_battle_deployment_view.dart',
  // game_start_intro_overlay.dart is a de-parted barrel (Refs #4117); build mixin
  // owns the migrated insets.
  'lib/features/game/widgets/dialogue/game_start_intro_overlay_build.dart',
  'lib/features/game/widgets/dialogue/intervention_choice_buttons.dart',
  // intervention_dialogue_overlay.dart is a de-parted barrel; shell + state
  // modules own the migrated insets.
  'lib/features/game/widgets/dialogue/intervention_dialogue_overlay_shell.dart',
  'lib/features/game/widgets/dialogue/intervention_dialogue_overlay_state.dart',
  // overture_dialogue_overlay.dart is a de-parted barrel; state module owns the
  // migrated insets.
  'lib/features/game/widgets/dialogue/overture_dialogue_overlay_state.dart',
  'lib/features/game/widgets/dialogue/overture_dialogue_overlay_offer_row.dart',
  // CtSpacing callsites moved to the extracted selection-prompt widget.
  'lib/features/game/flame/map_area/game_map_canvas_stack_selection_prompt.dart',
  // game_side_menu.dart is a de-parted barrel; panel module owns the inset.
  'lib/features/game/flame/controls/game_side_menu_panel.dart',
  'lib/features/game/flame/overlays/next_turn_confirmation_dialog.dart',
  // victory_overlay.dart is a de-parted barrel; panel module owns the inset.
  'lib/features/game/flame/overlays/victory_overlay_panel.dart',
  // diplomacy_detail_screen.dart is a de-parted barrel; sections module owns the
  // symmetric padding.
  'lib/features/game/screens/diplomacy/diplomacy_detail_screen_widgets_sections.dart',
  // technology_screen.dart is a de-parted barrel; body module owns the inset.
  'lib/features/game/screens/technology/technology_screen_body.dart',
  // trade_screen.dart is a de-parted barrel (Refs #4117); token callsites live
  // in the tabs body module.
  'lib/features/game/screens/trade/trade_screen_tabs_body.dart',
  'lib/features/game/screens/trade/trade_screen_deal_book_panel.dart',
  // civilian_units_panel.dart is a de-parted barrel; unit-row actions module
  // owns the token-eligible insets.
  'lib/features/game/widgets/units/civilian/civilian_units_panel_support_unit_row_actions.dart',
  // diplomacy_dialogs.dart is a de-parted barrel; grant/subsidy stepper owns the
  // symmetric padding.
  'lib/features/game/widgets/diplomacy/diplomacy_dialogs_grant_subsidy_chrome_stepper.dart',
  // diplomacy_panel.dart is a de-parted barrel (Refs #4117); list body owns the
  // panel-wide symmetric padding.
  'lib/features/game/widgets/diplomacy/diplomacy_panel_body.dart',
  // diplomacy_panel_chrome_badges.dart split: section header keeps CtSpacing;
  // relation/alliance badge chips use fixed 5×1 px padding (out of token set).
  'lib/features/game/widgets/diplomacy/diplomacy_panel_chrome_section_header.dart',
  'lib/features/game/widgets/diplomacy/diplomacy_panel_chrome_standing.dart',
  'lib/features/game/widgets/diplomacy/diplomacy_panel_mode_bar.dart',
  'lib/features/game/widgets/panels/fleet_expansion_tile.dart',
  // game_tab_bar.dart is a de-parted barrel; indicators module owns the symmetric
  // padding.
  'lib/features/game/widgets/shell/game_tab_bar_indicators.dart',
  // military_units_panel.dart is a de-parted barrel; detail-rows module owns the
  // token-eligible insets.
  'lib/features/game/widgets/units/military/military_units_panel_support_detail_rows.dart',
  // move_army_dialog.dart is a de-parted barrel; shared row scaffold owns the
  // token-eligible symmetric padding.
  'lib/features/game/widgets/unit_orders/move_units_dialog_base_row.dart',
  'lib/features/game/widgets/unit_orders/move_fleet_dialog.dart',
  // naval_units_panel.dart dropped from the adoption list: #3523 replaced its
  // only CtSpacing callsite (the header button's vertical: CtSpacing.s padding)
  // with CtActionTextButton pills, leaving only an out-of-scale
  // `SizedBox(width: 4)` gap (a legitimate override per SPEC § Spacing tokens,
  // kept raw in the sibling military_units_panel.dart). With no token-eligible
  // spacing left, the import/token-reference invariants no longer apply.
  'lib/features/game/widgets/panels/observe_mode_not_defined_panel.dart',
  'lib/features/game/widgets/panels/pause_menu_panel.dart',
  'lib/features/game/widgets/production/production_allocation_row_chrome.dart',
  // production_commodity_breakdown_dialog.dart is a de-parted barrel; table cells
  // module owns the token-eligible inset.
  'lib/features/game/widgets/production/production_commodity_breakdown_dialog_table_cells.dart',
  // production_panel.dart is a de-parted barrel; layout helpers own the body
  // padding.
  'lib/features/game/widgets/production/production_panel_layouts.dart',
  // province_sea_zone_detail_overlay.dart is a de-parted barrel (Refs #4117);
  // header chrome and section stack helpers own the migrated insets.
  'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_chrome.dart',
  'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart',
  // split_army_dialog.dart / split_fleet_dialog.dart dropped from the adoption
  // list: #3594 (PR #3600) extracted the shared SplitEntityDialog base, which
  // now owns the `Padding(EdgeInsets.all(CtSpacing.l))` body. Both dialogs
  // delegate their scaffold to that base and no longer contain any
  // token-eligible `EdgeInsets`/`SizedBox` spacing, so the import and
  // token-reference invariants moved to split_entity_dialog.dart below.
  'lib/features/game/widgets/unit_orders/split_entity_dialog.dart',
  'lib/features/game/widgets/technology/tech_tree_widget.dart',
  'lib/features/game/widgets/technology/technology_panel.dart',
  // technology_panel_orders.dart is a de-parted barrel; choose-tech rows own the
  // token-eligible insets.
  'lib/features/game/widgets/technology/technology_panel_choose_tech_dialog_rows.dart',
  // train_civilians_dialog.dart / train_military_dialog.dart dropped from the
  // adoption list: #3594 extracted the shared TrainDialogBase state, which now
  // owns the `EdgeInsets.fromLTRB(CtSpacing.l, CtSpacing.ml, ...)`
  // PopScope/CtDialogShell scaffold. Both dialogs (and the sibling
  // train_naval_dialog.dart, which was never token-eligible) delegate that
  // wrapper to the base and no longer contain token-eligible
  // `EdgeInsets`/`CtSpacing` spacing, so the import and token-reference
  // invariants moved to train_dialog_base_state.dart below.
  'lib/features/game/widgets/train/train_dialog_base_state.dart',
  'lib/features/game/widgets/train/train_dialog_chrome.dart',
  'lib/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart',
  'lib/features/game/widgets/dialogs/turn_news_dialog.dart',
  'lib/features/game/widgets/units/shared/location_section_header.dart',
  'lib/features/game/widgets/units/shared/region_section_header.dart',
  // units_entity_action_row.dart is a de-parted barrel; actions module owns the
  // symmetric padding.
  'lib/features/game/widgets/units/shared/units_entity_action_row_actions.dart',
  'lib/features/game/widgets/units/shared/units_panel_row_chrome.dart',
  'lib/features/game/widgets/units/shared/units_panel_shell.dart',
  // new_game_setup_flow.dart is a de-parted barrel; error dialog module owns the
  // token-eligible inset.
  'lib/features/shell/new_game_setup_flow_dialogs_error.dart',
  'lib/features/debug_log/debug_log_viewer_screen.dart',
  // Top-level shell screen widgets (`CtMainMenu`) under `lib/widgets/`.
  // main_menu.dart delegates layout padding to main_menu_constants.dart
  // (Refs #4117 de-part).
  'lib/widgets/main_menu_constants.dart',
];
