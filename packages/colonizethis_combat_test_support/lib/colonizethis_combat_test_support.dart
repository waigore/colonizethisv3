/// Shared combat test fixtures and table-driven scenario records for
/// `colonizethis_combat` and sibling test suites.
///
/// Consolidates package-local `*_test_support.dart` copies and imperative
/// scenario wiring into one canonical location (Refs #3865).
library colonizethis_combat_test_support;

export 'src/scenario_runner.dart';
export 'src/effective_strength_scenarios.dart';
export 'src/military_strength_scenarios.dart';
export 'src/military_strength_test_support.dart';
export 'src/quick_battle_action_modifiers_scenarios.dart';
export 'src/quick_battle_emplaced_guns_scenarios.dart';
export 'src/quick_battle_emplaced_guns_test_support.dart';
export 'src/quick_battle_input_test_support.dart';
export 'src/quick_battle_resolver_scenarios.dart';
export 'src/quick_battle_siege_pipeline_test_support.dart';
export 'src/quick_battle_siege_scenarios.dart';
export 'src/naval_combat_test_support.dart';
export 'src/naval_combat_resolver_scenarios.dart';
export 'src/naval_combat_resolution_scenarios.dart';
export 'src/naval_combat_privateering_scenarios.dart';
export 'src/quick_battle_build_siege_scenarios.dart';
export 'src/quick_battle_build_test_support.dart';
export 'src/quick_battle_perf_invariants_scenarios.dart';
export 'src/conflict_detection_test_support.dart';
export 'src/conflict_detection_scenarios.dart';
export 'src/combat_resolver_test_support.dart';
export 'src/combat_resolver_engagement_scenarios.dart';
export 'src/combat_resolver_limits_scenarios.dart';
export 'src/combat_resolver_part2_scenarios.dart';
export 'src/combat_resolver_probabilistic_scenarios.dart';
export 'src/combat_resolver_spy_civilian_scenarios.dart';
export 'src/battle_general_assignment_scenarios.dart';
export 'src/battle_general_assignment_bind_phase_scenarios.dart';
export 'src/combat_mode_selection_scenarios.dart';
export 'src/combat_loss_profile_scenarios.dart';
export 'src/combat_rng_scenarios.dart';
export 'src/military_attack_economy_scenarios.dart';
export 'src/combat_resolver_province_owner_transfer_scenarios.dart';
export 'src/conflict_detection_army_index_scenarios.dart';
export 'src/pre_combat_index_scenarios.dart';
export 'src/quick_battle_input_builder_scenarios.dart';
export 'src/quick_battle_resolver_apply_spy_scenarios.dart';
export 'src/unopposed_province_capture_scenarios.dart';
