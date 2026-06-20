/// Pins the **early-advance**, **confirm-then-advance**, and **timeout**
/// branches of `e2eAdvanceOneHumanTurn` (Refs GitHub #2336 AC2 / AC5 / AC10).
///
/// `e2eAdvanceOneHumanTurn` is the most-called E2E helper in the suite — every
/// turn step in `new_game_full_turn_e2e_test.dart` and
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls it once. Its
/// pre-pump short-circuit (`earlyAfter`) lets the helper skip the inner
/// [e2eWaitForNextTurnLabelAdvance] call when the next-turn label has already
/// changed by the time the post-tap settle finishes (for example a synchronous
/// turn resolution on `kCtE2EEnabled`). The confirm-then-advance branch covers
/// the canonical asynchronous resolution path where a `common_yes` confirm
/// dialog opens after the next-turn tap and the helper must tap it before
/// waiting for the label to change. The timeout branch ensures persistent
/// absence (no confirm dialog, no label change) surfaces a [TestFailure] from
/// the inner `e2eWaitForNextTurnLabelAdvance` call so a future regression that
/// silently no-ops the helper is caught at the widget-test layer.
///
/// `integration_test/` is not part of the PR `quality` workflow (see
/// `SPEC/program/e2e-integration-tests.md` § CI — `app_e2e_linux` lane is a
/// no-op), so this widget-test pin is the only automated guard against a
/// regression of these branches in PR checks. Companion pins:
///
///   - `e2e_wait_for_next_turn_label_advance_test.dart` (#2620) pins the
///     inner helper's pre-pump short-circuit and processing-dialog gate.
///   - `e2e_open_panel_prepump_test.dart` (#2586) pins the same prepump
///     short-circuit pattern on the civilian/naval panel openers.
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Initial next-turn label the host renders before any flip lands. The
/// helper reads this via `e2eReadNextTurnButtonLabel` (single descendant
/// `Text` rule pinned in `e2e_wait_for_next_turn_label_advance_test.dart`)
/// so the button child must remain a single `Text` widget here.
const String _labelBefore = 'Next turn (1 / 1492)';

/// Label the host flips to in the early-advance and confirm-then-advance
/// scenarios. Differs from [_labelBefore] in the `(turn / year)` slot so the
/// helper sees a strict `before != after` transition.
const String _labelAfter = 'Next turn (2 / 1492)';

/// Stateful host that mounts a key-tagged next-turn button (with whichever
/// label [_NextTurnAdvanceController] currently reports) plus an optional
/// `common_yes` confirm chip whose tap callback fires
/// [_NextTurnAdvanceController.onConfirmTapped]. A fake-async `Timer`
/// scheduled in [State.initState] can flip the label or the dialog
/// visibility after a delay so the helper's pump loop observes the change
/// without the test calling `tester.pump` itself (the same pattern as
/// `e2e_wait_for_next_turn_label_advance_test.dart`).
class _NextTurnAdvanceHost extends StatefulWidget {
  const _NextTurnAdvanceHost({
    required this.controller,
    this.flipAfter,
    this.flipToLabel,
    this.flipToShowConfirm,
  });

  final _NextTurnAdvanceController controller;
  final Duration? flipAfter;
  final String? flipToLabel;
  final bool? flipToShowConfirm;

  @override
  State<_NextTurnAdvanceHost> createState() => _NextTurnAdvanceHostState();
}

class _NextTurnAdvanceHostState extends State<_NextTurnAdvanceHost> {
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
    final newShow = widget.flipToShowConfirm;
    if (newShow != null) {
      widget.controller.showConfirm = newShow;
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
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Center(
          child: TextButton(
            key: kGameMapNextTurnButtonKey,
            onPressed: widget.controller.onNextTurnTapped,
            child: Text(widget.controller.label),
          ),
        ),
        if (widget.controller.showConfirm)
          Positioned(
            top: 32,
            left: 32,
            child: Material(
              child: TextButton(
                onPressed: widget.controller.onConfirmTapped,
                child: Text(l10n.common_yes),
              ),
            ),
          ),
      ],
    );
  }
}

class _NextTurnAdvanceController extends ChangeNotifier {
  _NextTurnAdvanceController({
    required String initialLabel,
    bool initialShowConfirm = false,
    this.onNextTurnTapped,
    this.onConfirmTapped,
  })  : _label = initialLabel,
        _showConfirm = initialShowConfirm;

  String _label;
  bool _showConfirm;

  /// Optional hook fired when the next-turn button is tapped. Used by the
  /// `taps next-turn-button before checking for confirm` sanity assertion.
  final VoidCallback? onNextTurnTapped;

  /// Optional hook fired when the `common_yes` confirm chip is tapped. The
  /// confirm-then-advance test uses this to hide the dialog and schedule
  /// the label flip on the very tap that the helper performs.
  final VoidCallback? onConfirmTapped;

  String get label => _label;
  set label(String value) {
    if (_label == value) return;
    _label = value;
    notifyListeners();
  }

  bool get showConfirm => _showConfirm;
  set showConfirm(bool value) {
    if (_showConfirm == value) return;
    _showConfirm = value;
    notifyListeners();
  }
}

