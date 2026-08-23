// Extracted from e2e_attempt_first_fleet_move_or_cancel_test.dart (#4598 Slice C).
library;

// ignore_for_file: deprecated_member_use
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'attempt_fleet_move_harness.dart';
import 'naval_fleet_move_harness.dart';

void registerE2eAttemptFirstFleetMoveOrCancelGuardGroup3() {
  group('e2eAttemptFirstFleetMoveOrCancel — confirmed branch', () {
    testWidgets(
      'taps first destination radio, taps Confirm, returns confirmed',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          wrapNavalScrollBody(
            navalPanelRoot(
              children: [
                FleetMoveButton(
                  buttonKey: kCtE2EFleetMoveActionKey,
                  dialogBuilder: (_) => SeaPickHost(l10n: l10n),
                ),
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
        expect(find.byType(CtDialogShell), findsNothing);
      },
    );

    testWidgets('emits perf timing with result=confirmed', (
      WidgetTester tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final perf = E2ePerfLog('confirmed_perf');
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              FleetMoveButton(
                buttonKey: kCtE2EFleetMoveActionKey,
                dialogBuilder: (_) => SeaPickHost(l10n: l10n),
              ),
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
          wrapNavalScrollBody(
            navalPanelRoot(
              children: [
                FleetMoveButton(
                  buttonKey: kCtE2EFleetMoveActionKey,
                  dialogBuilder: (context) => CtDialogShell(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SingleChildScrollView(
                          child: RadioListTile<int>(
                            title: const Text('sea zone 1'),
                            value: 0,
                            groupValue: null,
                            onChanged: (_) {},
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.common_cancel),
                        ),
                      ],
                    ),
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
        expect(find.byType(CtDialogShell), findsNothing);
      },
    );
  });
}
