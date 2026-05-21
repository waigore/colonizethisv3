/// Branch-waterfall pin for `e2eWaitForMapHudAfterNewGameStart`.
///
/// Canonical new-game → map HUD bootstrap polls this helper after leader
/// confirmation (Refs GitHub #2336 AC5 / Bottleneck 3). Integration tests
/// cannot run in default CI, so the widget layer locks each short-circuit:
///
/// 1. `Could not create game` visible → immediate [TestFailure] (no retry).
/// 2. [kHomeToCapitalButtonKey] mounted → calls [e2eAdvanceGameStartIntroUntilDismissed] then returns.
/// 3. [e2eGameStartIntroBlocksUi] true → intro advance path (when home key absent).
/// 4. `Creating game` visible → exponential-backoff idle pumps only.
/// 5. None of the above before [overallCap] → timeout [TestFailure].
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';
import '../integration_test/e2e_test_shared_bootstrap.dart';

/// Mounts [child] after [delay] so tests can observe the helper's poll loop
/// without calling [WidgetTester.pump] while the helper is awaiting.
class _DelayedMountHost extends StatefulWidget {
  const _DelayedMountHost({
    required this.delay,
    required this.child,
  });

  final Duration delay;
  final Widget child;

  @override
  State<_DelayedMountHost> createState() => _DelayedMountHostState();
}

class _DelayedMountHostState extends State<_DelayedMountHost> {
  Timer? _timer;
  var _showChild = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) {
        setState(() => _showChild = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _showChild ? widget.child : const SizedBox.shrink(),
      ),
    );
  }
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'Branch 1 (error fail-fast): fails immediately when setup error text is visible',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Could not create game')),
        ),
      );

      Object? caught;
      try {
        await e2eWaitForMapHudAfterNewGameStart(
          tester,
          overallCap: const Duration(seconds: 5),
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<TestFailure>());
      expect(
        '$caught',
        allOf(
          contains('New game setup failed'),
          contains('error dialog'),
        ),
        reason:
            'Branch 1: setup failure must surface on the first loop iteration '
            'without waiting for the overall cap (#2336 bootstrap contract).',
      );
    },
  );

  testWidgets(
    'Branch 2 (map HUD ready): returns once home→capital control is mounted',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              key: kHomeToCapitalButtonKey,
              onPressed: () {},
              child: const Text('Home'),
            ),
          ),
        ),
      );

      final sw = Stopwatch()..start();
      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 5),
      );
      expect(
        sw.elapsed < const Duration(seconds: 2),
        isTrue,
        reason:
            'Branch 2: a mounted home→capital key must complete quickly after '
            'the no-op intro advance short-circuit (#2336 AC5).',
      );
    },
  );

  testWidgets(
    'Branch 4 (creating game): backoff-polls until overall cap without home key',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Creating game')),
        ),
      );

      Object? caught;
      final sw = Stopwatch()..start();
      try {
        await e2eWaitForMapHudAfterNewGameStart(
          tester,
          overallCap: const Duration(milliseconds: 250),
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<TestFailure>());
      expect(
        '$caught',
        contains('map (home→capital)'),
        reason:
            'Branch 4: spinner-only setup text must not satisfy the HUD-ready '
            'exit without the home→capital key.',
      );
      expect(
        sw.elapsed >= const Duration(milliseconds: 200),
        isTrue,
        reason:
            'Branch 4: the creating-game branch must spend wall clock on '
            'backoff pumps before the cap elapses.',
      );
    },
  );

  testWidgets(
    'Branch 2 (delayed mount): completes after home key appears mid-poll',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _DelayedMountHost(
          delay: const Duration(milliseconds: 80),
          child: TextButton(
            key: kHomeToCapitalButtonKey,
            onPressed: () {},
            child: const Text('Home'),
          ),
        ),
      );

      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 2),
      );

      expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
    },
  );
}
