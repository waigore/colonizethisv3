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

// Turn (Refs #3290 C3 — colonizethis_turn package; re-exported for backward
// compat). The turn barrel also re-exports the order-effects dry-run projector
// (`projectOrderEffects`), which runs the turn resolver and now lives in the
// turn package.
export 'package:colonizethis_turn/colonizethis_turn.dart';

// Combat
export 'package:colonizethis_combat/colonizethis_combat.dart';

// Economy
export 'package:colonizethis_economy/colonizethis_economy.dart';

// Orders (Refs #3290 — colonizethis_orders package; re-exported for backward compat)
export 'package:colonizethis_orders/colonizethis_orders.dart';
export 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
// `validators/work_order_cost_calculator.dart` is now published by the
// `colonizethis_orders` barrel (Refs #3393 Phase 1 `turn → orders` slice), so it
// is re-exported transitively above; the prior deep re-export here was redundant.
export 'package:colonizethis_orders/src/orders/order_suggestion.dart'
    show
        AvailableWorkTargetsForUnit,
        getAvailableWorkTargetsForUnit,
        getValidWorkOrderTileKeys,
        getValidWorkOrderTileKeysWithVisibility,
        incrementalCandidateValidatorBuildCountForTests,
        orderSuggestionWorkOrderAcceptanceProbeCountForTests,
        resetIncrementalCandidateValidatorBuildCountForTests,
        setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests;
export 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
export 'package:colonizethis_orders/src/orders/unit_type_helpers.dart'
    show devExclusiveReservedTileKeysForPlayer;

// Diplomacy
export 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
export 'package:colonizethis_diplomacy/src/diplomacy/break_alliance_resolver.dart'
    show applyVoluntaryAllianceBreak;
export 'package:colonizethis_diplomacy/src/diplomacy/alliance_break_cooldown.dart'
    show isAllianceBreakCooldownActive, kAllianceBreakCooldownRejectionReason;

// Dossier (evidence rules, event dialogue)
export 'package:colonizethis_diplomacy/src/dossier/evidence_rules.dart';
export 'package:colonizethis_diplomacy/src/dossier/event_dialogue.dart';
