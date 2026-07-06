# Repo Layout and Package Plan

**SPEC/program** — In-repo source of truth for repository structure and shared packages. Derived from **TDD 15 (Technical Architecture)**.

---

## Repo layout

Monorepo layout:

- **Root:** `SPEC/`, `packages/`, `app/`, **`ctdev/`** (developer Flutter shell; sim and tooling UI), optional `assets/`, **`tool/`** (standalone CLI tools), tooling (e.g. `analysis_options.yaml`).
- **Flutter app** lives under **`app/`** (not at root). Run and build from `app/` (e.g. `flutter run`, `flutter build macos`). Package work is done in `packages/<name>/`.
- **Ctdev** lives under **`ctdev/`** — Flutter package for development workflows (see [ctdev-app.md](ctdev-app.md)).
- **Standalone CLI tools** (e.g. topology description, map generation) live under **`tool/`**. Run from the **project root** via **Melos**: `melos run <tool_name> -- [args]` (paths in args are relative to repo root). The repo uses a root Dart workspace and Melos for scripts; see [.cursor/rules/colonizethis-tools.mdc](../../.cursor/rules/colonizethis-tools.mdc). Tools may depend on colonizethis_data or a shared reader to load topology.
- **No `server/`** in current scope.

### App shell submodule layout (Refs #3878)

