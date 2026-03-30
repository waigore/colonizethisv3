/// Game rules, turn resolution, victory, validation. SPEC/program/turn-resolution.
library colonizethis_logic;

// Root
export 'src/constants.dart';
export 'src/event_bus/game_event_bus.dart';
export 'src/game_events.dart';
export 'src/turn_to_year.dart';

// Setup
export 'src/setup/capital_choice.dart';
export 'src/setup/game_setup.dart';
export 'src/setup/gp_starting_grain.dart';
export 'src/setup/town_capital_occupancy.dart';
export 'src/setup/init_game_orchestrator.dart';
export 'src/setup/warp_zone_generator.dart';
export 'src/setup/province_assignment.dart';
export 'src/setup/gp_land_connectivity_repair.dart';
export 'src/setup/province_name_fallback.dart';

// Turn
export 'src/turn/research_resolver.dart';
export 'src/turn/turn_resolution_result.dart';
export 'src/turn/turn_resolver.dart';

// Combat
export 'src/combat/battle_general_assignment.dart';
export 'src/combat/combat_mode_selection.dart';
export 'src/combat/leader_bonus_helpers.dart' show fallbackGeneralMedalsFromLeader;
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
export 'src/economy/economy_riches_to_treasury.dart';
export 'src/economy/resource_extractor.dart';
export 'src/economy/sea_transport.dart';
export 'src/economy/worker_economy.dart';

// Orders
export 'src/orders/order_engine.dart';
export 'src/orders/order_merge.dart';
export 'src/orders/projected_effects.dart';
export 'src/orders/order_projections.dart';
export 'src/orders/order_suggestion.dart';
export 'src/orders/order_suggestion.dart'
    show getValidWorkOrderTileKeys, getValidWorkOrderTileKeysWithVisibility;
export 'src/orders/order_suggestion_api_impl.dart';
export 'src/orders/order_visibility.dart';
export 'src/orders/draft_orders_mutations.dart';
export 'src/orders/orders_application.dart';
export 'src/orders/unit_type_helpers.dart' show
    devExclusiveReservedTileKeysForPlayer,
    devExclusiveTilesFromWorld,
    isDevExclusiveUnitType,
    isDevExclusiveWorkTarget;

// Diplomacy
export 'src/diplomacy/diplomacy_resolver.dart';

// Dossier (evidence rules, event dialogue)
export 'src/dossier/evidence_rules.dart';
export 'src/dossier/event_dialogue.dart';

// AI
export 'src/ai/ai_planner.dart';
export 'src/ai/ai_control.dart';
export 'src/ai/sim_game_ai.dart';
export 'src/ai/simple_ai_heuristics.dart';

// World
export 'src/world/capital_reassignment_fatal.dart';
export 'src/world/connectivity_resolver.dart';
export 'src/world/unit_lookup.dart';
export 'src/world/minor_military_parity.dart';
export 'src/world/movement.dart';
export 'src/world/naval.dart';
export 'src/world/player_view.dart';
export 'src/world/province_lookup.dart';
export 'src/world/tile_control.dart';
