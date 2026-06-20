// Pins the **canonical label set**, **timeout / phase defaults**, the
// **immediate-found short-circuit** for each label, the **mount-during-pump**
// branch, and the **timeout fail-fast** branch of
// `e2eAwaitCivilianWorkMenuMounted` in `app/integration_test/e2e_test_shared.dart`
// (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
//
// The lifted helper replaces two formerly-inline post-`Assign`-tap waits in
// `e2eTapFirstAssignInCivilianPanel` (`wait_until_civilian_work_menu`) and
// `e2eTapAssignOnCivilianRowWithTitle` (`wait_until_civilian_work_menu_row`).
// A regression here would either:
//
//   - Drift the canonical label set (e.g. localised strings replacing
//     English-only `Build improvement` / `Prospect` / `Explore`) and silently
//     stall every Assign-tap caller for the full 5 s timeout per call, or
//   - Lose the configurable `phaseName` so perf-timing dumps stop
//     distinguishing the title-scoped sibling caller from the first-of-many
//     caller, masking which Assign path is dominating wall-clock budget.
//
// `integration_test/` runs behind a no-op `app_e2e_linux` lane today
// (`SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
// is the only per-PR enforcement gate for the helper's contract.
library;

import 'dart:async';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Host that mounts at most one of the three canonical work-menu labels on
/// demand so the test can flip visibility while the helper polls. `Timer`
/// callbacks scheduled in [State.initState] fire when `tester.pump` advances
/// fake-time past the registered duration, mirroring the
/// `e2e_wait_until_any_finder_hit_testable_test.dart` precedent.
class _WorkMenuHost extends StatefulWidget {
  const _WorkMenuHost({
    required this.controller,
    this.mountAfter,
    this.labelToMount,
  });

  final _WorkMenuController controller;

  /// Fake-async delay before the host swaps in [labelToMount], or `null` to
  /// leave the controller's initial state untouched.
  final Duration? mountAfter;

  /// Label to surface as a mounted [Text] when [mountAfter] elapses.
  final String? labelToMount;

  @override
  State<_WorkMenuHost> createState() => _WorkMenuHostState();
}

class _WorkMenuHostState extends State<_WorkMenuHost> {
  Timer? _mountTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.mountAfter;
    final label = widget.labelToMount;
    if (after != null && label != null) {
      _mountTimer = Timer(after, () {
        widget.controller.mountedLabel = label;
      });
    }
  }

  @override
  void dispose() {
    _mountTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.controller.mountedLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[if (label != null) Text(label)],
    );
  }
}

class _WorkMenuController extends ChangeNotifier {
  _WorkMenuController({String? initialLabel}) : _mountedLabel = initialLabel;

  String? _mountedLabel;

  String? get mountedLabel => _mountedLabel;

  set mountedLabel(String? value) {
    if (_mountedLabel == value) return;
    _mountedLabel = value;
    notifyListeners();
  }
}

