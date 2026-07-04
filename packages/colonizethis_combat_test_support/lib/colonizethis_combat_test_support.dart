/// Shared combat test fixtures and table-driven scenario records for
/// `colonizethis_combat` and sibling test suites.
///
/// Consolidates package-local `*_test_support.dart` copies and imperative
/// scenario wiring into one canonical location (Refs #3865).
library colonizethis_combat_test_support;

export 'src/effective_strength_scenarios.dart';
export 'src/military_strength_scenarios.dart';
export 'src/military_strength_test_support.dart';
