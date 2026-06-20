/// Deterministic AI planning heuristics extracted from `colonizethis_logic`.
///
/// Owns the `src/ai/` file set (simple/full civilian work selection, order
/// generation, sim-game default AI). Depends on the logic domain packages it
/// plans against (`colonizethis_world`, `colonizethis_orders`) but **not** on
/// the thin `colonizethis_logic` core, and is consumed by `colonizethis_ai`
/// and the `ctdev` sim tooling (Refs #3290 C4).
///
/// The barrel re-exports the full public surface of the AI planning libraries;
/// consumers that want a narrow surface (e.g. `colonizethis_ai`) apply their own
/// `show` clause at the re-export site.
library colonizethis_ai_contracts;

export 'src/ai/ai_planner.dart';
export 'src/ai/full_ai_civilian_work_ow_feedstock_localization.dart';
export 'src/ai/full_ai_civilian_work_selection.dart';
export 'src/ai/sim_game_ai.dart';
export 'src/ai/simple_ai_heuristics.dart';
