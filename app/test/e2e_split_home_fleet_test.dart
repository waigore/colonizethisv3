/// Pins the `e2eSplitHomeFleetOnce` integration contract from
/// `app/integration_test/e2e_test_shared_panels.dart`
/// (Refs GitHub #2336 — AC2 single canonical helper, AC4 H8 split-dialog
/// pump replacement, AC5 condition-based confirmation wait, AC10 no
/// silent flakiness).
///
/// The helper is the canonical shared driver for the **Split** path of
/// the fleet-reach E2E (`new_game_fleet_reaches_new_world_e2e_test.dart`
/// + part files): open naval panel → tap **Split** → nudge ship counts
/// from the original to the new fleet via the
/// `ctTransfer.left.>>` / `ctTransfer.left.>` `CtNinePatchButton`
/// children of `CtDialogShell` → wait for the `splitFleet_confirm`
/// button to become **enabled** → tap it → wait for the
/// `splitFleet_dialogTitle` to disappear → re-expand any collapsed
/// `ExpansionTile` left in the naval panel.
///
/// Other tests in the suite explicitly call this helper out as the
/// motivating use case for the strict / best-effort `e2ePumpUntil` pins
/// (`app/test/e2e_pump_until_test.dart`,
/// `app/test/e2e_wait_until_found_test.dart`), but `e2eSplitHomeFleetOnce`
/// itself had no direct widget-level pin. Without these tests a
/// regression in the helper (for example dropping the move-all preference
/// over move-one, over-nudging past `splitConfirmEnabled()`, skipping the
/// trailing re-expand, or no-op'ing the dialog dismissal poll) would only
/// surface as a confusing flake on the wall-clock-bound fleet-reach
/// scenario the issue is reducing.
///
/// Because `integration_test/` is gated behind a no-op `app_e2e_linux`
/// lane (`SPEC/program/e2e-integration-tests.md` § CI), the behavioural
/// pins live in this widget-test layer alongside the sibling opener pins
/// (`app/test/e2e_open_civilian_panel_test.dart`,
/// `app/test/e2e_open_panel_prepump_test.dart`).
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

const String _kMoveOneKey = 'ctTransfer.left.>';
const String _kMoveAllKey = 'ctTransfer.left.>>';

/// Controller a test pumps through to inspect helper behaviour without
/// coupling to fleet model state. Tracks total nudge taps, surfaces
/// confirm-tap signals, and gates dialog dismissal.
class _SplitHarnessController extends ChangeNotifier {
  _SplitHarnessController({
    required this.nudgesUntilConfirm,
    this.includeMoveAll = true,
  });

  /// Number of left-transfer button taps required before
  /// `splitFleet_confirm` becomes enabled.
  final int nudgesUntilConfirm;

  /// Whether the harness exposes the `>>` move-all button alongside the
  /// `>` move-one button. When false the helper must fall back to the
  /// single-nudge button.
  final bool includeMoveAll;

  int nudgeCount = 0;
  int moveAllTaps = 0;
  int moveOneTaps = 0;
  int confirmTaps = 0;
  bool dialogVisible = false;

  bool get confirmEnabled => nudgeCount >= nudgesUntilConfirm;

  void openDialog() {
    dialogVisible = true;
    notifyListeners();
  }

  void registerMoveAll() {
    moveAllTaps += 1;
    nudgeCount += 1;
    notifyListeners();
  }

  void registerMoveOne() {
    moveOneTaps += 1;
    nudgeCount += 1;
    notifyListeners();
  }

  void registerConfirm() {
    confirmTaps += 1;
    dialogVisible = false;
    notifyListeners();
  }
}

class _SplitHarness extends StatefulWidget {
  const _SplitHarness({
    required this.controller,
    required this.l10n,
    this.includeExpansionTile = false,
  });

  final _SplitHarnessController controller;
  final AppLocalizations l10n;