- **`AppEventHandlerScope`** (`app/lib/core/services/app_event_handler_scope.dart`) binds session-scoped bus listeners. Session subscriptions are split into `part` files by event family (observe, civilian work, naval/army, diplomacy, debug), each capped at 500 non-comment lines (`repo.app_event_handler_part_size`). [`TurnResolutionResultApplier`](../../app/lib/core/services/turn_resolution_result_applier.dart) applies worker isolate turn-resolution results to session notifiers without threading `WidgetRef` through helpers.
- **`DebugCommandSessionHandler`** and **`ObserveModeSessionHandler`** apply ctdev/debug and observe-mode session mutations without importing feature panels.
- **`colonizethis_app_e2e_support`** (`packages/colonizethis_app_e2e_support`) hosts E2E/widget mirror helpers (`e2e_helpers.dart`, `e2e_test_shared*.dart`, panel expected-line fixtures) previously under `app/integration_test/` and `app/test/e2e_*`. `app/test` retains only barrel/contract tests (≤10 `e2e_*.dart` files); integration scenarios import the support package. Seed-42 demo fixtures remain in `app/lib/test_support/` (production/widgetbook consumers).
- **`features/shell/new_game_leader_selection_dialog.dart`** — DLG10001 new-game leader picker dialog library: `_NewGameLeaderSelectionDialogStateBase` (shared fields + validation), `_NewGameLeaderSelectionDialogSlots` (slot rows + responsive pickers), `_NewGameLeaderSelectionDialogSetupFields` (seed/advanced-start/infinite/terrain/footer). Public widget: `NewGameLeaderSelectionDialog`.
- **`features/game/flame/caches/`** — shared Flame asset decode helper (`AssetImageCache`), map marker icon caches (town, port, fleet, civilian, resource, province label), and logic re-export for [`PerPlayerWorkTargetSelectionCache`](../../app/lib/features/game/flame/caches/per_player_work_target_selection_cache.dart). Public barrel: `caches/caches.dart`.
- **`features/game/flame/host/`** — empty Flame game host ([ColonizeThisGame](../../app/lib/features/game/flame/host/game_canvas.dart)). Public barrel: `host/host.dart`.
- **`features/game/flame/map_area/`** — `GameMapAreaBackground`, [`GameMapCanvasStack`](../../app/lib/features/game/flame/map_area/game_map_canvas_stack.dart) (map + wide detail panel), and selection-prompt overlay ([`GameMapCanvasStackSelectionPrompt`](../../app/lib/features/game/flame/map_area/game_map_canvas_stack_selection_prompt.dart)). Public barrel: `map_area/map_area.dart`.
- **`features/game/flame/map_state/`** — `GameMapArea` widget stack, selection, province actions, turn-feed hooks, draft projections, and [`ProvinceActionStateCalculator`](../../app/lib/features/game/flame/map_state/province_action_state_calculator.dart) (shared explore/prospect/build-improvement inline action states for overlay hosts). `game_map_area.dart` library parts: `game_map_area_turn_feed_labels.dart` (turn-feed display labels + map-locate helpers), `game_map_area_turn_feed.dart` (turn-feed entry builder), `game_map_area_build_map_stack.dart` (map canvas stack + in-map overlay chrome), `game_map_area_build_overlays.dart` (play-area shell + debug/narrow slots), `game_map_area_build.dart` (controls bar + play-area shell). `game_map_area_state_logic.dart` library parts: `game_map_area_state_logic_work_targets.dart`, `game_map_area_state_logic_draft_projection.dart`, `game_map_area_state_logic_province_actions.dart`. `game_map_area_province_action_states.dart` library parts: `game_map_area_province_action_states_prospect.dart`, `game_map_area_province_action_states_explore.dart`, `game_map_area_province_action_states_build_improvement.dart`. `game_map_area_fleet_draft_projection.dart` library parts: `game_map_area_fleet_draft_projection_scope.dart` (location scope keys), `game_map_area_fleet_draft_projection_tiles.dart` (drawable tile resolution). Public barrel: `map_state/map_state.dart`.
- **`features/game/flame/region_map/`** — `RegionMapComponent` Flame render stack, `CtRegionMapGame` host (`ct_region_map_game.dart` library parts: `ct_region_map_game_camera.dart`, `ct_region_map_game_props.dart`, `ct_region_map_game_viewport.dart`), and viewport helpers. `region_map_component.dart` library parts split shared constants/plate layout (`region_map_component_shared.dart`) from visibility modes (`region_map_component_shared_visibility.dart`), fog/transport helpers (`region_map_component_shared_visibility_fog_transport.dart`), extraction disc helpers (`region_map_component_shared_visibility_extraction.dart`), and label/halos (`region_map_component_shared_visibility_*.dart`); hover/tap hit-testing (`region_map_component_interaction.dart`); province topology borders and GP ownership tint (`region_map_component_render_political_borders_province.dart`); faction political borders (`region_map_component_render_political_borders_faction.dart`); civilian vs fleet unit marker paint (`region_map_component_render_markers_units_civilian.dart`, `region_map_component_render_markers_units_fleet.dart`); capital rings (`region_map_component_render_markers_settlements_capitals.dart`), town/port paint (`region_map_component_render_markers_settlements_towns.dart`), and warp-zone edges (`region_map_component_render_markers_settlements_warp.dart`); province label compute vs paint (`region_map_component_render_political_labels_province_compute.dart`, `region_map_component_render_political_labels_province_paint.dart`). Public barrel: `region_map/region_map.dart`.
- **`features/game/flame/tilesets/`** — terrain Wang tilesets, transport overlay tilesets, and connectivity masks. `terrain_tileset.dart` library parts: `terrain_tileset_models.dart` (Wang tile types, layer enum), `terrain_tileset_variant_keys.dart` (L2 variant tile-key resolution). Public barrel: `tilesets/tilesets.dart`.
- **`features/game/flame/controls/`** — in-game map shell chrome: top/tab bar ([GameMapControls](../../app/lib/features/game/flame/controls/game_map_controls.dart)), corner tool row ([GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart)), empire left rail ([GameMapEmpireLeftRail](../../app/lib/features/game/flame/controls/game_map_empire_left_rail.dart)), and slide-out hamburger menu ([GameSideMenu](../../app/lib/features/game/flame/controls/game_side_menu.dart)). Public barrel: `controls/controls.dart`.
- **`features/game/flame/overlays/`** — map and session overlays/dialogs: province detail hosts ([GameMapProvinceDetailSidePanel](../../app/lib/features/game/flame/overlays/game_map_province_detail_side_panel.dart), [GameMapNarrowDetailOverlaySlot](../../app/lib/features/game/flame/overlays/game_map_narrow_detail_overlay.dart)), turn confirmation/processing dialogs, victory overlay ([VictoryPanel](../../app/lib/features/game/flame/overlays/victory_overlay.dart) library parts: `victory_overlay_panel.dart`, `victory_overlay_panel_corners.dart`), exit confirm, and debug console panel. Public barrel: `overlays/overlays.dart`.
- **`features/game/flame/minimap/`** — [GameRegionMinimap](../../app/lib/features/game/flame/minimap/game_region_minimap.dart) widget and viewport math helpers; `part` files: `game_region_minimap_controls.dart` (zoom slider + toggle chrome), `game_region_minimap_painter.dart` (terrain fill + viewport indicator). Public barrel: `minimap/minimap.dart`.
- **`features/game/flame/render/`** — pure map render helpers: GP ownership tint layer, warp-zone edge geometry, and resource extraction disc palette table. Public barrel: `render/render.dart`. `map_area/` and `region_map/` must not import `map_state/`; `map_state/` may import `map_area` public exports only (`map_area/map_area.dart`). Legacy re-export shims under `flame/` root are forbidden — import submodule barrels directly.
- **Widgetbook catalogs** (`widgetbook_host/lib/catalogs/`) — dev-only Widgetbook stories and catalog `part` files. `app/lib/widgetbook.dart` is a thin re-export shim for local `flutter run -t lib/widgetbook.dart`; production analyze scope for `app/lib/features`, `app/lib/core`, and `app/lib/widgets` excludes relocated catalogs (`repo.app_widgetbook_catalog_location`).
- **`features/game/widgets/panels/`** — shared panel chrome and non-unit panels: fleet expansion row ([fleet_expansion_tile.dart](../../app/lib/features/game/widgets/panels/fleet_expansion_tile.dart)), pause menu, observe-mode sentinel, and shared [GamePanelMixin](../../app/lib/features/game/widgets/panels/game_panel_contract.dart) contract. Panel tree builders live in [`panels/tree_builders/`](../../app/lib/features/game/widgets/panels/tree_builders/) — military army tree ([military_tree_builder.dart](../../app/lib/features/game/widgets/panels/tree_builders/military_tree_builder.dart)), naval fleet tree ([naval_tree_builder.dart](../../app/lib/features/game/widgets/panels/tree_builders/naval_tree_builder.dart) with scope/rows/group `part`s), and fleet mission label helper ([fleet_mission_label.dart](../../app/lib/features/game/widgets/panels/tree_builders/fleet_mission_label.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/units/civilian/`** — civilian units panel library ([CivilianUnitsPanel](../../app/lib/features/game/widgets/units/civilian/civilian_units_panel.dart) with `part` files for resolution, row card, and unit row), and sort helpers ([civilian_units_sort.dart](../../app/lib/features/game/widgets/units/civilian/civilian_units_sort.dart)). Imports [GamePanelMixin](../../app/lib/features/game/widgets/panels/game_panel_contract.dart) from `panels/`.
- **`features/game/widgets/units/military/`** — military units panel library ([MilitaryUnitsPanel](../../app/lib/features/game/widgets/units/military/military_units_panel.dart) with detail-row `part`). Imports tree builders from `panels/tree_builders/` and [GamePanelMixin](../../app/lib/features/game/widgets/panels/game_panel_contract.dart) from `panels/`.
- **`features/game/widgets/units/naval/`** — naval units panel library ([NavalUnitsPanel](../../app/lib/features/game/widgets/units/naval/naval_units_panel.dart) with combine/home-transfer/dialog `part`s). Imports [fleet_expansion_tile.dart](../../app/lib/features/game/widgets/panels/fleet_expansion_tile.dart), tree builders from `panels/tree_builders/`, and [GamePanelMixin](../../app/lib/features/game/widgets/panels/game_panel_contract.dart) from `panels/`.
- **`features/game/widgets/units/shared/`** — reusable unit-panel scaffold widgets shared by civilian, military, and naval panels: base mixin ([base_units_panel.dart](../../app/lib/features/game/widgets/units/shared/base_units_panel.dart)), panel shell ([units_panel_shell.dart](../../app/lib/features/game/widgets/units/shared/units_panel_shell.dart)), sheet surface host ([units_panel_sheet_surface.dart](../../app/lib/features/game/widgets/units/shared/units_panel_sheet_surface.dart)), viewport constraints ([units_panel_viewport_constraints.dart](../../app/lib/features/game/widgets/units/shared/units_panel_viewport_constraints.dart)), entity card ([units_entity_card.dart](../../app/lib/features/game/widgets/units/shared/units_entity_card.dart)), action row ([units_entity_action_row.dart](../../app/lib/features/game/widgets/units/shared/units_entity_action_row.dart)), row chrome ([units_panel_row_chrome.dart](../../app/lib/features/game/widgets/units/shared/units_panel_row_chrome.dart)), region/location section headers, combine-header actions, and multi-selection controller. Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/dialogs/`** — standalone in-game modal dialogs: map display options ([game_map_options_dialog.dart](../../app/lib/features/game/widgets/dialogs/game_map_options_dialog.dart)), turn-start news digest ([turn_news_dialog.dart](../../app/lib/features/game/widgets/dialogs/turn_news_dialog.dart)), and read-only campaign parameters ([game_parameters_dialog.dart](../../app/lib/features/game/widgets/dialogs/game_parameters_dialog.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/diplomacy/`** — diplomacy panel library ([DiplomacyPanel](../../app/lib/features/game/widgets/diplomacy/diplomacy_panel.dart) with `part` files for body, chrome, mode bar, order actions, and row chrome), row model/builder ([diplomacy_panel_rows.dart](../../app/lib/features/game/widgets/diplomacy/diplomacy_panel_rows.dart) with standing-chips, builder, and power `part`s), grant/subsidy dialog ([diplomacy_dialogs.dart](../../app/lib/features/game/widgets/diplomacy/diplomacy_dialogs.dart)), grant/subsidy confirmation listener ([grant_or_subsidy_listener.dart](../../app/lib/features/game/widgets/diplomacy/grant_or_subsidy_listener.dart)), relative-power line widget ([relative_power_line.dart](../../app/lib/features/game/widgets/diplomacy/relative_power_line.dart)), FNV-1a hash constants for row keys ([fnv1a_hash_constants.dart](../../app/lib/features/game/widgets/diplomacy/fnv1a_hash_constants.dart)), and shared order-label helpers ([diplomacy_order_helpers.dart](../../app/lib/features/game/widgets/diplomacy/diplomacy_order_helpers.dart)). Imports [GamePanelMixin](../../app/lib/features/game/widgets/panels/game_panel_contract.dart) from `panels/`.
- **`features/game/widgets/production/`** — production panel library ([ProductionPanel](../../app/lib/features/game/widgets/production/production_panel.dart) with `part` files for Available and Allocation subpanels), recipe affordance helpers ([production_recipe_affordance.dart](../../app/lib/features/game/widgets/production/production_recipe_affordance.dart) — slider cap, `RecipeAffordance`, `computeRecipeAffordance`), allocation row ([production_allocation_row.dart](../../app/lib/features/game/widgets/production/production_allocation_row.dart) + chrome/buttons/mutations/repeat-timing helpers), labour section ([production_labour_section.dart](../../app/lib/features/game/widgets/production/production_labour_section.dart) + helpers), available commodity grid ([production_available_grid.dart](../../app/lib/features/game/widgets/production/production_available_grid.dart)), commodity breakdown dialog ([production_commodity_breakdown_dialog.dart](../../app/lib/features/game/widgets/production/production_commodity_breakdown_dialog.dart) with table `part`), and Widgetbook demo data ([production_panel_demo_data.dart](../../app/lib/features/game/widgets/production/production_panel_demo_data.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/technology/`** — technology panel library ([TechnologyPanel](../../app/lib/features/game/widgets/technology/technology_panel.dart) with slot-card widgets in [technology_panel_widgets.dart](../../app/lib/features/game/widgets/technology/technology_panel_widgets.dart)), order helpers and choose-tech dialog ([technology_panel_orders.dart](../../app/lib/features/game/widgets/technology/technology_panel_orders.dart)), slot funding toggles ([technology_slot_funding_toggles.dart](../../app/lib/features/game/widgets/technology/technology_slot_funding_toggles.dart)), per-slot turn preview ([research_slot_turn_preview_view.dart](../../app/lib/features/game/widgets/technology/research_slot_turn_preview_view.dart)), tech tree graph ([tech_tree_widget.dart](../../app/lib/features/game/widgets/technology/tech_tree_widget.dart) with nodes/legend `part`s), GP pennant row ([tech_gp_pennant_row.dart](../../app/lib/features/game/widgets/technology/tech_gp_pennant_row.dart)), researchers list dialog ([tech_researchers_list_dialog.dart](../../app/lib/features/game/widgets/technology/tech_researchers_list_dialog.dart)), and tech-effect summary lookup ([tech_effect_summary_lookup.dart](../../app/lib/features/game/widgets/technology/tech_effect_summary_lookup.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/province_overlay/`** — province and sea-zone detail overlay library ([ProvinceSeaZoneDetailOverlay](../../app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart) with `part` files for sections, tile section, content, economic/military sections, and designation), pending-order row helpers ([province_panel_pending_orders.dart](../../app/lib/features/game/widgets/province_overlay/province_panel_pending_orders.dart)), localized panel labels ([province_panel_labels.dart](../../app/lib/features/game/widgets/province_overlay/province_panel_labels.dart)), unit partition helper ([province_overlay_unit_partition.dart](../../app/lib/features/game/widgets/province_overlay/province_overlay_unit_partition.dart)), and Widgetbook demo data ([province_overlay_demo_data.dart](../../app/lib/features/game/widgets/province_overlay/province_overlay_demo_data.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/train/`** — train-at-capital dialog family: shared base ([train_dialog_base.dart](../../app/lib/features/game/widgets/train/train_dialog_base.dart)), chrome ([train_dialog_chrome.dart](../../app/lib/features/game/widgets/train/train_dialog_chrome.dart)), commodity-cost base ([train_commodity_cost_dialog_base.dart](../../app/lib/features/game/widgets/train/train_commodity_cost_dialog_base.dart)), unit helper ([train_unit_dialog_helper.dart](../../app/lib/features/game/widgets/train/train_unit_dialog_helper.dart)), and concrete civilian/military/naval dialogs ([train_civilians_dialog.dart](../../app/lib/features/game/widgets/train/train_civilians_dialog.dart), [train_military_dialog.dart](../../app/lib/features/game/widgets/train/train_military_dialog.dart), [train_naval_dialog.dart](../../app/lib/features/game/widgets/train/train_naval_dialog.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/unit_orders/`** — in-game unit order dialogs: shared move scaffold ([move_units_dialog_base.dart](../../app/lib/features/game/widgets/unit_orders/move_units_dialog_base.dart)), army/fleet move dialogs ([move_army_dialog.dart](../../app/lib/features/game/widgets/unit_orders/move_army_dialog.dart), [move_fleet_dialog.dart](../../app/lib/features/game/widgets/unit_orders/move_fleet_dialog.dart)), split scaffold ([split_entity_dialog.dart](../../app/lib/features/game/widgets/unit_orders/split_entity_dialog.dart)) with army/fleet variants ([split_army_dialog.dart](../../app/lib/features/game/widgets/unit_orders/split_army_dialog.dart), [split_fleet_dialog.dart](../../app/lib/features/game/widgets/unit_orders/split_fleet_dialog.dart)), and transfer-to-home-fleet dialog ([transfer_to_home_fleet_dialog.dart](../../app/lib/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/shell/`** — in-game shell chrome: play/observe context provider ([shell_player_context.dart](../../app/lib/features/game/widgets/shell/shell_player_context.dart) — `ShellPlayerContext`, `shellPlayerContextProvider`, `resolveShellPanelPlayerId`, `shellPanelsNotDefined`, `resolveCivilianMarkerOwnerIds`), Flame map viewport host ([region_map_game_viewport.dart](../../app/lib/features/game/widgets/shell/region_map_game_viewport.dart)), top bar ([game_top_bar.dart](../../app/lib/features/game/widgets/shell/game_top_bar.dart)), tab bar ([game_tab_bar.dart](../../app/lib/features/game/widgets/shell/game_tab_bar.dart)), players bar ([game_map_players_bar.dart](../../app/lib/features/game/widgets/shell/game_map_players_bar.dart)), players-bar toggle ([players_bar_toggle_button.dart](../../app/lib/features/game/widgets/shell/players_bar_toggle_button.dart)), turn-event feed ([player_turn_event_feed.dart](../../app/lib/features/game/widgets/shell/player_turn_event_feed.dart)), and observe-mode shell guard ([shell_player_guarded_body.dart](../../app/lib/features/game/widgets/shell/shell_player_guarded_body.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/screens/game/`** — in-game host screen library ([GameScreen](../../app/lib/features/game/screens/game/game_screen.dart) with `part` file for Flame-canvas fallback next-turn button) and shared map-shell test keys/constants ([game_screen_shared.dart](../../app/lib/features/game/screens/game/game_screen_shared.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/screens/diplomacy/`** — Diplomacy screen library ([DiplomacyScreen](../../app/lib/features/game/screens/diplomacy/diplomacy_screen.dart)) and detail route ([DiplomacyDetailScreen](../../app/lib/features/game/screens/diplomacy/diplomacy_detail_screen.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/screens/production/`** — Production screen library ([ProductionScreen](../../app/lib/features/game/screens/production/production_screen.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/screens/technology/`** — Technology screen library ([TechnologyScreen](../../app/lib/features/game/screens/technology/technology_screen.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/chrome/`** — Ct-* catalog widget implementations shared by in-game panels and dialogs: hover button mixin ([ct_hover_button.dart](../../app/lib/features/game/widgets/chrome/ct_hover_button.dart)), nine-patch button ([ct_nine_patch_button.dart](../../app/lib/features/game/widgets/chrome/ct_nine_patch_button.dart)), action/danger text buttons, dialog shell, panel, and circular locate button. Flame `GameWidget` embedding lives in `widgets/shell/region_map_game_viewport.dart` so this folder stays free of direct Flame imports in catalog widgets.
- **`features/game/widgets/dialogue/`** — narrative dialogue overlays and shared view chrome: [CtDialogueView](../../app/lib/features/game/widgets/dialogue/ct_dialogue_view.dart) + line/choice body parts, game-start intro ([game_start_intro_overlay.dart](../../app/lib/features/game/widgets/dialogue/game_start_intro_overlay.dart)), overture / intervention / call-to-arms overlays, tribe first-contact overlay + sync helper. Public imports use full package paths; no barrel re-export shim.
- **`features/game/screens/trade/`** — World Market trade screen library ([TradeScreen](../../app/lib/features/game/screens/trade/trade_screen.dart) with `part` files for Market tab body/rows and Deal Book ledger), plus shared Market-tab section callback factory ([trade_section_handlers.dart](../../app/lib/features/game/screens/trade/trade_section_handlers.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/screens/combat/`** — Quick Battle full-screen host ([QuickBattleScreen](../../app/lib/features/game/screens/combat/quick_battle_screen.dart)). Public imports use full package paths; no barrel re-export shim.
- **`features/game/widgets/combat/`** — Quick Battle modal and presentational widgets: combat mode choice ([combat_mode_choice_dialog.dart](../../app/lib/features/game/widgets/combat/combat_mode_choice_dialog.dart)), result summary ([quick_battle_result_dialog.dart](../../app/lib/features/game/widgets/combat/quick_battle_result_dialog.dart)), deployment grid ([quick_battle_deployment_view.dart](../../app/lib/features/game/widgets/combat/quick_battle_deployment_view.dart)), and CP action selector ([quick_battle_action_selector.dart](../../app/lib/features/game/widgets/combat/quick_battle_action_selector.dart)). Opened via `OpenDialogEvent` registrations in `AppEventHandlerScope`. Public imports use full package paths; no barrel re-export shim.
- **Colocated UI helpers (no `features/game/utils/` barrel):** technology helpers ([research_slot_preview.dart](../../app/lib/features/game/widgets/technology/research_slot_preview.dart), [tech_gp_researchers.dart](../../app/lib/features/game/widgets/technology/tech_gp_researchers.dart), [tech_ui_helpers.dart](../../app/lib/features/game/widgets/technology/tech_ui_helpers.dart)); production commodity labels ([commodity_ui_helpers.dart](../../app/lib/features/game/widgets/production/commodity_ui_helpers.dart)); unit-panel region labels ([region_labels.dart](../../app/lib/features/game/widgets/units/shared/region_labels.dart)); map locate tile keys ([map_location_resolver.dart](../../app/lib/features/game/flame/map_state/map_location_resolver.dart)); sea-zone display names ([sea_zone_name_resolver.dart](../../app/lib/features/game/widgets/province_overlay/sea_zone_name_resolver.dart)).

---

## Package list and responsibilities

Game logic ships as a set of one-way-dependent Dart packages under `packages/`. The former `colonizethis_logic` monolith has been split into per-domain packages plus a thin `colonizethis_logic` re-export core (Refs #3290); the five `src/ai/` planning files moved into `colonizethis_ai_contracts`.

**Foundational packages (no logic-domain deps):**

| Package | Contents | Internal package deps |
|---------|----------|------------------------|
| **colonizethis_models** | Data models, schemas, serialization (Game, Player, Orders, WorldState, Province, Unit, etc.). Stockpile, WorkerPool. | None |
| **colonizethis_data** | Constants, tech tree, **static map data**: (1) **region topology** (nodes: provinces, sea zones; links P<->P, P<->S; cross-region); (2) **tile maps** (per region). Ruleset/config (e.g. `rules/` for JSON later). Topology and tile map **formats** and loaders; topology/tile-map **describe** helpers. | None |
| **colonizethis_logger** | Shared logging seam (`CtLogger`, per-package log prefixes). | None |
| **colonizethis_map** | Topology and tile map **generation**, topology inference from tile map, tile map topology validation, and tile map **PNG visualization**. Implements TDD map generation algorithms; consumed by tools and loaders. | colonizethis_data |
| **colonizethis_save** | Save format, schema, migrations | colonizethis_models |

**Logic domain packages (extracted from the former `colonizethis_logic` monolith, Refs #3290):**

| Package | Contents | Internal package deps (beyond models/data/logger) |
|---------|----------|------------------------|
| **colonizethis_world** | World state, province lookup/traversal, connectivity, fog, game-world mutation helpers, event bus, shared utils. Foundation of the logic domain. | — |
| **colonizethis_combat** | Combat resolution. | colonizethis_world |
| **colonizethis_economy** | Extraction, production, stockpile, worker allocation, world market. | colonizethis_world |
| **colonizethis_diplomacy** | Diplomacy relations/resolution, dossier. | colonizethis_world, colonizethis_combat, colonizethis_economy |
| **colonizethis_orders** | Order engine, order validation (incl. diplomatic sub-validators), order suggestions, work-order handlers. | colonizethis_world, colonizethis_diplomacy, colonizethis_economy |
| **colonizethis_setup** | Game setup/creation, capital choice, hidden-agenda assignment. | colonizethis_world, colonizethis_diplomacy, colonizethis_map |
| **colonizethis_turn** | Turn-resolution orchestration, phase handlers, turn trace. The orchestrator — imported by no other logic-domain package. | colonizethis_world, colonizethis_combat, colonizethis_economy, colonizethis_diplomacy, colonizethis_orders |

**Core, contracts, and consumers:**

| Package | Contents | Internal package deps |
|---------|----------|------------------------|
| **colonizethis_logic** | Thin core + backward-compat surface: `src/constants.dart`, logging seam, `turn_to_year.dart`, cross-package DI providers (`di/logic_providers.dart`), the public re-export barrel (`colonizethis_logic.dart`), and narrow contract libraries (`ai_api.dart`, `order_suggestion_api.dart`, `debug_console_api.dart`). Re-exports the domain packages so existing consumers import `colonizethis_logic` unchanged. | colonizethis_world, _combat, _economy, _diplomacy, _setup, _orders, _turn, _map, _models, _data, _logger |
| **colonizethis_ai_contracts** | AI planning contract implementations moved out of logic: `ai_planner.dart`, `ai_control.dart`, `sim_game_ai.dart`, `simple_ai_heuristics.dart`, `full_ai_civilian_work_selection.dart`. **Not** depended on by `colonizethis_logic` core. | colonizethis_world, colonizethis_orders |
| **colonizethis_ai** | AI behavior, planning, personalities. | colonizethis_logic (narrow AI-facing contracts only: `order_suggestion_api.dart`, `ai_api.dart`), colonizethis_ai_contracts |
| **colonizethis_debug_console** | Debug-console command parsing/execution contracts and history state for in-game debug tooling. | colonizethis_logic (narrow debug-console contract only: `debug_console_api.dart`), colonizethis_models |

**Config consumers:** the logic-domain packages and colonizethis_ai consume resolved config; app receives config at game load. See [ruleset-config.md](ruleset-config.md). Flutter does not perform merge or file parsing.

**Rule:** No UI in shared packages. Game logic lives only in shared packages; app is shell, routing, and integration.

### Logic domain packages — canonical abstractions

The logic domain packages are organized around a small set of canonical abstractions that keep validation, suggestion, and resolution code thin and consistent across order types and phases. Refs #2560, #3290.

- **Mutation helpers (`colonizethis_world` `src/world/game_world_mutations.dart`, `colonizethis_turn` `src/turn/turn_pipeline_state.dart`).** Turn pipelines and order application mutate nested `Game` → `WorldState` → `TurnState` fields frequently. Call sites use **`Game.updateWorldState`**, **`WorldState.updateTurnState`**, and **`TurnPipelineState.updateWorldState`** instead of three-level `copyWith` chains.
- **Province traversal (`colonizethis_world` `src/world/province_traversal.dart`).** Dual-region province scans use **`forEachWorldRegion`** / **`traverseProvinces`** instead of duplicating old-world/new-world iteration in connectivity, fog, naval, and similar resolvers (see `SPEC/program/logic-dual-region-province-access.md` for the broader sanctioned dual-region access policy).
- **Diplomatic sub-validators (`colonizethis_orders` `src/orders/validators/diplomatic/`).** Type-specific diplomatic rules live in per-type factory functions backed by `DiplomaticSubValidator` helpers (`relationDiplomaticSubValidator`, `delegatedDiplomaticSubValidator`). The parent `DiplomaticOrderValidator` runs cross-cutting checks before dispatch. See [orders.md](orders.md) § Diplomatic sub-validators (implementation).
- **Work-order handler registry (`colonizethis_orders` `src/orders/work_handlers/work_order_handler_registry.dart`).** Work-order application uses a single `workOrderHandlersByTarget` map keyed by work target string (one `WorkOrderHandler` per target; standard multi-turn build targets share `StandardBuildWorkOrderHandler`). `orders_application_work_phase.dart` resolves handlers by target lookup only. See [orders.md](orders.md) § Implementation (structure, not extra rules).
- **Work suggestion pipeline (`colonizethis_orders` `src/orders/work_suggestion_pipeline.dart`).** Civilian work suggestion for Explorer, Worker, Spy, and Merchant unit types uses the shared `WorkSuggestionPipeline.run()` loop with per-type `candidatesProvider` callbacks. See [order-suggestions.md](order-suggestions.md) § Work suggestion pipeline (`WorkSuggestionPipeline`).
- **Work-tile candidacy (`colonizethis_orders` `src/orders/work_tile_candidacy/`).** Work-target tile prefiltering and UI tile-key highlight probing share `WorkTileCandidateIndex`; `work_tile_candidacy.dart` re-exports the index plus `getValidWorkOrderTileKeys*` / `rawCandidateTilesForWorkTarget` entry points. See [order-suggestions.md](order-suggestions.md) § Pre-filtering by work target type (Refs #3877).
- **Work-order target prechecks (`colonizethis_orders` `src/orders/validators/work_order_target_prechecks.dart`).** Territory and target-specific work-order gates (foreign-province, embassy, dev-exclusive, explorer-consulate-in-minor-tribe, etc.) register in `workOrderTargetPrechecks`; `WorkOrderValidator` delegates via `runWorkOrderTargetPrecheck` instead of inlining territory rules (Refs #3877).
- **Diplomatic suggestion modules (`colonizethis_orders` `src/orders/order_suggestion_diplomatic*.dart`).** `order_suggestion_diplomatic.dart` is thin orchestration only; per-order-type builders live in `order_suggestion_diplomatic_candidates.dart` (reusing `DiplomaticSubValidatorContext`), and per-target primary/independent acceptance loops live in `order_suggestion_diplomatic_pass.dart`. See [order-suggestions.md](order-suggestions.md) (Refs #3877).
- **Feedstock helpers (`colonizethis_orders` `src/orders/feedstock_common.dart`).** Feedstock id resolution and regiment counting for extraction targets and bootstrap cost share one module (no duplicated `allUnitsFromWorld` scans across the former split files) (Refs #3877).
- **Validation orchestration factory (`colonizethis_orders` `src/orders/order_validator_factory.dart`, `validator_bundle.dart`).** Full-pass validation (`order_engine_validation.dart`) and incremental candidate replay (`incremental_candidate_validator_replay.dart`) route per-order validator dispatch through the shared factory (Refs #3877).
- **Turn-phase handler registry (`colonizethis_turn` `src/turn/phases/`, `src/turn/turn_phase_handler_registry.dart`).** Each turn phase is implemented by a `TurnPhaseHandler` in `turn/phases/*.dart` (one phase per file, re-exported by `turn/phases.dart`). The canonical map is `TurnPhaseHandlerRegistry.defaults`; tests and callers may override individual phases via `TurnResolverConfig.phaseHandlerOverrides`. See [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § Phase handler registry.

The shared abstractions above are the canonical extension points: new validators, handlers, suggestion paths, and phases plug into these registries and helpers rather than introducing parallel `switch` dispatch or new copy-paste structures. Repo-lint rules (for example `repo.logic_diplomatic_sub_validator_size`, and `repo.logic_work_target_switch` for the work-order registry path) keep adapters bounded so the canonical shapes do not silently regress.

**Riverpod in packages:** Canonical `Provider`s for logic/map/AI seams live in optional `di.dart` libraries; see [dependency-injection.md](dependency-injection.md).

---

## Dependency direction

The logic-domain packages form a strict one-way DAG (Refs #3290); `colonizethis_turn` is the orchestrator at the top of the domain layer and is imported by no other domain package, while `colonizethis_world` is the shared foundation imported by all of them.

```
app
 └── colonizethis_logic, colonizethis_models, colonizethis_ai, colonizethis_data,
     colonizethis_save, colonizethis_debug_console

colonizethis_ai
 └── colonizethis_logic (narrow contracts), colonizethis_ai_contracts

colonizethis_debug_console
 └── colonizethis_logic, colonizethis_models

colonizethis_logic  (thin core + re-export barrel)
 └── colonizethis_world, colonizethis_combat, colonizethis_economy, colonizethis_diplomacy,
     colonizethis_setup, colonizethis_orders, colonizethis_turn, colonizethis_map

colonizethis_ai_contracts
 └── colonizethis_world, colonizethis_orders        (NOT depended on by colonizethis_logic)

colonizethis_turn
 └── colonizethis_world, colonizethis_combat, colonizethis_economy, colonizethis_diplomacy,
     colonizethis_orders

colonizethis_orders
 └── colonizethis_world, colonizethis_diplomacy, colonizethis_economy

colonizethis_setup
 └── colonizethis_world, colonizethis_diplomacy, colonizethis_map

colonizethis_diplomacy
 └── colonizethis_world, colonizethis_combat, colonizethis_economy

colonizethis_combat
 └── colonizethis_world

colonizethis_economy
 └── colonizethis_world

colonizethis_world
 └── colonizethis_models, colonizethis_data, colonizethis_logger

colonizethis_save
 └── colonizethis_models

colonizethis_map
 └── colonizethis_data

colonizethis_models   (no package deps)
colonizethis_data     (no package deps)
colonizethis_logger   (no package deps)
```

Neither `colonizethis_logic` nor any logic-domain package (`colonizethis_world`, `_combat`, `_economy`, `_diplomacy`, `_orders`, `_setup`, `_turn`) may depend on `colonizethis_ai` or `colonizethis_ai_contracts` in either `dependencies` or `dev_dependencies`; tests that exercise AI behavior belong in `colonizethis_ai/test`. The post-split graph contains no bidirectional edges between domain packages.

### Dependency boundary acceptance criteria

- **Given** package metadata for `colonizethis_logic`, **when** dependency analysis reads `dependencies` and `dev_dependencies`, **then** no `colonizethis_ai` entry exists.
- **Given** `colonizethis_ai` imports logic interfaces, **when** static analysis inspects imports under `packages/colonizethis_ai/lib`, **then** imports use narrow logic contract libraries (`order_suggestion_api.dart`, `ai_api.dart`) and do not import `package:colonizethis_logic/colonizethis_logic.dart`.
- **Given** the main logic public barrel `packages/colonizethis_logic/lib/colonizethis_logic.dart`, **when** static analysis inspects exported libraries, **then** no `src/ai/*` export is present and no `src/setup/hidden_agenda_assignment.dart` export is present; AI internals and hidden-agenda setup helpers stay outside the broad logic export surface.
- **Given** Dart source under `app/lib` except `app/lib/config/app_assets.dart` and `app/lib/config/app_constants.dart`, **when** static analysis inspects string literals, **then** direct asset path literals matching `assets/...` or `packages/<pkg>/assets/...` are rejected and diagnostics include file, line, and reason.
- **Given** an app runtime asset reference in `app/lib`, **when** the code compiles, **then** the reference uses root-relative path constants in `app/lib/config/app_constants.dart` (re-exported from `app/lib/config/app_assets.dart`) and/or path builders such as `terrainTileAssetPath` in `app/lib/config/app_assets.dart`.
- **Given** Dart source under `app/`, `packages/`, and `tool/`, **when** static analysis inspects executable AST string literals, **then** raw literals equal to canonical tech IDs are rejected outside canonical declaration sources, generated outputs skipped as whole paths by the identifier-literal scan contract, and approved fixture or test-data paths, with **no** keyed per-symbol waivers (see `SPEC/program/repo-lint.md` — policy distinguishes scope-only wiring from violation allowlists).
- **Given** the tech-ID convention gate reports a violation, **when** a developer inspects the output, **then** each violation includes file path, line, column, and the offending tech ID literal for direct remediation.
- **Given** Dart source under `app/`, `packages/`, and `tool/`, **when** static analysis inspects executable AST string literals, **then** raw literals equal to canonical work target IDs are rejected outside the canonical work-target declaration file, whole-file scope skips for generated or catalog surfaces documented in `tool/check_work_target_constants.dart`, and approved fixture paths, with **no** keyed per-symbol waivers.
- **Given** the work-target convention gate reports a violation, **when** a developer inspects the output, **then** each violation includes file path, line, column, and the offending work target literal with a suggested `kWorkTarget*` constant when available.
- **Given** Dart source under `app/`, `packages/`, and `tool/`, **when** static analysis inspects executable AST string literals, **then** raw literals equal to canonical civilian unit type ids (`Explorer`, `Builder`, `Engineer`, `Spy`, `Merchant`, `Rail Builder` per `SPEC/game/civilian-units.md`) are rejected outside `packages/colonizethis_models/lib/src/civilian_unit_type_ids.dart`, approved fixture/test-data paths, and the single whole-file scope skip for `packages/colonizethis_data/lib/src/ai_personality_config.dart` (personality display strings that may collide with civilian spellings), with **no** keyed per-symbol waivers.
- **Given** the civilian unit type convention gate reports a violation, **when** a developer inspects the output, **then** each violation includes file path, line, column, and the offending literal with a suggested `kUnitType*` constant when available.

### Automated guard gate (CI)

The repository enforces this boundary in CI via:

- `dart run tool/ct_repo_lint.dart` (Quality workflow), including rules `repo.logic_ai_decoupling`, `repo.app_lib_no_broad_suggest_work_orders`, `repo.asset_path_constants`, `repo.tech_id_constants`, `repo.work_target_constants`, and `repo.civilian_unit_type_constants` (see `tool/ct_repo_lint_manifest.yaml` and `SPEC/program/repo-lint.md`).
- `tool/check_logic_ai_decoupling.sh`, `tool/check_asset_path_constants.dart`, and the other `tool/check_*` entrypoints invoked by repo lint.
- `.github/workflows/quality.yml` steps that run unit tests for individual convention checkers (e.g. `test/check_asset_path_constants_test.dart`, `test/check_work_target_constants_test.dart`, …) so checker logic stays covered in CI.

Guard behavior:

- Fails if `packages/colonizethis_logic/pubspec.yaml` declares `colonizethis_ai` under `dependencies` or `dev_dependencies`.
- Fails if `packages/colonizethis_ai/lib/**` imports `package:colonizethis_logic/colonizethis_logic.dart`.
- Fails if `packages/colonizethis_ai/lib/**` imports logic from any path other than `ai_api.dart` or `order_suggestion_api.dart`.
- Fails if `packages/colonizethis_logic/test/**` imports `package:colonizethis_ai/...`.
- Fails if `packages/colonizethis_logic/lib/colonizethis_logic.dart` exports any `src/ai/*` library.
- Fails if `packages/colonizethis_logic/lib/colonizethis_logic.dart` exports `src/setup/hidden_agenda_assignment.dart`.
- Fails if `app/lib/**` contains direct `assets/...` or `packages/<pkg>/assets/...` string literals outside `app/lib/config/app_assets.dart` and `app/lib/config/app_constants.dart`.
- Fails if executable `StringLiteral` AST nodes equal to canonical tech IDs appear outside canonical declaration sources, generated outputs skipped as whole paths by the scan contract, and approved fixture/test-data paths.
- Fails if executable `StringLiteral` AST nodes equal to canonical work target IDs appear outside `packages/colonizethis_logic/lib/src/constants.dart`, approved fixture/test-data paths, and whole-file scope skips for generated or catalog surfaces encoded in `tool/check_work_target_constants.dart` (not keyed per-symbol waivers).
- In PR CI, the tech-ID guard may scan only changed Dart files for faster feedback; if PR diff context is unavailable, it falls back to a full repository scan with the same violation rules.
- In PR CI, the work-target guard may scan only changed Dart files for faster feedback; if PR diff context is unavailable, it falls back to a full repository scan with the same violation rules.
- Fails if executable `StringLiteral` AST nodes equal to canonical civilian unit type ids appear outside `packages/colonizethis_models/lib/src/civilian_unit_type_ids.dart`, approved fixture/test-data paths, and the whole-file scope skip set in `tool/check_civilian_unit_type_constants.dart` (see acceptance criteria above).
- In PR CI, the civilian unit type guard may scan only changed Dart files for faster feedback; if PR diff context is unavailable, it falls back to a full repository scan with the same violation rules.

Civilian unit type guard remediation:

- Add or reuse `kUnitType*` constants in `packages/colonizethis_models/lib/src/civilian_unit_type_ids.dart` (also re-exported from `packages/colonizethis_logic/lib/src/constants.dart` for logic consumers).
- Replace direct string literals in executable code with those constants; extend whole-file scope skips only with SPEC updates and issue tracking—prefer constants and refactors over new waivers.

Asset-path guard remediation:

- Add new root-relative asset path constants in `app/lib/config/app_constants.dart`; add or extend path builders in `app/lib/config/app_assets.dart` (which re-exports the constants library).
- Replace direct string literals in `app/lib/**` with those constants/helpers.
- Keep exclusions explicit and minimal; whole-file scope skips for asset path literals are `app/lib/config/app_assets.dart` and `app/lib/config/app_constants.dart`.

---

## Pub workspace toolchain

Dart/Flutter pin, `pub.dev` advisories expectations, and intentional “not at Latest” dependency caps (until upstream unblocks) are documented in **[pub-workspace-toolchain.md](pub-workspace-toolchain.md)** (with manual audit driver in **[workspace-outdated-audit.md](workspace-outdated-audit.md)**). See **GitHub #2073** for the rolling upgrade issue.

---

## Flutter app `lib/` structure (TDD 15)

Structure under `app/lib/`:

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── constants.dart
│   ├── routes.dart
│   └── themes.dart
├── core/
│   ├── models/
│   ├── services/
│   └── utils/
├── features/
│   ├── auth/
│   ├── game/
│   │   ├── flame/       # Flame components: map, battle, HUD (game canvas)
│   │   ├── map/
│   │   ├── orders/
│   │   ├── combat/
│   │   └── widgets/
│   ├── multiplayer/
│   ├── tutorial/
│   └── settings/
├── providers/
└── widgets/
```

Flame owns game canvas and in-game pixel-art UI; Flutter owns app shell, routes, and list/form screens. Communication only via state (Riverpod) and callbacks.

### App providers — recoverable failures (home fleet cargo)

- **Given** `currentGameProvider` holds a game and `homeFleetCargoSummaryProvider` runs the overseas extraction path, **when** `GameService.getMapData` or downstream computation throws, **then** the provider logs the failure at **warn** or higher with `error` and `stackTrace`, returns capacity from the live game state, sets used cargo to `0`, and sets `HomeFleetCargoSummary.isCargoUsedReliable` to **false** so the map HUD does not present `used` as authoritative (display uses `—` for the used value).
- **Given** map data is simply missing for the current game id (no throw), **when** the provider evaluates, **then** it returns used `0` with `isCargoUsedReliable` **true** (expected empty state, not a computation failure).

**Rationale:** GitHub #1531; SPEC/program/logging — avoid silent `catch` in providers; align with core logging principles.

### App `GameService` — `getMapData` and in-memory map cache

- **Given** a `GameService` instance has already populated its in-memory map cache for `gameId` (for example after `loadGame`, `createNewGame`, or an earlier `getMapData` that loaded map data from storage), **when** the app calls `getMapData(gameId)` again, **then** the service returns the cached topology and tile maps **without** invoking `GameSaveAdapter.load` for that call (no redundant read of the game JSON from Hive solely to re-check existence). **Rationale:** GitHub #1560; avoids save-adapter info spam on UI hot paths (map pan/zoom rebuilds).
- **Given** no in-memory map cache entry exists for `gameId`, **when** `getMapData(gameId)` runs, **then** the service follows the usual save/load checks: it returns `null` when the game key is missing or the game JSON does not load, and otherwise returns map data from storage or cache per [save-load.md](save-load.md).
