/// Pins the **pre-pump short-circuit**, **adaptive backoff polling**, and
/// **`diagnoseAfter` settle pump** contracts of `e2eWaitUntilFound`
/// (Refs GitHub #2336 AC2 / AC5 /
/// `SPEC/program/e2e-integration-tests.md` § Adaptive poll pacing).
///
/// `e2eWaitUntilFound` is the canonical "wait until a finder becomes
/// non-empty" primitive that the rest of the E2E shared helpers
/// (`e2eWaitForNewGameEntry`, `e2eOpenProductionPanel`,
/// `e2eSplitHomeFleetOnce`, ...) depend on, but it had no direct
/// behavioral contract test — only indirect coverage through the
/// scenario-level pins. Any silent regression in its three branches
/// (entry short-circuit, adaptive pump loop, timeout failure path with
/// optional diagnostic settle) would slip through the existing widget
/// tests and only surface as a confusing E2E timing/flake regression
/// in the wall-clock-bound paths #2336 is reducing.
///
/// Because the `integration_test/` suite runs behind a no-op
/// `app_e2e_linux` lane today (`SPEC/program/e2e-integration-tests.md`
/// § CI), the behavioral pins live in the widget-test layer and use
/// fake-async `Timer` flips so the helper's `tester.pump` loop
/// observes the mounted finders without the test driving extra pumps
/// itself.
library;

import 'dart:async';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
// `dart:async` is imported for the `Timer` used by `_DelayedMountHost` to
// flip its `_mounted` flag during the helper's adaptive pump loop without the
// test driving extra pumps itself.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Host that mounts a single keyed `TextButton` after an optional fake-async
/// delay so the test can flip visibility while the helper polls.
///
/// `Timer` callbacks scheduled in [State.initState] fire when `tester.pump`
/// advances fake-time past the registered duration, so the helper sees the
/// newly mounted widget on a later iteration without the test calling
/// `tester.pump` itself (which would deadlock against the helper's guarded
/// pump loop).
class _DelayedMountHost extends StatefulWidget {
  const _DelayedMountHost({
    required this.targetKey,
    this.mountAfter,
    this.startMounted = false,
  });

  /// Key the host will render once mounted; the test waits on
  /// `find.byKey(targetKey)`.
  final Key targetKey;

  /// Fake-async delay before the host mounts [targetKey], or `null` to leave
  /// the mounted flag untouched.
  final Duration? mountAfter;

  /// Whether [targetKey] is mounted on the first frame (pre-pump).
  final bool startMounted;

  @override
  State<_DelayedMountHost> createState() => _DelayedMountHostState();
}

class _DelayedMountHostState extends State<_DelayedMountHost> {
  late bool _mounted;
  Timer? _mountTimer;