  /// Whether to render a collapsed `ExpansionTile` inside the naval-panel
  /// subtree so the trailing `e2eExpandEachExpansionTileOnce` step has
  /// something to act on.
  final bool includeExpansionTile;

  @override
  State<_SplitHarness> createState() => _SplitHarnessState();
}

class _SplitHarnessState extends State<_SplitHarness> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final l10n = widget.l10n;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          KeyedSubtree(
            key: kCtE2ENavalPanelRootKey,
            child: ListView(
              children: <Widget>[
                if (widget.includeExpansionTile)
                  const ExpansionTile(
                    initiallyExpanded: false,
                    title: Text('Home Fleet'),
                    children: <Widget>[Text('Carrack')],
                  ),
                TextButton(
                  onPressed: controller.openDialog,
                  child: const Text('Split'),
                ),
              ],
            ),
          ),
          if (controller.dialogVisible)
            Positioned.fill(
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: CtDialogShell(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(l10n.splitFleet_dialogTitle),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            if (widget.controller.includeMoveAll)
                              CtNinePatchButton(
                                key: const ValueKey<String>(_kMoveAllKey),
                                onPressed: controller.registerMoveAll,
                                child: const Text('>>'),
                              ),
                            CtNinePatchButton(
                              key: const ValueKey<String>(_kMoveOneKey),
                              onPressed: controller.registerMoveOne,
                              child: const Text('>'),
                            ),
                          ],
                        ),
                        CtNinePatchButton(
                          enabled: controller.confirmEnabled,
                          onPressed: controller.registerConfirm,
                          child: Text(l10n.splitFleet_confirm),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required _SplitHarnessController controller,
  required AppLocalizations l10n,
  bool includeExpansionTile = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: _SplitHarness(
        controller: controller,
        l10n: l10n,
        includeExpansionTile: includeExpansionTile,
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'taps Split inside naval panel, performs exactly one nudge, '
    'and confirms when one nudge enables the confirm button',
    (WidgetTester tester) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final controller = _SplitHarnessController(nudgesUntilConfirm: 1);
      await _pumpHarness(tester, controller: controller, l10n: l10n);

      await e2eSplitHomeFleetOnce(
        tester,
        l10n,
        navalPanelAlreadyOpen: true,
      );

      expect(
        controller.dialogVisible,
        isFalse,
        reason:
            'Helper must tap the confirm button so the split dialog '
            'unmounts (Refs GitHub #2336 H8 split-dialog pump '
            'replacement).',
      );
      expect(
        controller.confirmTaps,
        1,
        reason:
            'Helper must tap the confirm button exactly once on the '
            'success path.',
      );
      expect(
        controller.nudgeCount,
        1,
        reason:
            'Helper must stop nudging the moment `splitFleet_confirm` '
            'flips to enabled — over-nudging would defeat the AC5 '
            'condition-based wait by paying full per-attempt settles.',
      );
      expect(
        controller.moveAllTaps,
        1,
        reason:
            'When the `ctTransfer.left.>>` move-all button is enabled, '
            'the helper must prefer it over the single-nudge button '
            '(Refs GitHub #2336 AC4 H8).',
      );
      expect(
        controller.moveOneTaps,
        0,
        reason:
            'Move-all preference must skip the `ctTransfer.left.>` '
            'fallback while move-all is available.',
      );
    },
  );

  testWidgets(
    'falls back to the single-nudge `ctTransfer.left.>` button '
    'when the move-all `>>` button is absent',
    (WidgetTester tester) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final controller = _SplitHarnessController(
        nudgesUntilConfirm: 1,
        includeMoveAll: false,
      );
      await _pumpHarness(tester, controller: controller, l10n: l10n);

      await e2eSplitHomeFleetOnce(
        tester,
        l10n,
        navalPanelAlreadyOpen: true,
      );

      expect(
        controller.dialogVisible,
        isFalse,
        reason:
            'Dialog must dismiss even when only the `>` nudge button is '
            'available.',
      );
      expect(
        controller.confirmTaps,
        1,
        reason:
            'Helper must reach the confirm tap on the move-one fallback '
            'path.',
      );
      expect(
        controller.moveAllTaps,
        0,
        reason:
            'No move-all button is mounted; helper must not synthesize '
            'a `>>` tap.',
      );
      expect(
        controller.moveOneTaps,
        1,
        reason:
            'Helper must drive the `>` nudge once when that is the only '
            'enabled transfer button available.',
      );
    },
  );

  testWidgets(
    'iterates the bounded nudge loop until `splitFleet_confirm` '
    'becomes enabled when several nudges are required',
    (WidgetTester tester) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final controller = _SplitHarnessController(nudgesUntilConfirm: 3);
      await _pumpHarness(tester, controller: controller, l10n: l10n);

      await e2eSplitHomeFleetOnce(
        tester,
        l10n,
        navalPanelAlreadyOpen: true,
      );

      expect(
        controller.dialogVisible,
        isFalse,
        reason:
            'Helper must reach the confirm path after iterating the '
            'nudge loop, not bail when more than one nudge is required.',
      );
      expect(
        controller.confirmTaps,
        1,
        reason:
            'Helper must still tap the confirm button exactly once '
            'after the multi-nudge ramp.',
      );
      expect(
        controller.nudgeCount,
        3,
        reason:
            'Helper must stop nudging once the predicate flips — over '
            'or under-nudging would either waste pump frames or leave '
            'the confirm button disabled past the 5s strict pump.',
      );
      expect(
        controller.moveAllTaps,
        3,
        reason:
            'Move-all preference must hold for every iteration while '
            '`>>` is enabled.',
      );
    },
  );

  testWidgets(
    'short-circuits the nudge loop when `splitFleet_confirm` '
    'is already enabled on dialog entry',
    (WidgetTester tester) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final controller = _SplitHarnessController(nudgesUntilConfirm: 0);
      await _pumpHarness(tester, controller: controller, l10n: l10n);

      await e2eSplitHomeFleetOnce(
        tester,
        l10n,
        navalPanelAlreadyOpen: true,
      );

      expect(
        controller.dialogVisible,
        isFalse,
        reason:
            'Helper must reach the confirm tap without paying any nudge '
            'frame when the dialog opens with confirm already enabled.',
      );
      expect(
        controller.confirmTaps,
        1,
        reason: 'Confirm button must be tapped exactly once.',
      );
      expect(
        controller.nudgeCount,
        0,
        reason:
            'Helper must not nudge when confirm is already enabled '
            '(short-circuits the `for (attempt < 6 && !splitConfirmEnabled())` '
            'guard on entry).',
      );
    },
  );

  testWidgets(
    'expands every collapsed `ExpansionTile` left in the naval panel '
    'after the split dialog dismisses',
    (WidgetTester tester) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final controller = _SplitHarnessController(nudgesUntilConfirm: 1);
      await _pumpHarness(
        tester,
        controller: controller,
        l10n: l10n,
        includeExpansionTile: true,
      );

      final tileFinder = find.byType(ExpansionTile);
      expect(tileFinder, findsOneWidget);
      expect(
        e2eExpansionTileIsExpanded(tileFinder.evaluate().single),
        isFalse,
        reason: 'Expansion tile must start collapsed for the trailing '
            're-expand contract to mean something.',
      );

      await e2eSplitHomeFleetOnce(
        tester,
        l10n,
        navalPanelAlreadyOpen: true,
      );

      expect(
        e2eExpansionTileIsExpanded(tileFinder.evaluate().single),
        isTrue,
        reason:
            'Helper must call `e2eExpandEachExpansionTileOnce` after '
            'dismissing the split dialog so the naval-panel sheet is '
            'left in the same expanded state subsequent fleet-reach '
            'iterations rely on (Refs GitHub #2336 H6 expand-tile '
            'helper reuse).',
      );
    },
  );
}
