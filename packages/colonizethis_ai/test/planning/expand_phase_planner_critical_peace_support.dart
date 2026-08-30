// Shared fixtures for `expand_phase_planner_critical_peace_*` pins.

/// Generates a list of [count] OW province ids belonging to [factionId]
/// (used to set a deterministic lead).
List<String> criticalPeaceRivalProvinces(String factionId, int count) =>
    <String>[for (var i = 1; i <= count; i++) 'oldWorld|${factionId}_$i'];

const String criticalPeaceGpStronger = 'gp_stronger';
const String criticalPeaceGpThird = 'gp_third';
const String criticalPeaceGpFourth = 'gp_fourth';
const String criticalPeaceMinor1 = 'minor1';
const String criticalPeaceTribe1 = 'tribe1';
