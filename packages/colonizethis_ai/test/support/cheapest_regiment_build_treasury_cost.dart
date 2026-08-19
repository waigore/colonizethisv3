/// Test-support re-export of the AI cheapest-regiment treasury gate.
///
/// Observer campaigns must not import `lib/src/` for this helper (Refs #4530
/// AC7). The public barrel does not export it because
/// `colonizethis_data.cheapestRegimentBuildTreasuryCost` would clash in files
/// that import both packages.
export 'package:colonizethis_ai/src/planning/expand_phase_planner_economy.dart'
    show cheapestRegimentBuildTreasuryCost;