  @override
  void initState() {
    super.initState();
    _mounted = widget.startMounted;
    final after = widget.mountAfter;
    if (after != null) {
      _mountTimer = Timer(after, () {
        if (!mounted) return;
        setState(() {
          _mounted = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _mountTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mounted) {
      return const SizedBox.shrink();
    }
    return TextButton(
      key: widget.targetKey,
      onPressed: () {},
      child: const Text('btn'),
    );
  }
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required Key targetKey,
  Duration? mountAfter,
  bool startMounted = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: _DelayedMountHost(
            targetKey: targetKey,
            mountAfter: mountAfter,
            startMounted: startMounted,
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'short-circuits before any pump when finder is already non-empty',
    (WidgetTester tester) async {
      const targetKey = Key('e2e_present_btn');
      await _pumpHost(tester, targetKey: targetKey, startMounted: true);
      expect(find.byKey(targetKey), findsOneWidget);

      final sw = Stopwatch()..start();
      await e2eWaitUntilFound(
        tester,
        find.byKey(targetKey),
        timeout: const Duration(seconds: 5),
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Pre-pump short-circuit must return well before the timeout cap '
            'when the finder is already non-empty on entry; this keeps the '
            'caller from paying any adaptive pump time (#2336 AC5).',
      );
    },
  );

  testWidgets(
    'returns once a scheduled mount makes the finder non-empty during pump',
    (WidgetTester tester) async {
      const targetKey = Key('e2e_late_btn');
      await _pumpHost(
        tester,
        targetKey: targetKey,
        mountAfter: const Duration(milliseconds: 80),
      );
      expect(find.byKey(targetKey), findsNothing);

      await e2eWaitUntilFound(
        tester,
        find.byKey(targetKey),
        timeout: const Duration(seconds: 5),
      );

      expect(
        find.byKey(targetKey),
        findsOneWidget,
        reason:
            'The target finder must be non-empty at return time — that is '
            'the exact condition the adaptive pump loop waits on.',
      );
    },
  );

  testWidgets(
    'fails with TestFailure when finder never becomes non-empty within timeout',
    (WidgetTester tester) async {
      const missingKey = Key('e2e_missing_btn');
      await _pumpHost(tester, targetKey: missingKey);
      Object? caught;
      try {
        await e2eWaitUntilFound(
          tester,
          find.byKey(missingKey),
          timeout: const Duration(milliseconds: 200),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Persistent absence must hit the timeout failure path so '
            'missing widgets do not silently no-op and leak into later '
            'test steps (#2336 AC10).',
      );
      expect(
        caught.toString(),
        contains('Timed out'),
        reason:
            'Failure message must call out the timeout so the helper '
            'failure is attributable in CI logs.',
      );
      expect(
        caught.toString(),
        contains('waiting for'),
        reason:
            'Failure message must include the finder for diagnostic '
            'attribution alongside the timeout marker.',
      );
    },
  );

  testWidgets(
    'diagnoseAfter parameter still fails on persistent absence without crashing',
    (WidgetTester tester) async {
      const missingKey = Key('e2e_diagnose_btn');
      await _pumpHost(tester, targetKey: missingKey);

      Object? caught;
      try {
        await e2eWaitUntilFound(
          tester,
          find.byKey(missingKey),
          timeout: const Duration(milliseconds: 100),
          diagnoseAfter: const Duration(milliseconds: 300),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'diagnoseAfter must not swallow the timeout failure — the helper '
            'still has to fail so callers see the wait did not succeed '
            'even when a post-timeout diagnostic settle pump is requested.',
      );
      expect(
        caught.toString(),
        contains('Last exception'),
        reason:
            'The failure message must surface `tester.takeException()` under '
            '`Last exception:` so the diagnostic settle pump can attribute '
            'any late uncaught exceptions to the timed-out wait (#2336 AC10).',
      );
    },
  );

  testWidgets(
    'accepts a custom phaseName and E2ePerfLog on the short-circuit path',
    (WidgetTester tester) async {
      const targetKey = Key('e2e_perf_btn');
      await _pumpHost(tester, targetKey: targetKey, startMounted: true);
      final perf = E2ePerfLog('e2e_wait_until_found_test');
      await e2eWaitUntilFound(
        tester,
        find.byKey(targetKey),
        timeout: const Duration(seconds: 2),
        perf: perf,
        phaseName: 'pin_wait_until_found_perf_phase',
      );
      // Smoke-only: the helper must not throw when handed an E2ePerfLog +
      // explicit phaseName, so scenario-level callers can keep emitting
      // E2E_COUNTER / E2E_TIMING markers without paying a regression here.
    },
  );

  testWidgets(
    'accepts a custom phaseName and E2ePerfLog on the timeout path',
    (WidgetTester tester) async {
      const missingKey = Key('e2e_perf_timeout_btn');
      await _pumpHost(tester, targetKey: missingKey);
      final perf = E2ePerfLog('e2e_wait_until_found_test');
      Object? caught;
      try {
        await e2eWaitUntilFound(
          tester,
          find.byKey(missingKey),
          timeout: const Duration(milliseconds: 100),
          perf: perf,
          phaseName: 'pin_wait_until_found_perf_timeout',
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Passing a perf log on the timeout path must not suppress the '
            'fail() invocation; perf is observability metadata only.',
      );
    },
  );
}
