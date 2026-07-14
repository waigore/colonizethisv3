/// Historical S7-D / S7-T diagnostic findings for the seed-42 observer
/// conquest campaign (Refs #2847 / #2924 / #3967 / #3972).
///
/// Moved out of `seed42_observer_conquest_s7d_diagnostic_test.dart` so that
/// file stays a thin campaign runner + assertion harness. Re-run the
/// skipped diagnostic with `dart test --run-skipped` when refreshing.
///
/// Topic modules (Phase 5 / Refs #3972):
/// - `s7d_findings_geography.dart` — peer-war lock / H1–H4 geography
/// - `s7d_findings_feedstock_extraction.dart` — H8 feedstock-stage split
/// - `s7d_findings_feedstock_castiron.dart` — castIron / fabric / labour
/// - `s7d_findings_lock_recovery.dart` — #2924 lock-recovery + labour wall
///
/// ## How to refresh
///
/// Skipped by default (long-running, ~4 minutes on the project
/// reference host). Run manually with:
///
/// ```
/// (cd packages/colonizethis_ai && dart test \
///     test/seed42_observer_conquest_s7d_diagnostic_test.dart \
///     --run-skipped)
/// ```
///
/// and copy the `S7D_DIAGNOSTIC_JSON_*`-delimited block into a fresh
/// comment on issue #2847 if the diagnostic surface shifts after a
/// tuning slice lands.
///
library;

export 's7d_findings_feedstock_castiron.dart';
export 's7d_findings_feedstock_extraction.dart';
export 's7d_findings_geography.dart';
export 's7d_findings_lock_recovery.dart';

/// Anchor so the findings library is a valid Dart compilation unit.
typedef Seed42S7dDiagnosticFindingsAnchor = void;
