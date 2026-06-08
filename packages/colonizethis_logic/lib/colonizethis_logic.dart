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

// Setup (Refs #3290 — colonizethis_setup package; re-exported for backward compat)
export 'package:colonizethis_setup/colonizethis_setup.dart';

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
export 'package:colonizethis_economy/colonizethis_economy.dart';

// Orders
export 'src/orders/orders.dart';
// Order-effects dry-run projector (concrete impl lives in the neutral core
// `projections/` module because it runs the turn resolver; the orders barrel
// only exposes the injectable typedef + ProjectedEffects value type). Refs #3290 C2.
export 'src/projections/order_projections.dart';
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
export 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';

// Dossier (evidence rules, event dialogue)
export 'package:colonizethis_diplomacy/src/dossier/evidence_rules.dart';
export 'package:colonizethis_diplomacy/src/dossier/event_dialogue.dart';