Future<void> _pumpHost(
  WidgetTester tester,
  _WorkMenuController controller, {
  Duration? mountAfter,
  String? labelToMount,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: _WorkMenuHost(
            controller: controller,
            mountAfter: mountAfter,
            labelToMount: labelToMount,
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  test(
    'kE2eCivilianWorkMenuLabels lists Build improvement, Prospect, Explore in order',
    () {
      // Pins the label set against silent additions/removals/reorders. The
      // production civilian panel only surfaces these three work-menu rows
      // after an `Assign` tap (`SPEC/program/e2e-integration-tests.md`
      // § Determinism); a drift here would either mask a missing label
      // (helper returns immediately on a stale label) or pin the wrong
      // existential short-circuit order.
      expect(
        kE2eCivilianWorkMenuLabels,
        equals(<String>['Build improvement', 'Prospect', 'Explore']),
      );
    },
  );

  test(
    'default timeout matches the legacy 5s budget and phase label is wait_until_civilian_work_menu',
    () {
      // Pins the legacy pre-lift inline timeout / phase byte-for-byte so the
      // first-of-many `e2eTapFirstAssignInCivilianPanel` caller does not
      // silently change CI perf-timing labels or shrink its post-tap budget.
      expect(
        kE2eDefaultCivilianWorkMenuMountTimeout,
        equals(const Duration(seconds: 5)),
      );
      expect(
        kE2eDefaultCivilianWorkMenuMountPhase,
        equals('wait_until_civilian_work_menu'),
      );
    },
  );

  testWidgets('returns immediately when Build improvement is already mounted', (
    WidgetTester tester,
  ) async {
    // First label in [kE2eCivilianWorkMenuLabels]: pre-pump short-circuit
    // must return without burning fake-async time so the common Builder
    // tap-then-build-improvement path is byte-equivalent to the pre-lift
    // inline `e2eWaitUntilAnyFinderHitTestable` call.
    final controller = _WorkMenuController(initialLabel: 'Build improvement');
    await _pumpHost(tester, controller);
    final sw = Stopwatch()..start();
    await e2eAwaitCivilianWorkMenuMounted(tester);
    expect(
      sw.elapsed,
      lessThan(const Duration(milliseconds: 200)),
      reason:
          'Pre-pump short-circuit must return well before the 5 s default '
          'timeout when Build improvement is already hit-testable.',
    );
  });

  testWidgets(
    'returns immediately when only Prospect (the second label) is mounted',
    (WidgetTester tester) async {
      // Pins the existential short-circuit for the second label; a regression
      // that bound the helper to `Build improvement` only would silently
      // burn the 5 s timeout when an Explorer tapped Assign and the panel
      // surfaced `Prospect` instead.
      final controller = _WorkMenuController(initialLabel: 'Prospect');
      await _pumpHost(tester, controller);
      final sw = Stopwatch()..start();
      await e2eAwaitCivilianWorkMenuMounted(tester);
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Helper must scan every label in kE2eCivilianWorkMenuLabels on '
            'the pre-pump pass; a later label being hit-testable must '
            'short-circuit the wait the same as the first label.',
      );
    },
  );

  testWidgets(
    'returns immediately when only Explore (the third label) is mounted',
    (WidgetTester tester) async {
      // Pins the existential short-circuit for the third label. Explorer
      // assignment in fleet-reach scenarios surfaces `Explore` first; a
      // regression that bound the helper to one of the other labels would
      // silently stall the bundled-Explore retry loop.
      final controller = _WorkMenuController(initialLabel: 'Explore');
      await _pumpHost(tester, controller);
      final sw = Stopwatch()..start();
      await e2eAwaitCivilianWorkMenuMounted(tester);
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Helper must short-circuit on Explore alone; otherwise the '
            'fleet-reach Explorer Assign path burns its 5 s post-tap budget.',
      );
    },
  );

  testWidgets('returns once a scheduled mount surfaces a label during pump', (
    WidgetTester tester,
  ) async {
    // Pins the mount-during-pump branch: the controller starts empty and
    // surfaces `Build improvement` after enough fake-async time that the
    // helper has already passed its pre-pump scan and is inside the
    // adaptive backoff loop. The helper must observe the late mount via
    // its `tester.pump` cadence without the test driving extra pumps.
    final controller = _WorkMenuController();
    await _pumpHost(
      tester,
      controller,
      mountAfter: const Duration(milliseconds: 80),
      labelToMount: 'Build improvement',
    );
    expect(find.text('Build improvement'), findsNothing);

    await e2eAwaitCivilianWorkMenuMounted(tester);

    expect(
      controller.mountedLabel,
      equals('Build improvement'),
      reason:
          'Sanity: the scheduled mount must have run before the helper '
          'returned, otherwise the helper saw a stale empty controller.',
    );
    expect(
      find.text('Build improvement').hitTestable(),
      findsOneWidget,
      reason:
          'The target finder must be hit-testable at return time, since '
          'that is the exact condition the helper waits on.',
    );
  });

  testWidgets('fails with TestFailure when no work-menu label ever surfaces', (
    WidgetTester tester,
  ) async {
    // Pins the timeout fail-fast branch: a tap that never mounts the work
    // menu must surface a TestFailure so the surrounding scenario fails at
    // the offending turn rather than continuing with a stale civilian
    // panel state (#2336 AC10).
    final controller = _WorkMenuController();
    await _pumpHost(tester, controller);
    Object? caught;
    try {
      await e2eAwaitCivilianWorkMenuMounted(
        tester,
        timeout: const Duration(milliseconds: 200),
      );
    } catch (e) {
      caught = e;
    }
    expect(
      caught,
      isA<TestFailure>(),
      reason:
          'Persistent absence must hit the timeout failure path so missing '
          'work-menu mounts do not silently no-op into later test steps.',
    );
    expect(
      caught.toString(),
      contains('Timed out'),
      reason:
          'Failure message must call out the timeout so the helper failure '
          'is attributable in CI logs.',
    );
  });

  testWidgets('honors a caller-supplied phaseName for perf-timing meta', (
    WidgetTester tester,
  ) async {
    // Pins that the title-scoped caller's
    // `wait_until_civilian_work_menu_row` phase still drives the inner
    // [e2eWaitUntilAnyFinderHitTestable] perf timing rather than being
    // dropped on the floor by the lift. We exercise this by inducing a
    // timeout and confirming `_perf` recorded a timing slice keyed on the
    // caller's phase.
    const callerPhase = 'wait_until_civilian_work_menu_row';
    final controller = _WorkMenuController();
    await _pumpHost(tester, controller);
    final perf = E2ePerfLog('await_civilian_work_menu_phase_pin');

    // Capture debugPrint output so we can assert on the inner perf timing
    // emitted by [e2eWaitUntilAnyFinderHitTestable].
    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        logs.add(message);
      }
    };
    try {
      try {
        await e2eAwaitCivilianWorkMenuMounted(
          tester,
          timeout: const Duration(milliseconds: 200),
          phaseName: callerPhase,
          perf: perf,
        );
        fail('Expected TestFailure when work menu never surfaces');
      } on TestFailure {
        // Expected: timeout path of [e2eWaitUntilAnyFinderHitTestable].
      }
    } finally {
      debugPrint = originalDebugPrint;
    }

    expect(
      logs.any(
        (line) =>
            line.startsWith('E2E_TIMING') &&
            line.contains('phase=$callerPhase') &&
            line.contains('result=timeout'),
      ),
      isTrue,
      reason:
          'The caller-supplied phase name must reach the inner '
          'e2eWaitUntilAnyFinderHitTestable so perf-timing dumps still '
          'distinguish the title-scoped sibling caller after the lift.',
    );
  });
}
