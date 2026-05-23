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

import '../integration_test/e2e_helpers.dart';
import '../integration_test/e2e_test_shared.dart' as shared;

/// Mounts a hit-testable panel root with the given children so
/// [e2eWaitUntilFound] short-circuits on the first poll. The helper exits
/// before its `timeout` ever elapses, isolating the contract under test
/// to the wait → null-check → collect → compare composition only.
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

  group('e2eExpectPanelTextsMatchSnapshot — default constants', () {
    test(
      'kE2eDefaultExpectPanelTextsPhase preserves the documented phase '
      'literal',
      () {
        expect(
          kE2eDefaultExpectPanelTextsPhase,
          'wait_until_found_panel_for_text_assertion',
          reason:
              'Callers that omit `phaseName` rely on this canonical default '
              '(used in the AC1 barrel signature and the helper signature) '
              'so AC8 timing tables can attribute generic invocations to a '
              'single bucket. A silent rename would orphan that bucket and '
              'fragment attribution across runs.',
        );
      },
    );

    test(
      'kE2eDefaultExpectPanelTextsTimeout preserves the 20-second budget '
      'used by the pre-lift inline closures',
      () {
        expect(
          kE2eDefaultExpectPanelTextsTimeout,
          const Duration(seconds: 20),
          reason:
              'The full-turn pre-lift closures '
              '(`expectCivilianPanelTexts` / `expectNavalPanelTexts` / '
              '`expectProductionPanelTexts`) all used a 20-second timeout. '
              'A silent change to the default would inflate the per-panel '
              'wall-clock budget #2336 is reducing.',
        );
      },
    );
  });

  group('e2eExpectPanelTextsMatchSnapshot — happy path', () {
    testWidgets(
      'matching expected texts -> assertion passes, builder called once, '
      'no E2E_DIAG markers emitted',
      (tester) async {
        const root = Key('panel_root_happy');
        await tester.pumpWidget(
          _wrap(root, const [Text('alpha'), Text('beta'), Text('gamma')]),
        );
        var calls = 0;
        await e2eExpectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: root,
          snapshot: const Object(),
          buildExpected: () {
            calls++;
            return const ['alpha', 'beta', 'gamma'];
          },
        );
        expect(
          calls,
          1,
          reason:
              'When no alternative builder is supplied and the assertion '
              'passes on the first compare, the primary builder must be '
              'invoked exactly once — invoking it again on success would '
              'double-cost downstream snapshot mirrors that build large '
              'expected lists.',
        );
      },
    );

    testWidgets(
      'mismatched expected texts -> orderedEquals fails (negative)',
      (tester) async {
        const root = Key('panel_root_mismatch');
        await tester.pumpWidget(
          _wrap(root, const [Text('alpha'), Text('beta')]),
        );
        await expectLater(
          () => e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshot: const Object(),
            buildExpected: () => const ['alpha', 'gamma'],
          ),
          throwsA(isA<TestFailure>()),
          reason:
              'A regression that swallowed the orderedEquals mismatch '
              '(for example by guarding the expect call with a try/catch) '
              'would silently green every snapshot drift in the four '
              'panel scenarios. Pin the failure path so the assertion '
              'still fails when the panel renders unexpected texts.',
        );
      },
    );
  });

  group('e2eExpectPanelTextsMatchSnapshot — null-snapshot guard', () {
    testWidgets(
      'null snapshot -> assertion fails with a panel-root-keyed reason',
      (tester) async {
        const root = Key('panel_root_null_snapshot');
        await tester.pumpWidget(_wrap(root, const [Text('whatever')]));
        try {
          await e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshot: null,
            buildExpected: () => const ['whatever'],
          );
          fail(
            'expected the helper to throw a TestFailure when the '
            'snapshot is null',
          );
        } on TestFailure catch (e) {
          expect(
            e.message,
            isNotNull,
            reason: 'TestFailure messages must be populated for diagnosis.',
          );
          expect(
            e.message!,
            contains('panel_root_null_snapshot'),
            reason:
                'A regression that dropped the panel root key from the '
                'reason: argument would surface a generic null check '
                'failure with no panel attribution. Pin the key in the '
                'failure message so callers can trace which mirror failed '
                'to prime its CtE2e* snapshot.',
          );
        }
      },
    );

    testWidgets(
      'null snapshot -> primary builder is never invoked',
      (tester) async {
        const root = Key('panel_root_null_snapshot_no_call');
        await tester.pumpWidget(_wrap(root, const [Text('only')]));
        var called = false;
        try {
          await e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshot: null,
            buildExpected: () {
              called = true;
              return const ['only'];
            },
          );
        } on TestFailure {
          // Expected — null guard fires before the builder runs.
        }
        expect(
          called,
          isFalse,
          reason:
              'A regression that called buildExpected before the '
              'null-snapshot guard would dereference a null `snap!` inside '
              'the panel-specific expected-texts function, producing a '
              'confusing Null check operator stack trace instead of the '
              'pin-friendly TestFailure carrying the panel root key.',
        );
      },
    );
  });

  group(
    'e2eExpectPanelTextsMatchSnapshot — alternative-expected anyOf fallback',
    () {
      testWidgets(
        'primary expected matches -> alternative builder is never called',
        (tester) async {
          const root = Key('panel_root_alt_primary');
          await tester.pumpWidget(
            _wrap(root, const [Text('alpha'), Text('beta')]),
          );
          var altCalls = 0;
          await e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshot: const Object(),
            buildExpected: () => const ['alpha', 'beta'],
            buildAlternativeExpected: () {
              altCalls++;
              return const ['x', 'y'];
            },
          );
          expect(
            altCalls,
            1,
            reason:
                'The naval-panel use case relies on `anyOf(orderedEquals(a), '
                'orderedEquals(b))` semantics — `anyOf` evaluates both '
                'matchers up front to produce its or-of-matchers, so the '
                'alternative builder is invoked exactly once even when the '
                'primary already matches. A regression that switched to '
                'short-circuit evaluation would change the perf cost '
                'characteristics of the naval expanded-fallback path; pin '
                'the pre-lift behaviour here.',
          );
        },
      );

      testWidgets(
        'primary fails, alternative matches -> assertion still passes',
        (tester) async {
          const root = Key('panel_root_alt_match');
          await tester.pumpWidget(
            _wrap(root, const [Text('collapsed-only')]),
          );
          await e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshot: const Object(),
            buildExpected: () => const ['expanded-only'],
            buildAlternativeExpected: () => const ['collapsed-only'],
          );
        },
      );

      testWidgets(
        'both expected lists fail -> assertion fails (negative)',
        (tester) async {
          const root = Key('panel_root_alt_both_fail');
          await tester.pumpWidget(_wrap(root, const [Text('actual-only')]));
          await expectLater(
            () => e2eExpectPanelTextsMatchSnapshot(
              tester,
              panelRootKey: root,
              snapshot: const Object(),
              buildExpected: () => const ['expanded-only'],
              buildAlternativeExpected: () => const ['collapsed-only'],
            ),
            throwsA(isA<TestFailure>()),
            reason:
                'When neither variant of a two-state panel matches the '
                'rendered tree, the helper must still fail. A regression '
                'that fell through to a silent pass after both legs missed '
                'would mask real snapshot drift on the naval expanded path.',
          );
        },
      );
    },
  );

  group('e2eExpectPanelTextsMatchSnapshot — perf attribution', () {
    testWidgets('phaseName forwards into the wait-until-found timing event', (
      tester,
    ) async {
      const root = Key('panel_root_phase_forward');
      await tester.pumpWidget(_wrap(root, const [Text('only')]));
      final perf = shared.E2ePerfLog('expect_panel_texts_pin');
      final lines = await _captureDebugPrints(() async {
        await e2eExpectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: root,
          snapshot: const Object(),
          buildExpected: () => const ['only'],
          phaseName: 'pin_panel_phase',
          perf: perf,
        );
      });
      expect(
        lines.where(
          (line) =>
              line.startsWith('E2E_TIMING|') &&
              line.contains('|phase=pin_panel_phase|'),
        ),
        isNotEmpty,
        reason:
            'The wait-until-found gate inside the helper must forward the '
            'caller-supplied `phaseName` into its timing event so AC8 '
            'tables keep their per-panel attribution. A regression that '
            'hard-coded the default phase would silently merge '
            '`wait_until_found_civilian_panel` / `_naval_panel` / '
            '`_production_panel` / `open_panel_province` into one bucket.',
      );
    });
  });

  group('e2eExpectPanelTextsMatchSnapshot — AC1 barrel forwarding', () {
    testWidgets(
      'expectPanelTextsMatchSnapshot (barrel alias) is wired to the '
      'lifted form',
      (tester) async {
        const root = Key('panel_root_barrel');
        await tester.pumpWidget(
          _wrap(root, const [Text('alpha'), Text('beta')]),
        );
        await expectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: root,
          snapshot: const Object(),
          buildExpected: () => const ['alpha', 'beta'],
        );
      },
    );

    test(
      'expectPanelTextsMatchSnapshot is re-exported as a tear-off '
      '(compile-time signature pin)',
      () {
        final Future<void> Function(
          WidgetTester, {
          required Key panelRootKey,
          required Object? snapshot,
          required List<String> Function() buildExpected,
          String phaseName,
          Duration timeout,
          shared.E2ePerfLog? perf,
          List<String> Function()? buildAlternativeExpected,
        })
        ref = expectPanelTextsMatchSnapshot;
        expect(
          ref,
          isNotNull,
          reason:
              'The AC1 barrel must keep exporting the helper with the '
              'documented signature. A silent removal from the `show` '
              'clause, an arg-order swap on the wrapper, or a default '
              'change for `phaseName` / `timeout` would fail this '
              'assignment at compile time, not at slow-CI E2E time.',
        );
      },
    );
  });
}
