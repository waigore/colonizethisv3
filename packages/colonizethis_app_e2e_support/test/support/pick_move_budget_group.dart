library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'move_dialog_widget_tester_harness.dart';

void registerPickMoveBudgetGroup() {
  group('e2ePickMoveDestinationAndConfirm — budget / determinism', () {
    testWidgets(
      'fails with deterministic message when no AlertDialog mounts in time',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await pumpMoveDialogScaffold(tester, child: const SizedBox());

        Object? caught;
        try {
          await e2ePickMoveDestinationAndConfirm(
            tester,
            l10n,
            // Allow the inner `wait_until_found_move_dialog` (2 s) to run to
            // its own timeout and surface a deterministic "Timed out" failure;
            // the budget guard would otherwise short-circuit with the at-step
            // diagnostic, which is also valid but covered by the next case.
            moveDialogBudget: const Duration(seconds: 10),
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNotNull,
          reason:
              'When no AlertDialog mounts, the inner '
              'wait_until_found_move_dialog must throw (helper does not '
              'swallow it). Silent return would let the fleet-reach loop '
              'proceed into a NUL state.',
        );
        expect(
          caught.toString(),
          contains('Timed out'),
          reason:
              'Failure surface must include the timeout sentinel from '
              'e2eWaitUntilFound so triage points at the missing dialog, '
              'not a downstream symptom.',
        );
      },
    );

    testWidgets(
      'fails on the very first ensureBudget when moveDialogBudget is zero',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
        );

        Object? caught;
        try {
          await e2ePickMoveDestinationAndConfirm(
            tester,
            l10n,
            moveDialogBudget: Duration.zero,
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNotNull,
          reason:
              'A non-positive budget must trip the ensureBudget guard '
              'immediately. A regression that swallowed Duration.zero would '
              'let the helper run past the documented per-call cap.',
        );
        expect(
          caught.toString(),
          contains('Move fleet dialog exceeded'),
          reason:
              'Failure must use the budget-exceeded diagnostic (not a '
              'generic timeout) so triage knows the cap fired, not the '
              'inner finders.',
        );
      },
    );

    testWidgets(
      'is deterministic across two independent invocations',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));

        final hostA = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
        );
        await e2ePickMoveDestinationAndConfirm(tester, l10n);
        expect(hostA.selectedKind, 'warp');
        expect(hostA.dialogOpen, isFalse);

        final hostB = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
        );
        await e2ePickMoveDestinationAndConfirm(tester, l10n);
        expect(
          hostB.selectedKind,
          'warp',
          reason:
              'Helper has no hidden state — a second invocation on a fresh '
              'host must yield the same warp-tap result (Refs GitHub #2336 '
              'AC5 / Bottleneck 4 determinism contract).',
        );
        expect(hostB.dialogOpen, isFalse);
      },
    );
  });

}
