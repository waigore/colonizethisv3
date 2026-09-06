// Pins AC1 barrel re-exports for helpers lifted on PR #2731 (Refs #2336).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show
        CtE2eCivilianPanelSnapshot,
        CtE2eNavalPanelSnapshot,
        ctE2eNavalPanelSnapshot;
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'app_shell_harness.dart';
import 'e2e_helpers_barrel_pr2731_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('AC1 barrel: PR #2731 lifted helpers', () {
    testWidgets(
      'dismissCtDialogShellIfPresent is re-exported through the barrel',
      (tester) async {
        final Future<bool> Function(
          WidgetTester,
          AppLocalizations, {
          E2ePerfLog? perf,
          Duration shellCloseTimeout,
          String phaseName,
        })
        ref = dismissCtDialogShellIfPresent;
        expect(ref, isNotNull);
        expect(
          kE2eDefaultCtDialogShellCloseTimeout,
          const Duration(seconds: 3),
        );
        expect(
          kE2eDefaultCtDialogShellClosePhase,
          'pump_until_shell_closed_after_close_candidate',
        );
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(await ref(tester, l10n), isFalse);
      },
    );

    testWidgets(
      'attemptFirstFleetMoveOrCancel is re-exported through the barrel',
      (tester) async {
        final Future<E2eFirstFleetMoveOutcome> Function(
          WidgetTester,
          AppLocalizations, {
          E2ePerfLog? perf,
          Duration moveDialogOpenTimeout,
          Duration confirmReadyTimeout,
          Duration dialogCloseTimeout,
        })
        ref = attemptFirstFleetMoveOrCancel;
        expect(ref, isNotNull);
        expect(
          kE2eDefaultFirstFleetMoveDialogOpenTimeout,
          const Duration(seconds: 5),
        );
        expect(
          kE2eDefaultFirstFleetMoveConfirmReadyTimeout,
          const Duration(seconds: 2),
        );
        expect(
          kE2eDefaultFirstFleetMoveDialogCloseTimeout,
          const Duration(seconds: 10),
        );
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(await ref(tester, l10n), E2eFirstFleetMoveOutcome.noMoveButton);
      },
    );

    test(
      'awaitExploreEnabledFromCivilianPanel is re-exported through the barrel',
      () {
        final Future<bool> Function(
          WidgetTester,
          AppLocalizations, {
          E2ePerfLog? perf,
          Duration maxUiResponseWait,
          int maxBoundedTurnRetries,
          String retryIterationCounter,
        })
        ref = awaitExploreEnabledFromCivilianPanel;
        expect(ref, isNotNull);
        expect(kE2eDefaultBundledExploreMaxTurnRetries, 8);
        expect(
          kE2eDefaultBundledExploreRetryIterationCounter,
          'bundled_explore_retry_iterations',
        );
      },
    );

    testWidgets(
      'handleBundledExploreFailure is re-exported through the barrel',
      (tester) async {
        final Future<void> Function(
          WidgetTester, {
          required CtE2eNavalPanelSnapshot? navalSnapshot,
          required CtE2eCivilianPanelSnapshot? civilianSnapshot,
          CtE2eNavalPanelSnapshot? lastKnownNavalSnapshot,
          required int maxBoundedTurnRetries,
        })
        ref = handleBundledExploreFailure;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        Object? caught;
        try {
          await ref(
            tester,
            navalSnapshot: bundledExploreFailureNavalSnapshot(),
            civilianSnapshot: null,
            maxBoundedTurnRetries: kE2eDefaultBundledExploreMaxTurnRetries,
          );
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<TestFailure>());
        expect(caught.toString(), contains('Post-bundle #1869 regression'));
        expect(
          caught.toString(),
          contains(
            '$kE2eDefaultBundledExploreMaxTurnRetries bounded Next turn retries',
          ),
        );
      },
    );

    testWidgets(
      'ensureNonHomeFleetInNwAfterLoop is re-exported through the barrel',
      (tester) async {
        final Future<E2eFinalNavalReachCheckResult> Function(
          WidgetTester, {
          required E2ePerfLog perf,
          required String Function(Object? lastException) failureMessageBuilder,
          Duration maxUiResponseWait,
        })
        ref = ensureNonHomeFleetInNwAfterLoop;
        expect(ref, isNotNull);
        expect(
          kE2eDefaultFinalNavalReachCheckUiWait,
          const Duration(seconds: 5),
        );
        ctE2eNavalPanelSnapshot = nwReachNavalSnapshot();
        addTearDown(() {
          ctE2eNavalPanelSnapshot = null;
        });
        final perf = E2ePerfLog('e2e_helpers_barrel_pr2731_lifted_test');
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        final result = await ref(
          tester,
          perf: perf,
          failureMessageBuilder: (_) => 'barrel smoke failure',
        );
        expect(result.lastKnownNavalSnapshot, same(ctE2eNavalPanelSnapshot));
      },
    );
  });
}
