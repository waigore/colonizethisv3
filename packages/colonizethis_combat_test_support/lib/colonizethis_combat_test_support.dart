/// Shared combat test fixtures and table-driven scenario records for
/// `colonizethis_combat` and sibling test suites.
///
/// Consolidates package-local `*_test_support.dart` copies and imperative
/// scenario wiring into one canonical location (Refs #3865).
library colonizethis_combat_test_support;

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
