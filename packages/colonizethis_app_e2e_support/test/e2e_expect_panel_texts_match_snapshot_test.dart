/// Pins the widget-tree contract of [e2eExpectPanelTextsMatchSnapshot]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The full-turn scenario in `new_game_full_turn_e2e_test.dart` calls this
/// helper through the AC1 barrel alias `expectPanelTextsMatchSnapshot` for
/// three panels (civilian / naval / production) and the capital-panel
/// scenario in `new_game_capital_panel_e2e_test.dart` uses the same alias
/// for the province panel. The helper composes four sub-steps (wait for
/// the panel root, assert the `CtE2e*` snapshot is non-null, collect texts
/// in pre-order, compare with `orderedEquals` — falling back to an
/// alternative expected list via `anyOf` when one is supplied).
///
/// A silent regression here would either:
///
///   - Skip the `e2eWaitUntilFound` gate and race against the panel
///     mounting — the inline closure pre-lift always waited up to 20s for
///     the panel root before reading the snapshot, so dropping the wait
///     would surface as a flaky `null` snapshot in only the slow CI lane.
///   - Drop the `expect(snapshot, isNotNull)` guard and let
///     [buildExpected] dereference a still-`null` snapshot via `snap!`,
///     producing a confusing `Null check operator used on a null value`
///     stack trace deep inside `civilianUnitsPanelExpectedTexts` /
///     `navalUnitsPanelExpectedTexts` / `productionPanelWideExpectedTexts`
///     / `provincePanelWideLayoutExpectedTexts` instead of the named
///     panel-root-key reason this helper carries.
///   - Forward the `phaseName` / `timeout` parameters incorrectly (or
///     hard-code them) — collapsing the per-panel attribution labels
///     (`wait_until_found_civilian_panel`, `wait_until_found_naval_panel`,
///     `wait_until_found_production_panel`, `open_panel_province`) into a
///     single bucket would orphan AC8 timing tables keyed on the
///     pre-lift labels.
///   - Skip the `buildAlternativeExpected` `anyOf` fallback — the naval
///     panel can settle in either the `fleetTilesExpanded: true` or
///     `fleetTilesExpanded: false` variant after a tap-driven expansion
///     re-render; collapsing to `orderedEquals(buildExpected())`
///     unconditionally would re-introduce the pre-#2336 flake when the
///     post-tap settle landed on the collapsed mirror.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

/// Mounts a hit-testable panel root with the given children so
/// [e2eWaitUntilFound] short-circuits on the first poll. The helper exits
/// before its `timeout` ever elapses, isolating the contract under test
/// to the wait → null-check → collect → compare composition only.

part 'support/expect_panel_texts_constants_part.dart';
part 'support/expect_panel_texts_happy_part.dart';
part 'support/expect_panel_texts_null_part.dart';
part 'support/expect_panel_texts_mismatch_a_part.dart';
part 'support/expect_panel_texts_mismatch_b_part.dart';
part 'support/expect_panel_texts_ignore_part.dart';
part 'support/expect_panel_texts_perf_part.dart';
part 'support/expect_panel_texts_barrel_part.dart';

Widget _wrap(Key panelRootKey, List<Widget> children) => MaterialApp(
  home: Scaffold(
    body: KeyedSubtree(
      key: panelRootKey,
      child: ListView(children: children),
    ),
  ),
);

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
Future<List<String>> _captureDebugPrints(Future<void> Function() body) async {
  final captured = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    captured.add(message ?? '');
  };
  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return captured;
}


void main() {
  suppressLogsForTests();
  registerExpectPanelTextsConstantsGroup();
  registerExpectPanelTextsHappyGroup();
  registerExpectPanelTextsNullGuardGroup();
  registerExpectPanelTextsMismatchAGroup();
  registerExpectPanelTextsMismatchBGroup();
  registerExpectPanelTextsIgnoreGroup();
  registerExpectPanelTextsPerfGroup();
  registerExpectPanelTextsBarrelGroup();
}
