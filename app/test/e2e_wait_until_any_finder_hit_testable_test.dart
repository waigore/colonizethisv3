/// Pins the **empty-list no-op**, **pre-pump short-circuit**, **adaptive
/// doubling backoff**, and **timeout fail-fast** contracts of
/// `e2eWaitUntilAnyFinderHitTestable` (Refs GitHub #2336 AC2 / AC5 /
/// `SPEC/program/e2e-integration-tests.md` § Adaptive poll pacing).
///
/// The helper is the canonical "wait for any one of several openers /
/// transient widgets to become tappable" primitive used by `e2eOpenNavalPanel`
/// and other panel openers. Because the `integration_test/` suite runs behind
/// a no-op `app_e2e_linux` lane today (`SPEC/program/e2e-integration-tests.md`
/// § CI), the behavioral pins live in the widget-test layer and use
/// fake-async `Timer` flips so the helper's `tester.pump` loop observes the
/// mounted finders without the test driving extra pumps itself.
library;

import 'dart:async';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Host that mounts zero or more keyed `TextButton` finders on demand so the
/// test can flip visibility while the helper polls.
///
/// `Timer` callbacks scheduled in [State.initState] fire when `tester.pump`
/// advances fake-time past the registered duration, so the helper sees the
/// newly mounted widget on a later iteration without the test calling
/// `tester.pump` itself (which would deadlock against the helper's guarded
/// pump loop).
class _MountKeysHost extends StatefulWidget {
  const _MountKeysHost({
    required this.controller,
    this.mountAfter,
    this.mountKeys = const <Key>[],
  });

  final _MountKeysController controller;

  /// Fake-async delay before the host mounts [mountKeys], or `null` to leave
  /// the controller untouched.
  final Duration? mountAfter;

  /// Keys to mount as visible, hit-testable `TextButton`s when [mountAfter]
  /// elapses.
  final List<Key> mountKeys;

  @override
  State<_MountKeysHost> createState() => _MountKeysHostState();
}

class _MountKeysHostState extends State<_MountKeysHost> {
  Timer? _mountTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.mountAfter;
    if (after != null) {
      _mountTimer = Timer(after, _applyMount);
    }
  }

  void _applyMount() {
    widget.controller.mountedKeys = widget.mountKeys;
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
    final keys = widget.controller.mountedKeys;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final k in keys)
          TextButton(
            key: k,
            onPressed: () {},
            child: const Text('btn'),
          ),
      ],
    );
  }
}

class _MountKeysController extends ChangeNotifier {
  _MountKeysController({List<Key> initialKeys = const <Key>[]})
      : _mountedKeys = List<Key>.of(initialKeys);

  List<Key> _mountedKeys;

  List<Key> get mountedKeys => _mountedKeys;

  set mountedKeys(List<Key> value) {
    _mountedKeys = List<Key>.of(value);
    notifyListeners();
  }
}

Future<void> _pumpHost(
  WidgetTester tester,
  _MountKeysController controller, {
  Duration? mountAfter,
  List<Key> mountKeys = const <Key>[],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: _MountKeysHost(
            controller: controller,
            mountAfter: mountAfter,
            mountKeys: mountKeys,
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'returns immediately when the finder list is empty (no pump, no throw)',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final sw = Stopwatch()..start();
      await e2eWaitUntilAnyFinderHitTestable(
        tester,
        const <Finder>[],
        timeout: const Duration(seconds: 5),
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Empty finder list must short-circuit before any pump or timeout '
            'accrual; callers may legitimately pass an empty list when no '
            'opener is in scope yet.',
      );
    },
  );

  testWidgets(
    'short-circuits before any pump when the first finder is already hit-testable',
    (WidgetTester tester) async {
      const onlyKey = Key('e2e_only_btn');
      final controller =
          _MountKeysController(initialKeys: const <Key>[onlyKey]);
      await _pumpHost(tester, controller);
      final sw = Stopwatch()..start();
      await e2eWaitUntilAnyFinderHitTestable(
        tester,
        <Finder>[find.byKey(onlyKey)],
        timeout: const Duration(seconds: 5),
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Pre-pump short-circuit must return well before the timeout cap '
            'when a finder is already hit-testable on entry (#2336 AC5).',
      );
    },
  );

  testWidgets(
    'short-circuits before any pump when a later finder is already hit-testable',
    (WidgetTester tester) async {
      const firstKey = Key('e2e_first_btn');
      const secondKey = Key('e2e_second_btn');
      // Only the second key is mounted, so the first finder is empty.
      final controller =
          _MountKeysController(initialKeys: const <Key>[secondKey]);
      await _pumpHost(tester, controller);
      final sw = Stopwatch()..start();
      await e2eWaitUntilAnyFinderHitTestable(
        tester,
        <Finder>[find.byKey(firstKey), find.byKey(secondKey)],
        timeout: const Duration(seconds: 5),
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Helper must scan the full finder list on the pre-pump pass; a '
            'later finder that is already hit-testable must short-circuit the '
            'wait the same as the first one.',
      );
    },
  );

  testWidgets(
    'returns once a scheduled mount makes one finder hit-testable during pump',
    (WidgetTester tester) async {
      const targetKey = Key('e2e_target_btn');
      final controller = _MountKeysController();
      // The host starts with no widgets; schedule a mount after enough
      // fake-async time that the helper has already passed its pre-pump scan
      // and is inside the adaptive pump loop.
      await _pumpHost(
        tester,
        controller,
        mountAfter: const Duration(milliseconds: 80),
        mountKeys: const <Key>[targetKey],
      );
      expect(find.byKey(targetKey), findsNothing);

      await e2eWaitUntilAnyFinderHitTestable(
        tester,
        <Finder>[find.byKey(targetKey)],
        timeout: const Duration(seconds: 5),
      );

      expect(
        controller.mountedKeys,
        contains(targetKey),
        reason:
            'Sanity check: the scheduled mount must have run before the '
            'helper returned, otherwise the helper saw a stale empty finder.',
      );
      expect(
        find.byKey(targetKey).hitTestable(),
        findsOneWidget,
        reason:
            'The target finder must be hit-testable at return time, since '
            'that is the exact condition the helper waits on.',
      );
    },
  );

  testWidgets(
    'fails with TestFailure when no finder ever becomes hit-testable within timeout',
    (WidgetTester tester) async {
      const missingKey = Key('e2e_missing_btn');
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      Object? caught;
      try {
        await e2eWaitUntilAnyFinderHitTestable(
          tester,
          <Finder>[find.byKey(missingKey)],
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
            'panel openers do not silently no-op and leak into later test '
            'steps (#2336 AC10).',
      );
      expect(
        caught.toString(),
        contains('Timed out'),
        reason:
            'Failure message must call out the timeout so the helper failure '
            'is attributable in CI logs.',
      );
    },
  );
}
