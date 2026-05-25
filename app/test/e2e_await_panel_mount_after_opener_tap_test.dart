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

import 'dart:async';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

const _kPanelKey = ValueKey<String>('e2e_await_panel_mount_panel');

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
        const MaterialApp(
          home: Scaffold(
            body: KeyedSubtree(
              key: _kPanelKey,
              child: SizedBox(width: 100, height: 100),
            ),
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
    late _DelayedMountState state;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _DelayedMountHost(onState: (s) => state = s)),
      ),
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
      late _DelayedMountState state;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _DelayedMountHost(
              flipAfter: const Duration(milliseconds: 60),
              onState: (s) => state = s,
            ),
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

  testWidgets(
    'e2eAwaitPanelMountAfterOpenerTap returns false without throwing when '
    'the panel never mounts within the timeout',
    (WidgetTester tester) async {
      // Best-effort contract pin: the panel openers gate their outer
      // adaptive-poll loop on this helper\'s `false` return to dismiss
      // transient overlays and retry the rail/marker tap. A regression
      // that promoted the timeout into a `fail()` call (for example by
      // swapping [e2ePumpUntilConditionOrIdle] for the strict
      // [e2ePumpUntil]) would surface as a hard TestFailure inside
      // `tryOpen` instead of letting the outer loop recover, which would
      // regress every scenario that opens a panel while a sheet is
      // closing (Refs GitHub #2336 AC1 / AC10).
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      Object? caught;
      bool? result;
      try {
        result = await e2eAwaitPanelMountAfterOpenerTap(
          tester,
          find.byKey(_kPanelKey),
          timeout: const Duration(milliseconds: 150),
          phaseName: 'pin_never_mounts_timeout',
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isNull,
        reason:
            'Best-effort variant must NOT call fail() on timeout so the '
            'opener tryOpen closure can return false and let the outer '
            'loop dismiss transient overlays and retry the rail/marker '
            'tap (Refs GitHub #2336 AC10).',
      );
      expect(
        result,
        isFalse,
        reason:
            'Persistent not-mounted panel must surface as a false return '
            'so the opener tryOpen closure can decide whether to retry '
            'the rail/marker branch on the outer adaptive-poll loop '
            '(Refs GitHub #2336 AC1).',
      );
    },
  );

  testWidgets('e2eAwaitPanelMountAfterOpenerTap accepts a custom phaseName and '
      'E2ePerfLog on the success path', (WidgetTester tester) async {
    // Smoke-only: the helper must not throw when handed an
    // E2ePerfLog + explicit phaseName so scenario-level callers can
    // keep emitting `E2E_TIMING|phase=...|result=...` markers without
    // paying a signature regression here. The three panel openers
    // already forward their `perf` arg into this helper; a signature
    // break would compile-error at the call sites.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: _kPanelKey,
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );
    final perf = E2ePerfLog('e2e_await_panel_mount_after_opener_tap_test');
    final result = await e2eAwaitPanelMountAfterOpenerTap(
      tester,
      find.byKey(_kPanelKey),
      timeout: const Duration(seconds: 2),
      perf: perf,
      phaseName: 'pin_perf_success',
    );
    expect(result, isTrue);
  });

  testWidgets('e2eAwaitPanelMountAfterOpenerTap accepts a custom phaseName and '
      'E2ePerfLog on the timeout path without escalating to fail()', (
    WidgetTester tester,
  ) async {
    // The perf arg must remain observability metadata only; a
    // regression that started failing the test when perf was provided
    // (for example by swapping in a strict pump helper that fails on
    // timeout) would break every panel-opener call site that already
    // forwards `perf` and break wall-clock attribution.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final perf = E2ePerfLog('e2e_await_panel_mount_after_opener_tap_test');
    final result = await e2eAwaitPanelMountAfterOpenerTap(
      tester,
      find.byKey(_kPanelKey),
      timeout: const Duration(milliseconds: 80),
      perf: perf,
      phaseName: 'pin_perf_timeout',
    );
    expect(
      result,
      isFalse,
      reason:
          'Passing a perf log on the timeout path must keep the '
          'best-effort `false` return; perf is observability metadata '
          'only and must not promote the timeout into a fail() call '
          '(Refs GitHub #2336 AC1 / AC10).',
    );
  });

  testWidgets(
    'AC1 barrel alias `awaitPanelMountAfterOpenerTap` forwards to the '
    'shared implementation with the documented signature',
    (WidgetTester tester) async {
      // Compile-time alias signature pin: the tear-off must assign to a
      // matching function type from the barrel without an explicit cast.
      // A future signature drift here (extra positional/named arg,
      // return-type change, or a missing `timeout` / `phaseName` named
      // requirement) would fail at compile time so consumers of the AC1
      // barrel cannot silently switch to a different recipe.
      final Future<bool> Function(
        WidgetTester,
        Finder, {
        required Duration timeout,
        E2ePerfLog? perf,
        required String phaseName,
      })
      tearOff = awaitPanelMountAfterOpenerTap;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KeyedSubtree(
              key: _kPanelKey,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
      final result = await tearOff(
        tester,
        find.byKey(_kPanelKey),
        timeout: const Duration(seconds: 1),
        phaseName: 'pin_ac1_barrel_alias',
      );
      expect(result, isTrue);
    },
  );
}

/// Host that exposes a `mount()` method to externally trigger a `setState`
/// flip that mounts a [KeyedSubtree(key: _kPanelKey)] in the widget tree.
///
/// When [flipAfter] is provided, schedules a fake-async [Timer] in
/// `initState` that mounts the panel after the requested elapsed fake
/// time. The host is otherwise inert so a test can call `state.mount()`
/// from outside the helper to exercise the post-pump fast-check path.
class _DelayedMountHost extends StatefulWidget {
  const _DelayedMountHost({required this.onState, this.flipAfter});

  final void Function(_DelayedMountState state) onState;
  final Duration? flipAfter;

  @override
  State<_DelayedMountHost> createState() => _DelayedMountState();
}

class _DelayedMountState extends State<_DelayedMountHost> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    widget.onState(this);
    final after = widget.flipAfter;
    if (after != null) {
      Timer(after, () {
        if (!mounted) return;
        setState(() => _show = true);
      });
    }
  }

  void mount() {
    setState(() => _show = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) {
      return const SizedBox.shrink();
    }
    return const KeyedSubtree(
      key: _kPanelKey,
      child: SizedBox(width: 100, height: 100),
    );
  }
}
