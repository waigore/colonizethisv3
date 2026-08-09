// Shared score-boost constants for economy planning (root + labour).
// Extracted to avoid an economy_planner_labour.dart <-> economy_planner.dart
// import cycle (Refs #4079 Slice A).

/// Recipe-score boost for outputs that supply a missing cheapest-regiment
/// build input when the EXPAND regiment-rebuild directive is active
/// (Refs #2847 H8 production companion).
const double kRegimentBuildInputProductionScoreBoost = 50.0;

/// Recipe-score boost an **affluent supplier** applies to a domestically
/// produced improvement input (e.g. `castIron`) that a *peer* lock-recovery
/// seller needs but the world market structurally cannot supply (Refs #2847
/// H8-supply castIron source). Deliberately **small** — far below the
/// shortage-driven score of the supplier's own essential recipes
/// (`kShortageWeight * kShortageThreshold == 16`) — so the supplier only
/// converts **leftover** labour/feedstock into a releasable surplus and never
/// starves its own conquest economy. This keeps the +6 OW baseline for the
/// healthy GPs (gp1/gp2) safe by construction. Planner-internal (not a new
/// `ai_victory_config.dart` constant).
const double kSupplierBuildInputReleaseProductionScoreBoost = 5.0;
