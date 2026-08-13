/// Pins the snapshot-driven bundled-Explore diagnostic surface of
/// [e2eBundledExploreRejectionDiagnostics]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// The fleet-reach test's final guard
/// (`new_game_fleet_reaches_new_world_e2e_test.dart` line ~408) calls this
/// helper to build the multi-line diagnostic embedded in the bundled-Explore
/// failure `fail()` message. The fail-message text is part of the
/// observable contract (it is grep-able from CI logs by the
/// `'No ctE2eNavalPanelSnapshot available for diagnostics.'` and `'diag:'`
/// prefixes) so a silent rename, line-order swap, or accidental
/// fail-open ("always emit the empty string") here would either:
///
///   - Hide the failing fleet-reach `availableWorkTargets` / `suggestedExplore`
///     details under a generic `fail()` message and erase the per-province
///     `workReason` / `moveReason` lines reviewers grep for when triaging
///     post-bundle #1869 regressions; or
///   - Make the deterministic per-explorer + per-province ordering
///     `(ascending by unit.id, ascending by province.id)` drift, masking
///     non-deterministic AI / order-engine state in CI runs where the
///     diagnostic is the only post-mortem record.
///
/// The function takes both [CtE2eNavalPanelSnapshot] and
/// [CtE2eCivilianPanelSnapshot] explicitly rather than reading the global
/// `ctE2eNavalPanelSnapshot` / `ctE2eCivilianPanelSnapshot` so the
/// diagnostic is deterministic and unit-testable (matches the lifted
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] /
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] /
/// [e2eExploreAssignEnabledFromCivilianSnapshot] precedents).
///
/// The integration suite cannot validate this directly today
/// (the `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin (Refs GitHub #2336 AC1 / AC2).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/bundled_explore_rejection_harness.dart';
import 'support/bundled_explore_fallback_group.dart';
import 'support/bundled_explore_header_group.dart';
import 'support/bundled_explore_no_explorers_group.dart';
import 'support/bundled_explore_probe_group.dart';
import 'support/bundled_explore_determinism_group.dart';

void main() {
  suppressLogsForTests();
  registerBundledExploreFallbackGroup();
  registerBundledExploreHeaderGroup();
  registerBundledExploreNoExplorersGroup();
  registerBundledExploreProbeGroup();
  registerBundledExploreDeterminismGroup();
}
