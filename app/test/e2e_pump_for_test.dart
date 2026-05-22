/// Pins the **fixed-step pump loop**, **non-positive short-circuit**, and
/// **last-step overshoot** contracts of `e2ePumpFor`
/// in `app/integration_test/e2e_test_shared.dart` (Refs GitHub #2336 AC2).
///
/// `e2ePumpFor` is the small public helper that `e2eWaitUntilFound` calls
/// on its `diagnoseAfter` settle path when a poll times out, so callers
/// (`e2eOpenProductionPanel`, `e2eOpenCivilianPanel`, `e2eSplitHomeFleetOnce`,
/// ...) can record a stable widget snapshot before the surrounding `fail()`.
/// It is also re-exported as `pumpFor` from `app/integration_test/e2e_helpers.dart`
/// per the AC1 shared-helper checklist, so its contract is part of the
/// public AC2 surface that new E2E scenarios depend on.
///
/// The implementation is deliberately tiny:
///
/// ```dart
/// Future<void> e2ePumpFor(WidgetTester tester, Duration total) async {
///   const step = Duration(milliseconds: 50);
///   var elapsed = Duration.zero;
///   while (elapsed < total) {
///     await tester.pump(step);
///     elapsed += step;
///   }
/// }
/// ```
///
/// Three branches are easy to break silently:
///
/// 1. **Pre-loop short-circuit** — `total <= Duration.zero` must drive
///    **zero** pumps. A regression that always does at least one pump
///    would burn a 50ms frame on every failure diagnose call (and
///    on any future caller that opts into a zero-cap settle).
/// 2. **Fixed 50ms step** — each iteration pumps exactly the constant
///    `step` (50ms), not `total - elapsed`. A regression that switched
///    to `tester.pump(total)` in one shot would break the diagnostic
///    intent (capture an intermediate frame after each step) and break
///    any caller that relies on the simulated clock advancing in 50ms
///    increments.
/// 3. **Last-step overshoot** — the loop runs **one additional pump**
///    whenever `total` is not a multiple of 50ms (the strict `elapsed
///    < total` check fires before the increment). Callers therefore
///    receive a settled snapshot at the next 50ms boundary at or
///    after `total`, never earlier. A regression that swapped the
///    bound for `elapsed + step <= total` would silently round down
///    sub-50ms callers to zero pumps.
///
/// Because the `integration_test/` suite runs behind a no-op
/// `app_e2e_linux` lane today (`SPEC/program/e2e-integration-tests.md`
/// § CI), the behavioral pins live in the widget-test layer and use a
/// persistent `Ticker` driven by a [SingleTickerProviderStateMixin] host
/// to count the simulated frames the helper pumps without the test
/// driving extra pumps itself (which would deadlock against the
/// helper's guarded pump loop).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Host that owns an active [Ticker] and counts every frame the binding
/// processes after the ticker is started.
///
/// [Ticker.start] dispatches one `onTick` callback per frame as long as
/// the ticker is muted=false and active, so each `tester.pump(step)`
/// invocation inside `e2ePumpFor` produces exactly one tick. The
/// counter is exposed via [framesPumped] so the surrounding test can
/// assert the iteration count after the helper returns.
class _TickerFrameCounter extends StatefulWidget {
  const _TickerFrameCounter({required this.onState});

  final void Function(_TickerFrameCounterState state) onState;

  @override
  State<_TickerFrameCounter> createState() => _TickerFrameCounterState();
}

class _TickerFrameCounterState extends State<_TickerFrameCounter>
    with SingleTickerProviderStateMixin {
  int framesPumped = 0;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    widget.onState(this);
    _ticker = createTicker((_) => framesPumped++);
  }

  void startCounting() {
    framesPumped = 0;
    _ticker.start();
  }

  void stopCounting() {
    _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<_TickerFrameCounterState> _pumpTickerHost(WidgetTester tester) async {
  late _TickerFrameCounterState captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _TickerFrameCounter(onState: (s) => captured = s),
      ),
    ),
  );
  return captured;
}

