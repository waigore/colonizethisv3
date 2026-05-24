/// Pins the **pre-pump short-circuit** and **`TurnResolutionProcessingDialog`
/// race-gate** contracts of `e2eWaitForNextTurnLabelAdvance` (Refs GitHub
/// #2336 AC2 / AC5).
///
/// The helper is the source of truth for "the next-turn map chip label
/// changed" in every E2E scenario (`e2eAdvanceOneHumanTurn`, fleet reach
/// turn loops, bundled explore retries). The integration test suite cannot
/// validate this in CI (`integration_test/` runs are gated behind a
/// no-op `app_e2e_linux` lane today, per `SPEC/program/e2e-integration-tests.md`
/// § CI), so the widget-test layer carries the behavioral pins.
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Host that mounts a key-tagged next-turn label (and an optional
/// [TurnResolutionProcessingDialog]) and exposes a fake-async `Timer`-driven
/// hook for tests to flip the label or dismiss the dialog while the
/// helper's `tester.pump` loop is running.
///
/// `Timer` callbacks scheduled in [State.initState] fire when `tester.pump`
/// advances fake-time past the registered duration, so the helper observes
/// the flip on a later polling iteration without the test needing to call
/// `tester.pump` itself (which would deadlock against the helper's guarded
/// pump).
class _NextTurnLabelHost extends StatefulWidget {
  const _NextTurnLabelHost({
    required this.controller,
    this.flipAfter,
    this.flipToLabel,
    this.flipToShowDialog,
  });

  final _NextTurnLabelController controller;

  /// Fake-async delay before the host flips the controller, or `null` to
  /// leave the controller untouched (no scheduled flip).
  final Duration? flipAfter;

  /// New label to apply when [flipAfter] elapses, or `null` to leave the
  /// label unchanged.
  final String? flipToLabel;

  /// New processing-dialog visibility to apply when [flipAfter] elapses,
  /// or `null` to leave the visibility unchanged.
  final bool? flipToShowDialog;

  @override
  State<_NextTurnLabelHost> createState() => _NextTurnLabelHostState();
}

class _NextTurnLabelHostState extends State<_NextTurnLabelHost> {
  Timer? _flipTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.flipAfter;
    if (after != null) {
      _flipTimer = Timer(after, _applyFlip);
    }
  }

  void _applyFlip() {
    final newLabel = widget.flipToLabel;
    if (newLabel != null) {
      widget.controller.label = newLabel;
    }
    final newDialog = widget.flipToShowDialog;
    if (newDialog != null) {
      widget.controller.showProcessingDialog = newDialog;
    }
  }

  @override
  void dispose() {
    _flipTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showDialog = widget.controller.showProcessingDialog;
    final label = widget.controller.label;
    return Stack(
      children: [
        Center(
          child: TextButton(
            key: kGameMapNextTurnButtonKey,
            onPressed: () {},
            child: Text(label),
          ),
        ),
        if (showDialog)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x88000000),
              child: Center(
                child: TurnResolutionProcessingDialog(
                  phaseText: 'Validating orders...',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NextTurnLabelController extends ChangeNotifier {
  _NextTurnLabelController({
    required String initialLabel,
    bool initialShowProcessingDialog = false,
  })  : _label = initialLabel,
        _showProcessingDialog = initialShowProcessingDialog;

  String _label;
  bool _showProcessingDialog;

  String get label => _label;

  set label(String value) {
    if (_label == value) {
      return;
    }
    _label = value;
    notifyListeners();
  }

  bool get showProcessingDialog => _showProcessingDialog;

  set showProcessingDialog(bool value) {
    if (_showProcessingDialog == value) {
      return;
    }
    _showProcessingDialog = value;
    notifyListeners();
  }
}

Future<void> _pumpHost(
  WidgetTester tester,
  _NextTurnLabelController controller, {
  Duration? flipAfter,
  String? flipToLabel,
  bool? flipToShowDialog,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: _NextTurnLabelHost(
          controller: controller,
          flipAfter: flipAfter,
          flipToLabel: flipToLabel,
          flipToShowDialog: flipToShowDialog,
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'returns immediately when current label already differs from before',
    (WidgetTester tester) async {
      final controller = _NextTurnLabelController(
        initialLabel: 'Next turn (2 / 1492)',
      );
      await _pumpHost(tester, controller);
      final sw = Stopwatch()..start();
      final elapsed = await e2eWaitForNextTurnLabelAdvance(
        tester,
        turnLabelBefore: 'Next turn (1 / 1492)',
        timeout: const Duration(seconds: 5),
      );
      expect(
        elapsed,
        lessThan(const Duration(milliseconds: 100)),
        reason:
            'Pre-pump short-circuit must return ~Duration.zero when the label '
            'already changed before the helper started polling (#2336 AC5).',
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Wall-clock for the pre-pump short-circuit path must stay well '
            'under the timeout cap; large drift signals a regression in the '
            'condition-before-first-pump contract.',
      );
    },
  );

  testWidgets('returns once a scheduled label flip lands during pump', (
    WidgetTester tester,
  ) async {
    final controller = _NextTurnLabelController(
      initialLabel: 'Next turn (1 / 1492)',
    );
    // Schedule the host to flip the label after 80ms of fake-async time so
    // the helper's adaptive pump loop advances clock past the Timer
    // deadline and observes the change on a later iteration (no guarded
    // `tester.pump` from the test itself; #2336 AC5).
    await _pumpHost(
      tester,
      controller,
      flipAfter: const Duration(milliseconds: 80),
      flipToLabel: 'Next turn (2 / 1492)',
    );

    final returned = await e2eWaitForNextTurnLabelAdvance(
      tester,
      turnLabelBefore: 'Next turn (1 / 1492)',
      timeout: const Duration(seconds: 5),
    );

    expect(
      controller.label,
      'Next turn (2 / 1492)',
      reason:
          'Sanity check: the scheduled flip must have landed before the '
          'helper returned, otherwise the helper short-circuited on a '
          'stale label.',
    );
    expect(
      returned,
      lessThan(const Duration(seconds: 5)),
      reason:
          'Helper must complete strictly within its timeout when the label '
          'change is observed; reaching the timeout would indicate the '
          'adaptive backoff missed the flip.',
    );
  });

  testWidgets(
    'fails with TestFailure when label never advances within timeout',
    (WidgetTester tester) async {
      final controller = _NextTurnLabelController(
        initialLabel: 'Next turn (1 / 1492)',
      );
      await _pumpHost(tester, controller);
      Object? caught;
      try {
        await e2eWaitForNextTurnLabelAdvance(
          tester,
          turnLabelBefore: 'Next turn (1 / 1492)',
          timeout: const Duration(milliseconds: 200),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Persistent identical label must hit the timeout failure path so '
            'real regressions are not silently swallowed (#2336 AC10).',
      );
    },
  );

  testWidgets(
    'holds return until TurnResolutionProcessingDialog clears even if label already differs',
    (WidgetTester tester) async {
      final controller = _NextTurnLabelController(
        initialLabel: 'Next turn (2 / 1492)',
        initialShowProcessingDialog: true,
      );
      // Schedule dialog dismissal after a fake-async delay; the helper must
      // observe `sawProcessingDialog=true` on early iterations and refuse to
      // return until the dialog leaves the tree, even though the label
      // already differs from `turnLabelBefore`.
      await _pumpHost(
        tester,
        controller,
        flipAfter: const Duration(milliseconds: 250),
        flipToShowDialog: false,
      );
      expect(find.byType(TurnResolutionProcessingDialog), findsOneWidget);

      final returned = await e2eWaitForNextTurnLabelAdvance(
        tester,
        turnLabelBefore: 'Next turn (1 / 1492)',
        timeout: const Duration(seconds: 5),
      );

      expect(
        find.byType(TurnResolutionProcessingDialog),
        findsNothing,
        reason:
            'Dialog must have cleared by the time the helper returned — '
            'otherwise the dialog-gate race was lost.',
      );
      expect(
        controller.showProcessingDialog,
        isFalse,
        reason:
            'Sanity check: the scheduled flip must have run before the '
            'helper returned.',
      );
      expect(
        returned,
        lessThan(const Duration(seconds: 5)),
        reason:
            'Once the processing dialog clears, the helper must observe the '
            'already-different label on the next adaptive poll step and '
            'return within the 5s budget.',
      );
    },
  );

  group('post-pump final check (timeout-edge correctness)', () {
    testWidgets(
      'returns elapsed via post-loop final check when the while loop is '
      'skipped (Duration.zero) and the label already differs',
      (WidgetTester tester) async {
        final controller = _NextTurnLabelController(
          initialLabel: 'Next turn (2 / 1492)',
        );
        await _pumpHost(tester, controller);

        // With `timeout: Duration.zero` the `while (sw.elapsed < timeout)`
        // loop deterministically never enters because `sw.elapsed >= 0`
        // from the moment the Stopwatch starts. The only opportunity to
        // observe the already-different label is the post-loop final
        // check. Without the fix the helper falls straight through to
        // `fail()`, mirroring the regression class covered for
        // `e2eWaitUntilFound` / `e2ePumpUntil` /
        // `e2eWaitUntilAnyFinderHitTestable` in `a4c07ebf4` (Refs GitHub
        // #2336 AC5 busy-wait final check).
        final returned = await e2eWaitForNextTurnLabelAdvance(
          tester,
          turnLabelBefore: 'Next turn (1 / 1492)',
          timeout: Duration.zero,
        );

        expect(
          returned,
          lessThan(const Duration(milliseconds: 100)),
          reason:
              'Post-loop final check must report ~Duration.zero — only the '
              'final check ran, the pump loop was skipped.',
        );
      },
    );

    testWidgets(
      'still fails with TestFailure when the label never advances and '
      'the loop is skipped (Duration.zero, additive contract)',
      (WidgetTester tester) async {
        final controller = _NextTurnLabelController(
          initialLabel: 'Next turn (1 / 1492)',
        );
        await _pumpHost(tester, controller);

        Object? caught;
        try {
          await e2eWaitForNextTurnLabelAdvance(
            tester,
            turnLabelBefore: 'Next turn (1 / 1492)',
            timeout: Duration.zero,
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'The post-loop final check is additive — when the label '
              'stays equal through both the (skipped) loop and the '
              'post-loop check, the helper must still hit the timeout '
              '`fail()` path so the absence is attributable in CI logs '
              '(Refs GitHub #2336 AC10).',
        );
        expect(
          caught.toString(),
          contains('did not advance'),
          reason:
              'Failure message must call out the missed label advance so '
              'the helper failure is attributable in CI logs.',
        );
      },
    );

    testWidgets(
      'post-loop final check refuses to return while the '
      'TurnResolutionProcessingDialog is still mounted',
      (WidgetTester tester) async {
        final controller = _NextTurnLabelController(
          initialLabel: 'Next turn (2 / 1492)',
          initialShowProcessingDialog: true,
        );
        await _pumpHost(tester, controller);
        expect(find.byType(TurnResolutionProcessingDialog), findsOneWidget);

        Object? caught;
        try {
          await e2eWaitForNextTurnLabelAdvance(
            tester,
            turnLabelBefore: 'Next turn (1 / 1492)',
            timeout: Duration.zero,
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'Even though the post-loop final check sees a different '
              'label, it must observe `sawProcessingDialog=true` AND a '
              'still-mounted dialog and therefore refuse to return — '
              'matching the in-loop dialog gate so the post-loop fix '
              'does not weaken the race contract pinned by the '
              'sibling "holds return until …" test (#2336 AC5).',
        );
      },
    );
  });

  testWidgets(
    'e2eReadNextTurnButtonLabel returns null when no next-turn button is mounted',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      expect(e2eReadNextTurnButtonLabel(tester), isNull);
    },
  );

  testWidgets(
    'e2eReadNextTurnButtonLabel returns null when subtree has more than one Text',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButton(
                key: kGameMapNextTurnButtonKey,
                onPressed: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Next turn'),
                    SizedBox(width: 4),
                    Text('(1 / 1492)'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        e2eReadNextTurnButtonLabel(tester),
        isNull,
        reason:
            'Two-text layout breaks the single-Text contract; helper must '
            'return null so callers fall back to other readiness signals '
            '(`SPEC/program/e2e-integration-tests.md`).',
      );
    },
  );
}
