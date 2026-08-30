/// Game rules, turn resolution, victory, validation. SPEC/program/turn-resolution.
library colonizethis_logic;

// Root
export 'package:colonizethis_models/colonizethis_models.dart'
    show AssignedRecipe;
export 'package:colonizethis_world/colonizethis_world.dart';
export 'order_suggestion_api.dart';
export 'industry_counsel_api.dart';
export 'src/constants.dart';
export 'src/civilians/civilians_missing_work_orders.dart';
export 'src/civilians/spy_relocate_intel.dart';
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

// Orders (Refs #3290 — colonizethis_orders package; re-exported for backward
// compat). Domain barrel already publishes civilian_projected_tile,
// per_player_work_target_selection_cache, order_suggestion, and unit_type_helpers
// (Refs #4660 contract barrel SoT).
export 'package:colonizethis_orders/colonizethis_orders.dart';

// Diplomacy + dossier (Refs #4660 — barrel SoT; was deep `src/` re-exports).
export 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
