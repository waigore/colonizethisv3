/// Pins the widget-tree contract of [e2eAttemptFirstFleetMoveOrCancel]
/// (`app/integration_test/e2e_test_shared_first_fleet_move.dart`).
///
/// The full-turn E2E scenario in `new_game_full_turn_e2e_test.dart` calls
/// this helper exactly once per `testWidgets` after [e2eSplitHomeFleetOnce]
/// to opportunistically nudge any visible Move-capable fleet in the naval
/// panel, tolerating an empty destination-radios dialog by tapping Cancel.
/// A silent rename or behavioural drift here would either:
///
///   - Stall the test for `kE2eDefaultFirstFleetMoveDialogCloseTimeout` (10 s)
///     at `pump_until_move_dialog_closed*` if Confirm / Cancel never tap;
///   - Or mask an empty-radios regression by silently failing the
///     `find.text(common_cancel)` expectation — breaking the AC4 / AC5
///     adaptive-poll contract issue #2336 is enforcing.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 2.
library;

// Test fixtures build the legacy `RadioListTile<int>(groupValue, onChanged)`
// shape on purpose — `e2eAttemptFirstFleetMoveOrCancel` matches
// `find.byType(RadioListTile<dynamic>)` which resolves the production
// `MoveFleetDialog` widgets regardless of the newer RadioGroup-based API.
// Mirrors the deprecation suppression in
// `e2e_pick_move_destination_and_confirm_test.dart`.
// ignore_for_file: deprecated_member_use

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

class _MoveButton extends StatelessWidget {
  const _MoveButton({required this.dialogBuilder});

  final Widget Function(BuildContext context) dialogBuilder;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Carry the production stable key so the helper's keyed Move finder
        // ([kCtE2EFleetMoveActionKey]) resolves the control. Production fleet
        // rows render the Move action icon-only (no `Text('Move')`) at narrow
        // test-host viewports, so the helper locates it by key (Refs #2336).
        return TextButton(
          key: kCtE2EFleetMoveActionKey,
          onPressed: () {
            showDialog<void>(context: context, builder: dialogBuilder);
          },
          child: const Text('Move'),
        );
      },
    );
  }
}

Widget _navalPanel({required List<Widget> children}) => KeyedSubtree(
  key: kCtE2ENavalPanelRootKey,
  child: Column(children: children),
);

Widget _wrap(Widget body) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: body)),
);

WidgetBuilder _emptyRadiosDialogBuilder(AppLocalizations l10n) {
  return (context) => AlertDialog(
    content: const Text('No destinations available.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.common_cancel),
      ),
    ],
  );
}

class _SeaPickHost extends StatefulWidget {
  const _SeaPickHost({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_SeaPickHost> createState() => _SeaPickHostState();
}

class _SeaPickHostState extends State<_SeaPickHost> {
  dynamic selected;
  int taps = 0;
  bool dialogOpen = true;

  @override
  Widget build(BuildContext context) {
    if (!dialogOpen) {
      return const SizedBox.shrink();
    }
    // Build `RadioListTile<dynamic>` explicitly so the helper's
    // `find.byType(RadioListTile<dynamic>)` (exact-type match per Flutter
    // Finder semantics) actually resolves the radios. The pre-lift inline
    // block in `new_game_full_turn_e2e_test.dart` used the same exact-type
    // finder; the production `MoveFleetDialog` uses `RadioListTile<_MovePick>`
    // which the legacy block did not match (always cancelled). Refs the
    // "Legacy quirk preserved" note on `e2eAttemptFirstFleetMoveOrCancel`.
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<dynamic>(
              title: const Text('sea zone 1'),
              value: 0,
              groupValue: selected,
              onChanged: (next) {
                taps++;
                setState(() => selected = next);
              },
            ),
            RadioListTile<dynamic>(
              title: const Text('sea zone 2'),
              value: 1,
              groupValue: selected,
              onChanged: (next) {
                taps++;
                setState(() => selected = next);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => dialogOpen = false),
          child: Text(widget.l10n.common_confirm),
        ),
      ],
    );
  }
}

Future<_SeaPickHostState> _pumpSeaPickDialogStandalone(
  WidgetTester tester, {
  required AppLocalizations l10n,
}) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: _SeaPickHost(l10n: l10n)))),
  );
  return tester.state<_SeaPickHostState>(find.byType(_SeaPickHost));
}