Future<void> _pumpHost(
  WidgetTester tester,
  _NextTurnAdvanceController controller, {
  Duration? flipAfter,
  String? flipToLabel,
  bool? flipToShowConfirm,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: _NextTurnAdvanceHost(
          controller: controller,
          flipAfter: flipAfter,
          flipToLabel: flipToLabel,
          flipToShowConfirm: flipToShowConfirm,
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'returns via earlyAfter when label advances before confirm appears',
    (WidgetTester tester) async {
      var nextTurnTaps = 0;
      var confirmTaps = 0;
      final controller = _NextTurnAdvanceController(
        initialLabel: _labelBefore,
        onNextTurnTapped: () {
          nextTurnTaps += 1;
        },
        onConfirmTapped: () {
          confirmTaps += 1;
        },
      );
      // Flip the label after 80ms of fake-async time. The helper's
      // `e2ePumpUntilConditionOrIdle` loop advances clock past this Timer
      // deadline and observes the change before any confirm appears, so
      // the helper should short-circuit via the `earlyAfter` branch and
      // skip the inner `e2eWaitForNextTurnLabelAdvance` call entirely.
      await _pumpHost(
        tester,
        controller,
        flipAfter: const Duration(milliseconds: 80),
        flipToLabel: _labelAfter,
      );

      final l10n = await AppLocalizationsBinding.delegate.load(
        const Locale('en'),
      );
      final returned = await e2eAdvanceOneHumanTurn(
        tester,
        l10n: l10n,
        timeout: const Duration(seconds: 5),
      );

      expect(
        nextTurnTaps,
        1,
        reason:
            'Helper must tap the next-turn button exactly once on entry, '
            'regardless of which branch it returns through (earlyAfter or '
            'confirm-then-advance).',
      );
      expect(
        confirmTaps,
        0,
        reason:
            'earlyAfter branch must skip the confirm tap entirely when the '
            'label already changed during the post-tap settle (#2336 AC5: '
            'condition-based wait short-circuits the slower fallback).',
      );
      expect(
        controller.label,
        _labelAfter,
        reason:
            'Sanity check: the scheduled flip must have landed before the '
            'helper returned, otherwise the earlyAfter branch would not '
            'have been exercised.',
      );
      expect(
        returned,
        lessThan(const Duration(seconds: 5)),
        reason:
            'Helper must complete strictly within its timeout when the '
            'label change is observed; reaching the timeout indicates the '
            'earlyAfter branch missed the flip and fell through to the '
            'inner waiter.',
      );
    },
  );

  testWidgets(
    'taps confirm and waits for label advance when confirm dialog appears',
    (WidgetTester tester) async {
      var nextTurnTaps = 0;
      var confirmTaps = 0;
      _NextTurnAdvanceController? controllerRef;
      Timer? labelFlipTimer;
      final controller = _NextTurnAdvanceController(
        initialLabel: _labelBefore,
        initialShowConfirm: true,
        onNextTurnTapped: () {
          nextTurnTaps += 1;
        },
        onConfirmTapped: () {
          confirmTaps += 1;
          // Hide the dialog and schedule the label flip from the very tap
          // the helper performs on the confirm chip — mirrors the
          // canonical app path where confirming the next turn kicks off
          // turn resolution and the map chip label updates a beat later.
          controllerRef?.showConfirm = false;
          labelFlipTimer = Timer(const Duration(milliseconds: 60), () {
            controllerRef?.label = _labelAfter;
          });
        },
      );
      controllerRef = controller;
      addTearDown(() => labelFlipTimer?.cancel());

      await _pumpHost(tester, controller);
      expect(
        find.text('Yes').hitTestable(),
        findsOneWidget,
        reason:
            'Pre-condition: confirm chip must be hit-testable on first '
            'pump so the helper observes it on the post-tap settle.',
      );

      final l10n = await AppLocalizationsBinding.delegate.load(
        const Locale('en'),
      );
      final returned = await e2eAdvanceOneHumanTurn(
        tester,
        l10n: l10n,
        timeout: const Duration(seconds: 5),
      );

      expect(
        nextTurnTaps,
        1,
        reason: 'Helper must tap the next-turn button exactly once on entry.',
      );
      expect(
        confirmTaps,
        1,
        reason:
            'Confirm-then-advance branch must tap the `common_yes` chip '
            'exactly once when it appears in the post-tap window. A 0 here '
            'indicates the helper short-circuited on a stale label change; '
            'a >1 indicates a duplicate confirm tap regression.',
      );
      expect(
        controller.label,
        _labelAfter,
        reason:
            'Sanity check: the scheduled label flip after confirm must have '
            'landed before the helper returned.',
      );
      expect(
        controller.showConfirm,
        isFalse,
        reason:
            'Sanity check: confirm dialog must have dismissed in response '
            'to the helper\'s tap before the helper returned.',
      );
      expect(
        returned,
        lessThan(const Duration(seconds: 5)),
        reason:
            'Helper must observe the post-confirm label advance and return '
            'within the 5s budget; reaching the timeout would indicate the '
            'inner waiter missed the flip.',
      );
    },
  );

  testWidgets(
    'fails with TestFailure when neither confirm nor label advance occurs',
    (WidgetTester tester) async {
      final controller = _NextTurnAdvanceController(
        initialLabel: _labelBefore,
      );
      await _pumpHost(tester, controller);
      final l10n = await AppLocalizationsBinding.delegate.load(
        const Locale('en'),
      );
      Object? caught;
      try {
        await e2eAdvanceOneHumanTurn(
          tester,
          l10n: l10n,
          timeout: const Duration(milliseconds: 250),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Persistent absence (no confirm dialog, no label change) must '
            'surface a TestFailure via the inner waiter so a future '
            'regression that silently no-ops the helper is caught at the '
            'widget-test layer (#2336 AC10: no new flakiness).',
      );
      expect(
        controller.label,
        _labelBefore,
        reason:
            'Sanity check: label must remain at the pre-tap value through '
            'the timeout path so the test does not coincidentally observe '
            'an unscheduled flip.',
      );
    },
  );
}
