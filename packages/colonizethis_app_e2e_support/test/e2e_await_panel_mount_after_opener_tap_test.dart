/// Widget-test coverage for `e2eAwaitPanelMountAfterOpenerTap`, the shared
/// post-tap panel-mount probe that `e2eOpenCivilianPanel`,
/// `e2eOpenNavalPanel`, and `e2eOpenProductionPanel` invoke after their
/// rail/marker tap.
///
/// Before this lift each of the three panel openers inlined the same
/// three-step recipe ("fast hit-check → one explicit `await tester.pump()`
/// → bounded [e2ePumpUntilConditionOrIdle]") with per-opener phase names
/// and timeouts. A regression that diverged any of the three openers
/// (for example dropping the post-pump fast-check on production but
/// keeping it on civilian/naval, or replacing the bounded
/// [e2ePumpUntilConditionOrIdle] with a strict [e2ePumpUntil] that fails
/// loudly inside `tryOpen`) would surface as a wall-clock regression in
/// the integration suite — but the `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI, so the widget-test
/// layer carries the behavioural pins for the AC1 "single canonical
/// shared helper" and AC10 "no silent flakiness from off-screen-trigger
/// drops" contracts.
///
/// Refs GitHub #2336 (AC1 — shared helpers; AC2 — single canonical
/// implementation; AC10 — no silent flakiness from timeout regressions).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'support/delayed_mount_harness.dart';
import 'support/e2e_await_panel_mount_after_opener_tap_guard_group.dart';
import 'support/e2e_widget_pump_harness.dart';

const _kPanelKey = ValueKey<String>('e2e_await_panel_mount_panel');

Widget _panelHost({
  required void Function(DelayedMountHostState state) onState,
  Duration? flipAfter,
}) => DelayedMountHost(
  mountAfter: flipAfter,
  onState: onState,
  child: const KeyedSubtree(
    key: _kPanelKey,
    child: SizedBox(width: 100, height: 100),
  ),
);

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eAwaitPanelMountAfterOpenerTap returns true synchronously without '
    'pumping when the panel root is already mounted',
    (WidgetTester tester) async {
      // Mount the panel root before the helper runs so the immediate
      // hit-check branch is exercised. The fast path must avoid an
      // unconditional leading pump because the three panel openers call
      // this helper inside their inner `tryOpen` closures — a leading
      // pump per call would re-introduce the per-opener idle frame that
      // PR #2782 already removed from the outer loop.
      await tester.pumpWidget(
        wrapE2eScaffold(
          const KeyedSubtree(
            key: _kPanelKey,
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );
      final sw = Stopwatch()..start();
      final result = await e2eAwaitPanelMountAfterOpenerTap(
        tester,
        find.byKey(_kPanelKey),
        timeout: const Duration(seconds: 3),
        phaseName: 'pin_already_mounted',
      );
      expect(
        result,
        isTrue,
        reason:
            'Already-mounted panel root must report true so the opener '
            'tryOpen closure short-circuits without entering the bounded '
            'poll (Refs GitHub #2336 AC1).',
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Already-mounted panel root must return before the helper '
            'enters [e2ePumpUntilConditionOrIdle]; a regression that '
            'always pumped a leading frame would re-introduce per-call '
            'idle frames that the three panel openers invoke many times '
            'per scenario (Refs GitHub #2336 AC5).',
      );
    },
  );

  testWidgets('e2eAwaitPanelMountAfterOpenerTap returns true via the post-pump '
      'fast-check when the panel mounts during the helper\'s explicit pump', (
    WidgetTester tester,
  ) async {
    // The pre-call `state.mount()` marks the host dirty without
    // rebuilding the element tree, so the helper\'s immediate
    // hit-check still sees an empty panel root. The helper\'s explicit
    // `await tester.pump()` triggers the deferred rebuild; after the
    // pump the panel root is in the tree and the post-pump fast-check
    // returns true without entering the bounded poll. A regression
    // that dropped the post-pump fast-check would still pass (via
    // [e2ePumpUntilConditionOrIdle]) but would pay one extra adaptive
    // poll cycle per call across all three openers (Refs GitHub #2336
    // AC1 / AC5).
    late DelayedMountHostState state;
    await tester.pumpWidget(
      wrapE2eScaffold(_panelHost(onState: (s) => state = s)),
    );
    expect(find.byKey(_kPanelKey), findsNothing);
    state.mount();
    final result = await e2eAwaitPanelMountAfterOpenerTap(
      tester,
      find.byKey(_kPanelKey),
      timeout: const Duration(seconds: 3),
      phaseName: 'pin_mounts_after_first_pump',
    );
    expect(
      result,
      isTrue,
      reason:
          'Panel mounted after the helper\'s explicit pump must return '
          'true via the post-pump fast-check so the opener tryOpen '
          'closure does not pay an extra adaptive poll iteration on '
          'the common "frame-deferred mount" path (Refs GitHub #2336 '
          'AC1 / AC10).',
    );
    expect(
      find.byKey(_kPanelKey),
      findsOneWidget,
      reason:
          'Post-call assertion: the panel root must be in the tree at '
          'return time so any regression that returned true without '
          'pumping (skipping the explicit pump entirely) would surface '
          'as a missing panel root in the harness.',
    );
  });

  testWidgets(
    'e2eAwaitPanelMountAfterOpenerTap returns true via the bounded poll '
    'when the panel mounts after a fake-async Timer fires',
    (WidgetTester tester) async {
      // Schedule the mount via a fake-async Timer that fires inside the
      // bounded poll's adaptive backoff window. The helper\'s immediate
      // and post-pump fast-checks both fail (Timer has not fired yet);
      // [e2ePumpUntilConditionOrIdle] then drives the pump loop until
      // the Timer flips the host. A regression that swapped
      // [e2ePumpUntilConditionOrIdle] for the strict [e2ePumpUntil]
      // would still pass this test (because the predicate eventually
      // becomes true), but the timeout-failure test below pins the
      // best-effort contract directly.
      late DelayedMountHostState state;
      await tester.pumpWidget(
        wrapE2eScaffold(
          _panelHost(
            flipAfter: const Duration(milliseconds: 60),
            onState: (s) => state = s,
          ),
        ),
      );
      expect(find.byKey(_kPanelKey), findsNothing);
      final result = await e2eAwaitPanelMountAfterOpenerTap(
        tester,
        find.byKey(_kPanelKey),
        timeout: const Duration(seconds: 3),
        phaseName: 'pin_mounts_during_bounded_poll',
      );
      expect(
        result,
        isTrue,
        reason:
            'Panel that mounts during the bounded poll window must '
            'return true so the opener tryOpen closure proceeds to the '
            'outer-loop success path; a regression that returned false '
            'would stall the opener at the timeout cap (Refs GitHub '
            '#2336 AC10).',
      );
      expect(state.mounted, isTrue);
    },
  );

  registerAwaitPanelMountAfterOpenerTapGuardGroup();
}