void main() {
  suppressLogsForTests();

  group('e2ePumpFor', () {
    testWidgets(
      'short-circuits before any pump when total is Duration.zero',
      (WidgetTester tester) async {
        final host = await _pumpTickerHost(tester);
        host.startCounting();
        final sw = Stopwatch()..start();

        await e2ePumpFor(tester, Duration.zero);
        host.stopCounting();

        expect(
          host.framesPumped,
          0,
          reason:
              'A zero-duration call must not pump any frames. '
              '`e2eWaitUntilFound` passes `Duration.zero` on its '
              '`diagnoseAfter` failure path by default; a regression that '
              'always pumps one 50ms frame would silently lengthen every '
              'failure timeline by a frame and burn wall-clock budget on '
              'the success path of any future caller that opts into a '
              'zero-cap settle (#2336 AC5).',
        );
        expect(
          sw.elapsed,
          lessThan(const Duration(milliseconds: 200)),
          reason:
              'The pre-loop short-circuit must return well inside any '
              'sensible wall-clock budget when nothing needs settling.',
        );
      },
    );

    testWidgets(
      'short-circuits without pumping when total is negative',
      (WidgetTester tester) async {
        final host = await _pumpTickerHost(tester);
        host.startCounting();

        await e2ePumpFor(tester, const Duration(milliseconds: -25));
        host.stopCounting();

        expect(
          host.framesPumped,
          0,
          reason:
              'A negative duration is treated by the strict `elapsed < total` '
              'check as "nothing to do" — the loop body must not execute. A '
              'regression that absolutized or ignored the sign would pump '
              'unbounded frames on a defensive caller passing a clamped '
              'delta.',
        );
      },
    );

    testWidgets(
      'pumps exactly one 50ms frame for a sub-step duration',
      (WidgetTester tester) async {
        final host = await _pumpTickerHost(tester);
        host.startCounting();

        await e2ePumpFor(tester, const Duration(milliseconds: 25));
        host.stopCounting();

        expect(
          host.framesPumped,
          1,
          reason:
              'For any `0 < total <= 50ms` the loop runs exactly one '
              'iteration: `0 < 25 -> pump -> 50 !< 25 -> exit`. A regression '
              'that rounded sub-step callers down to zero pumps would skip '
              'the intended diagnostic snapshot entirely.',
        );
      },
    );

    testWidgets(
      'pumps exactly one 50ms frame for total equal to the step',
      (WidgetTester tester) async {
        final host = await _pumpTickerHost(tester);
        host.startCounting();

        await e2ePumpFor(tester, const Duration(milliseconds: 50));
        host.stopCounting();

        expect(
          host.framesPumped,
          1,
          reason:
              'The strict `elapsed < total` bound excludes the boundary '
              'case: a single pump satisfies `total == step`. A regression '
              'that used `elapsed <= total` would pump one extra frame on '
              'every multiple-of-step caller.',
        );
      },
    );

    testWidgets(
      'pumps an extra step when total is not a multiple of 50ms (overshoot)',
      (WidgetTester tester) async {
        final host = await _pumpTickerHost(tester);
        host.startCounting();

        await e2ePumpFor(tester, const Duration(milliseconds: 51));
        host.stopCounting();

        expect(
          host.framesPumped,
          2,
          reason:
              'For total slightly above one step, the loop runs `0 < 51 -> '
              'pump -> 50 < 51 -> pump -> 100 !< 51 -> exit` (two pumps). '
              'Callers receive a settled snapshot at the next 50ms boundary '
              '*at or after* `total`, never earlier — a regression that '
              'used `elapsed + step <= total` would drop the second pump '
              'and round sub-100ms callers down to a single frame.',
        );
      },
    );

    testWidgets(
      'pumps four 50ms frames for a 200ms total',
      (WidgetTester tester) async {
        final host = await _pumpTickerHost(tester);
        host.startCounting();

        await e2ePumpFor(tester, const Duration(milliseconds: 200));
        host.stopCounting();

        expect(
          host.framesPumped,
          4,
          reason:
              'For a clean multiple of the step, the loop runs '
              '`200ms / 50ms = 4` iterations. A regression that swapped the '
              'per-iteration `tester.pump(step)` for a single '
              '`tester.pump(total)` would collapse this to one frame and '
              'break callers that rely on intermediate frames for the '
              'diagnostic snapshot.',
        );
      },
    );

    testWidgets(
      'pumps three 50ms frames for a 150ms total (no overshoot at boundary)',
      (WidgetTester tester) async {
        final host = await _pumpTickerHost(tester);
        host.startCounting();

        await e2ePumpFor(tester, const Duration(milliseconds: 150));
        host.stopCounting();

        expect(
          host.framesPumped,
          3,
          reason:
              'A 150ms total is exactly `3 * 50ms`; the loop must exit at '
              'the boundary without an extra pump. Pinned alongside the '
              '51ms overshoot case so a refactor cannot swap the bound '
              'condition without flipping both branches.',
        );
      },
    );
  });
}