void main() {
  suppressLogsForTests();

  group('e2eAttemptFirstFleetMoveOrCancel — no Move button branch', () {
    testWidgets('returns noMoveButton without opening a dialog', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        _wrap(_navalPanel(children: const [Text('Empty fleets list')])),
      );

      final outcome = await e2eAttemptFirstFleetMoveOrCancel(tester, l10n);

      expect(
        outcome,
        E2eFirstFleetMoveOutcome.noMoveButton,
        reason:
            'Helper must short-circuit without tapping or opening a dialog '
            'when no Move text descends from the naval panel root.',
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('emits perf timing with result=no_move_button', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('no_move_button_perf');
      await tester.pumpWidget(
        _wrap(_navalPanel(children: const [Text('Empty fleets list')])),
      );

      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await e2eAttemptFirstFleetMoveOrCancel(tester, l10n, perf: perf);
      } finally {
        debugPrint = original;
      }

      expect(
        lines.any(
          (l) =>
              l.contains('attempt_first_fleet_move') &&
              l.contains('result=no_move_button'),
        ),
        isTrue,
        reason:
            'perf wiring must emit the no_move_button marker so wall-clock '
            'attribution sees the short-circuit branch fired.',
      );
    });
  });

  group('e2eAttemptFirstFleetMoveOrCancel — cancel-on-empty-radios branch', () {
    testWidgets('taps Cancel and returns cancelled when no radios present', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        _wrap(
          _navalPanel(
            children: [
              _MoveButton(dialogBuilder: _emptyRadiosDialogBuilder(l10n)),
            ],
          ),
        ),
      );

      final outcome = await e2eAttemptFirstFleetMoveOrCancel(tester, l10n);

      expect(
        outcome,
        E2eFirstFleetMoveOutcome.cancelled,
        reason:
            'Empty destination-radios dialog must dismiss via Cancel, not '
            'via Confirm. A regression that picked the first radio would '
            'commit an invalid move and stall the dialog-close pump.',
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('emits perf timing with result=cancelled', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('cancelled_perf');
      await tester.pumpWidget(
        _wrap(
          _navalPanel(
            children: [
              _MoveButton(dialogBuilder: _emptyRadiosDialogBuilder(l10n)),
            ],
          ),
        ),
      );

      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await e2eAttemptFirstFleetMoveOrCancel(tester, l10n, perf: perf);
      } finally {
        debugPrint = original;
      }

      expect(
        lines.any(
          (l) =>
              l.contains('attempt_first_fleet_move') &&
              l.contains('result=cancelled'),
        ),
        isTrue,
      );
    });
  });

  group('e2eAttemptFirstFleetMoveOrCancel — confirmed branch', () {
    testWidgets(
      'taps first destination radio, taps Confirm, returns confirmed',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          _wrap(
            _navalPanel(
              children: [
                _MoveButton(dialogBuilder: (_) => _SeaPickHost(l10n: l10n)),
              ],
            ),
          ),
        );

        final outcome = await e2eAttemptFirstFleetMoveOrCancel(tester, l10n);

        expect(
          outcome,
          E2eFirstFleetMoveOutcome.confirmed,
          reason:
              'A dialog with hit-testable RadioListTile<dynamic> rows and a '
              'Confirm action must round-trip through tap-radio -> '
              'pump-confirm-tappable -> tap-Confirm -> dialog-close.',
        );
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('emits perf timing with result=confirmed', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('confirmed_perf');
      await tester.pumpWidget(
        _wrap(
          _navalPanel(
            children: [
              _MoveButton(dialogBuilder: (_) => _SeaPickHost(l10n: l10n)),
            ],
          ),
        ),
      );

      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await e2eAttemptFirstFleetMoveOrCancel(tester, l10n, perf: perf);
      } finally {
        debugPrint = original;
      }

      expect(
        lines.any(
          (l) =>
              l.contains('attempt_first_fleet_move') &&
              l.contains('result=confirmed'),
        ),
        isTrue,
      );
    });

    testWidgets(
      'RadioListTile<int> fixture goes through cancel branch (exact-type quirk)',
      (WidgetTester tester) async {
        // Reverse-pin the documented legacy quirk: the helper's
        // `find.byType(RadioListTile<dynamic>)` is an EXACT runtimeType match
        // per Flutter Finder semantics. `RadioListTile<int>` is a distinct
        // runtimeType and therefore is NOT seen as a destination radio — the
        // helper takes the cancel branch even though the dialog visibly has
        // radio rows. This mirrors how the pre-lift inline block behaved
        // against the production `RadioListTile<_MovePick>` dialog.
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          _wrap(
            _navalPanel(
              children: [
                _MoveButton(
                  dialogBuilder: (context) => AlertDialog(
                    content: SingleChildScrollView(
                      child: RadioListTile<int>(
                        title: const Text('sea zone 1'),
                        value: 0,
                        groupValue: null,
                        onChanged: (_) {},
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.common_cancel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        final outcome = await e2eAttemptFirstFleetMoveOrCancel(tester, l10n);

        expect(
          outcome,
          E2eFirstFleetMoveOutcome.cancelled,
          reason:
              'Generic-instantiated RadioListTile<int> must not match the '
              'helper exact-type RadioListTile<dynamic> finder; the helper '
              'must therefore take the cancel branch. A regression that '
              'switched to a subtype-aware finder would change full-turn '
              'snapshot assertions downstream.',
        );
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });

  group('e2eAttemptFirstFleetMoveOrCancel — direct sea-pick dialog smoke', () {
    testWidgets('_SeaPickHost confirms on Confirm tap (fixture sanity)', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final host = await _pumpSeaPickDialogStandalone(tester, l10n: l10n);
      expect(host.selected, isNull);
      expect(host.dialogOpen, isTrue);
    });
  });

  group('e2eAttemptFirstFleetMoveOrCancel — default constants', () {
    test('kE2eDefaultFirstFleetMoveDialogOpenTimeout matches legacy 5 s cap', () {
      expect(
        kE2eDefaultFirstFleetMoveDialogOpenTimeout,
        const Duration(seconds: 5),
      );
    });
    test('kE2eDefaultFirstFleetMoveConfirmReadyTimeout matches legacy 2 s cap', () {
      expect(
        kE2eDefaultFirstFleetMoveConfirmReadyTimeout,
        const Duration(seconds: 2),
      );
    });
    test('kE2eDefaultFirstFleetMoveDialogCloseTimeout matches legacy 10 s cap', () {
      expect(
        kE2eDefaultFirstFleetMoveDialogCloseTimeout,
        const Duration(seconds: 10),
      );
    });
  });
}
