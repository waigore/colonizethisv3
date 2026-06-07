/// Game rules, turn resolution, victory, validation. SPEC/program/turn-resolution.
library colonizethis_logic;

// Root
export 'package:colonizethis_models/colonizethis_models.dart'
    show AssignedRecipe;
export 'package:colonizethis_world/colonizethis_world.dart';
export 'order_suggestion_api.dart';
export 'src/constants.dart';
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
export 'src/setup/minor_tribe_starting_development.dart';
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
export 'src/turn/pending_treasury_costs.dart';
export 'src/turn/research_resolver.dart';
export 'src/turn/turn_resolution_result.dart';
export 'src/turn/turn_resolver.dart';
export 'src/turn/turn_news_digest.dart';

// Combat
export 'package:colonizethis_combat/colonizethis_combat.dart';

// Economy
export 'src/economy/build_cost.dart';
export 'src/economy/economy_consumption.dart';
export 'src/economy/economy_extraction.dart';
export 'src/economy/economy_production.dart';
export 'src/economy/economy_preview_stockpile_phase.dart';
export 'src/economy/economy_riches_to_treasury.dart';
export 'src/economy/non_gp_extraction.dart';
export 'src/economy/resource_extractor.dart';
export 'src/economy/sea_transport.dart';
export 'src/economy/worker_action_cost.dart';
export 'src/economy/worker_economy.dart';
export 'src/economy/world_market/deal_matcher.dart';
export 'src/economy/world_market/first_right_credits.dart';
export 'src/economy/world_market/first_right_profit.dart';
export 'src/economy/world_market/lock_recovery_minor_bids.dart';
export 'src/economy/world_market/price_discovery.dart';
export 'src/economy/world_market/purchased_tile_index.dart';
export 'src/economy/world_market/sellable_quantity.dart';
export 'src/economy/world_market/trade_order_suggester.dart';
export 'src/economy/world_market/trade_order_validator.dart';
export 'src/economy/world_market/treasury_bid_budget.dart';

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
