/// Game rules, turn resolution, victory, validation. SPEC/program/turn-resolution.
library colonizethis_logic;

// Root
export 'package:colonizethis_models/colonizethis_models.dart'
    show AssignedRecipe;
export 'order_suggestion_api.dart';
export 'src/constants.dart';
export 'src/logic_validation_exception.dart';
export 'src/event_bus/game_event_bus.dart';
export 'src/game_events.dart';
export 'src/turn_to_year.dart';

// Setup — GitHub #2201: these setup/dossier/world lines stay public for package
// tests and integrators; an app/ai usage audit found no direct consumers, but
// removing them would force broad `src/` imports in tests without shrinking
// runtime surface meaningfully.

// Setup
export 'src/setup/capital_choice.dart';
export 'src/setup/game_setup.dart';
export 'src/setup/setup_validation_exception.dart';
export 'src/setup/gp_old_world_resource_redistribution.dart';
export 'src/setup/gp_old_world_terrain_redistribution.dart';
export 'src/setup/gp_starting_grain.dart';
export 'src/setup/town_capital_occupancy.dart';
export 'src/setup/effective_setup_seed.dart';
export 'src/setup/init_game_orchestrator.dart';
export 'src/setup/warp_zone_generator.dart';
export 'src/setup/province_assignment.dart';
export 'src/setup/gp_land_connectivity_repair.dart';
export 'src/setup/province_name_fallback.dart';
export 'src/setup/setup_exceptions.dart';

// Turn
export 'src/turn/economy_debt_rules.dart';
export 'src/turn/research_resolver.dart';
export 'src/turn/trace/turn_trace_contracts.dart';
export 'src/turn/trace/turn_trace_file_exporter.dart';
export 'src/turn/trace/turn_trace_runtime.dart';
export 'src/turn/turn_resolution_result.dart';
export 'src/turn/turn_resolver.dart';
export 'src/turn/turn_news_digest.dart';

// Combat
export 'src/combat/battle_general_assignment.dart';
export 'src/combat/combat_mode_selection.dart';
export 'src/combat/combat_resolver.dart';
export 'src/combat/combat_resolver_probabilistic.dart';
export 'src/combat/conflict_detection.dart';
export 'src/combat/military_strength.dart';
export 'src/combat/naval_combat_resolver.dart';
export 'src/combat/quick_battle_input_builder.dart';
export 'src/combat/quick_battle_resolver.dart';

// Economy
export 'src/economy/build_cost.dart';
export 'src/economy/economy_consumption.dart';
export 'src/economy/economy_extraction.dart';
export 'src/economy/economy_production.dart';
export 'src/economy/economy_preview_stockpile_phase.dart';
export 'src/economy/economy_riches_to_treasury.dart';
export 'src/economy/resource_extractor.dart';
export 'src/economy/sea_transport.dart';
export 'src/economy/worker_action_cost.dart';
export 'src/economy/worker_economy.dart';
export 'src/economy/world_market/first_right_profit.dart';

// Orders
export 'src/orders/orders.dart';
export 'src/orders/civilian_projected_tile.dart';
export 'src/orders/validators/work_order_cost_calculator.dart';
export 'src/orders/order_suggestion.dart'
    show
        AvailableWorkTargetsForUnit,
        getAvailableWorkTargetsForUnit,
        getValidWorkOrderTileKeys,
        getValidWorkOrderTileKeysWithVisibility,
        incrementalCandidateValidatorBuildCountForTests,
        orderSuggestionWorkOrderAcceptanceProbeCountForTests,
        resetIncrementalCandidateValidatorBuildCountForTests,
        setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests;
export 'src/orders/per_player_work_target_selection_cache.dart';
export 'src/orders/unit_type_helpers.dart'
    show devExclusiveReservedTileKeysForPlayer;

// Diplomacy
export 'src/diplomacy/diplomacy_resolver.dart';

// Dossier (evidence rules, event dialogue)
export 'src/dossier/evidence_rules.dart';
export 'src/dossier/event_dialogue.dart';

// World
export 'src/world/army_commands.dart';
export 'src/world/army_ids.dart';
export 'src/world/army_migration.dart';
export 'src/world/army_movement.dart';
export 'src/world/capital_reassignment_fatal.dart';
export 'src/world/capital_and_gp_fall.dart';
export 'src/world/connectivity_resolver.dart';
export 'src/world/unit_lookup.dart';
export 'src/world/minor_military_parity.dart';
export 'src/world/movement.dart';
export 'src/world/naval.dart';
export 'src/world/naval_fleet_commands.dart';
export 'src/world/fog_resolution.dart'
    show
        applyCoastalSeaZoneFullVisibility,
        applyCoastalSeaZoneFullVisibilityForProvinceTargets;
export 'src/world/player_state_pipeline.dart';
export 'src/world/player_view.dart';
export 'src/world/province_ownership_transfer.dart';
export 'src/world/province_lookup.dart';
export 'src/world/sea_zone_identity.dart';
export 'src/world/tile_control.dart';
