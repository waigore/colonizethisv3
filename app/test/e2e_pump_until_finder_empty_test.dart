/// Pins the **pre-pump short-circuit**, **finder-flip-during-pump**, and
/// **best-effort timeout** branches of `e2ePumpUntilFinderEmpty`
/// in `app/integration_test/e2e_test_shared.dart` (Refs GitHub #2336 AC5 /
/// `SPEC/program/e2e-integration-tests.md` § Adaptive poll pacing).
///
/// `e2ePumpUntilFinderEmpty` is the post-dismiss settle primitive used by
/// `e2eCloseBottomSheet` to wait for a [BottomSheet] to leave the widget
/// tree after a single back-route pop. The helper must:
///
/// 1. Short-circuit before any pump when the finder already matches nothing
///    (callers chain it after a pop and the route may already be gone).
/// 2. Pump with `e2eAdaptivePollRampAfterIdle` pacing until the finder is
///    empty, returning the moment the widget leaves the tree (no fixed
///    300–500ms tail wait — that overhead drove the wall-clock blowups
///    #2336 is reducing).
/// 3. Return silently on timeout (no `fail()`); a stuck finder is treated
///    as a best-effort settle the caller can escalate, **not** a test
///    failure.
///
/// A silent regression in any of these branches (for example a swap to
/// `await tester.pumpAndSettle()`, a fixed 50ms initial pump, or a
/// `fail()` on the timeout path) would only surface as a confusing E2E
/// flake or a missed wall-clock reduction; this widget-test layer pins
/// the contract directly since `integration_test/` is gated by the
/// no-op `app_e2e_linux` lane today.
library;

import 'dart:async';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Host that removes an internal child widget after an optional fake-async
/// delay so a polling helper can observe the disappearance without the
/// test calling `tester.pump` itself (which would deadlock against the
/// helper's guarded pump loop).
class _DelayedRemovalHost extends StatefulWidget {
  const _DelayedRemovalHost({
    required this.removeAfter,
    required this.onState,
  });

  final Duration removeAfter;
  final void Function(_DelayedRemovalState state) onState;

  @override
  State<_DelayedRemovalHost> createState() => _DelayedRemovalState();
}

class _DelayedRemovalState extends State<_DelayedRemovalHost> {
  bool present = true;

  @override
  void initState() {
    super.initState();
    widget.onState(this);
    Timer(widget.removeAfter, () {
      if (!mounted) return;
      setState(() => present = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!present) {
      return const SizedBox.shrink();
    }
    return const Text('pin-target', textDirection: TextDirection.ltr);
  }
}

Future<_DelayedRemovalState> _pumpHost(
  WidgetTester tester, {
  required Duration removeAfter,
}) async {
  late _DelayedRemovalState captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _DelayedRemovalHost(
          removeAfter: removeAfter,
          onState: (s) => captured = s,
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  suppressLogsForTests();

  group('e2ePumpUntilFinderEmpty', () {
    testWidgets(
      'short-circuits before any pump when finder is already empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final sw = Stopwatch()..start();
        await e2ePumpUntilFinderEmpty(
          tester,
          find.text('never-mounted'),
          timeout: const Duration(seconds: 5),
        );
        expect(
          sw.elapsed,
          lessThan(const Duration(milliseconds: 200)),
          reason:
              'Pre-pump short-circuit must return well before the timeout '
              'cap when the finder is already empty on entry. Callers chain '
              'this after a pop and the post-dismiss frame may already have '
              'cleared the target, so any pump cycle here is wasted work '
              'against the wall-clock budget (#2336 AC5).',
        );
      },
    );

    testWidgets(
      'returns once a scheduled removal makes the finder empty during pump',
      (WidgetTester tester) async {
        final state = await _pumpHost(
          tester,
          removeAfter: const Duration(milliseconds: 80),
        );
        expect(state.present, isTrue);
        expect(find.text('pin-target'), findsOneWidget);

        await e2ePumpUntilFinderEmpty(
          tester,
          find.text('pin-target'),
          timeout: const Duration(seconds: 5),
        );

        expect(
          find.text('pin-target'),
          findsNothing,
          reason:
              'The finder must be observed empty at return time — that is '
              'the exact condition the adaptive pump loop waits on for the '
              'post-dismiss settle in `e2eCloseBottomSheet`.',
        );
      },
    );

    testWidgets(
      'returns without throwing when finder is persistently non-empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('persistent-target', textDirection: TextDirection.ltr),
            ),
          ),
        );
        expect(find.text('persistent-target'), findsOneWidget);

        Object? caught;
        try {
          await e2ePumpUntilFinderEmpty(
            tester,
            find.text('persistent-target'),
            timeout: const Duration(milliseconds: 200),
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'Best-effort variant must NOT call fail() on timeout so '
              'callers can treat the wait as an optional post-dismiss '
              'settle and decide whether to escalate (#2336 AC5).',
        );
        expect(
          find.text('persistent-target'),
          findsOneWidget,
          reason:
              'A persistent target must still be present after the silent '
              'timeout return so callers retain a true post-condition for '
              'their own escalation logic.',
        );
      },
    );

    testWidgets(
      'respects the timeout window when the finder never empties',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('stuck-target', textDirection: TextDirection.ltr),
            ),
          ),
        );
        final sw = Stopwatch()..start();
        await e2ePumpUntilFinderEmpty(
          tester,
          find.text('stuck-target'),
          timeout: const Duration(milliseconds: 150),
        );
        expect(
          sw.elapsed,
          lessThan(const Duration(seconds: 2)),
          reason:
              'The helper must honour the caller-supplied timeout window; '
              'a stuck finder must not pump indefinitely past the cap, '
              'otherwise wall-clock budgets cannot be reasoned about at '
              'the call site (#2336 AC5).',
        );
      },
    );
  });
}
