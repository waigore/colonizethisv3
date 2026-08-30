// step label and AC1 barrel pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'await_nw_coastal_fixtures.dart';
import 'e2e_widget_pump_harness.dart';

void registerAwaitNwCoastalBarrelGroup() {
  group(
    'e2eAwaitNwCoastalOrVisibleLandForBundledExplore — AC1 barrel forwarding',
    () {
      testWidgets('awaitNwCoastalOrVisibleLandForBundledExplore (barrel alias) '
          'short-circuits identically to the lifted form', (tester) async {
        await pumpE2eEmptyScaffold(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        ctE2eNavalPanelSnapshot = awaitNwCoastalArrivalSnapshot();
        final steps = <String>[];
        await awaitNwCoastalOrVisibleLandForBundledExplore(
          tester,
          l10n,
          ensureUnderWallClock: steps.add,
          maxTurns: kE2eDefaultBundledExploreReadinessMaxTurns,
        );
        expect(
          steps,
          equals(<String>['NW bundled-explore readiness i=0']),
          reason:
              'The AC1 barrel wrapper must forward arguments in the '
              'documented order — a regression that swapped '
              '`ensureUnderWallClock` with `maxTurns`, dropped '
              '`l10n`, or accidentally captured a fresh `maxTurns` '
              'default would surface here, not in the slow CI lane.',
        );
      });

      test('awaitNwCoastalOrVisibleLandForBundledExplore is re-exported as a '
          'tear-off (compile-time signature pin)', () {
        final Future<void> Function(
          WidgetTester,
          AppLocalizations, {
          required void Function(String step) ensureUnderWallClock,
          int maxTurns,
          Duration maxUiResponseWait,
        })
        ref = awaitNwCoastalOrVisibleLandForBundledExplore;
        expect(
          ref,
          isNotNull,
          reason:
              'The AC1 barrel must continue to export the helper with '
              'the documented signature. A silent removal from the '
              '`show` clause or an arg-order swap on the wrapper '
              'would fail this assignment at compile time.',
        );
      });
    },
  );
}
