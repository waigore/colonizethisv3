import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// Splits the home fleet once via the naval panel (GitHub #2336 H8).
Future<void> e2eSplitHomeFleetOnce(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
  Duration openNavalTimeout = kE2eDefaultNavalOpenTimeout,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  bool navalPanelAlreadyOpen = false,
}) async {
  final phaseSw = Stopwatch()..start();
  if (!navalPanelAlreadyOpen) {
    await e2eOpenNavalPanel(
      tester,
      perf: perf,
      timeout: openNavalTimeout,
      bottomSheetCloseTimeout: bottomSheetCloseTimeout,
    );
    await e2eExpandEachExpansionTileOnce(tester);
  }
  final navalPanelRoot = find.byKey(kCtE2ENavalPanelRootKey);
  // Production fleet rows collapse Split to icon-only at E2E viewports; the
  // widget-test pin keeps a legacy `Text('Split')` harness button as fallback.
  final splitByKey = find.descendant(
    of: navalPanelRoot,
    matching: find.byKey(kCtE2EFleetSplitActionKey),
  );
  final splitByLabel = find.descendant(
    of: navalPanelRoot,
    matching: find.text(l10n.common_split),
  );
  final split = splitByKey.evaluate().isNotEmpty ? splitByKey : splitByLabel;
  final splitHit = split.hitTestable();
  expect(splitHit, findsWidgets);
  await tester.tap(splitHit.first, warnIfMissed: false);
  await e2eWaitUntilFound(
    tester,
    find.descendant(
      of: find.byType(CtDialogShell),
      matching: find.byWidgetPredicate(
        (w) =>
            w is CtNinePatchButton &&
            w.enabled &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('ctTransfer.left.>'),
      ),
    ),
    timeout: const Duration(seconds: 4),
    perf: perf,
    phaseName: 'wait_until_found_split_nudge_right',
  );
  final confirmButton = find.widgetWithText(
    CtNinePatchButton,
    l10n.splitFleet_confirm,
  );
  bool splitConfirmEnabled() {
    if (confirmButton.evaluate().isEmpty) {
      return false;
    }
    return tester.widget<CtNinePatchButton>(confirmButton.first).enabled;
  }

  Finder enabledLeftNudge(String prefix) => find.descendant(
    of: find.byType(CtDialogShell),
    matching: find.byWidgetPredicate((w) {
      if (w is! CtNinePatchButton || !w.enabled) {
        return false;
      }
      final key = w.key;
      return key is ValueKey<String> && key.value.startsWith(prefix);
    }),
  );

  for (var attempt = 0; attempt < 6 && !splitConfirmEnabled(); attempt++) {
    final moveAll = enabledLeftNudge('ctTransfer.left.>>');
    if (moveAll.evaluate().isNotEmpty) {
      await tester.tap(moveAll.first, warnIfMissed: false);
    } else {
      final moveOne = enabledLeftNudge('ctTransfer.left.>');
      if (moveOne.evaluate().isEmpty) {
        break;
      }
      await tester.tap(moveOne.first, warnIfMissed: false);
    }
    await e2ePumpUntilConditionOrIdle(
      tester,
      splitConfirmEnabled,
      timeout: const Duration(milliseconds: 400),
      perf: perf,
      phaseName: 'pump_until_split_confirm_enabled_attempt_$attempt',
    );
  }
  await e2ePumpUntil(
    tester,
    splitConfirmEnabled,
    timeout: const Duration(seconds: 5),
    perf: perf,
    phaseName: 'pump_until_split_confirm_enabled',
  );
  await tester.tap(confirmButton.first, warnIfMissed: false);
  final splitTitle = find.text(l10n.splitFleet_dialogTitle);
  await e2ePumpUntil(
    tester,
    () => splitTitle.evaluate().isEmpty,
    timeout: const Duration(seconds: 10),
    perf: perf,
    phaseName: 'pump_until_split_fleet_dialog_dismissed',
  );
  await e2eExpandEachExpansionTileOnce(tester);
  perf?.timing('fleet_split', phaseSw.elapsed);
}
