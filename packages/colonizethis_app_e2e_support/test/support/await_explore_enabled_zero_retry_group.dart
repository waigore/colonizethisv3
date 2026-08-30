// zero-retry budget pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildRoad, kWorkTargetExplore;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

import 'await_explore_enabled_fixtures.dart';
import 'expect_panel_texts_harness.dart' as panel_host;

void registerAwaitExploreEnabledZeroRetryGroup(AppLocalizations l10n) {
  group('e2eAwaitExploreEnabledFromCivilianPanel — zero-retry budget', () {
    testWidgets('maxBoundedTurnRetries: 0 with disabled snapshot -> returns '
        'false without entering the retry loop', (tester) async {
      ctE2eCivilianPanelSnapshot = awaitExploreCivilianSnapshot(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
        },
      );
      await tester.pumpWidget(
        panel_host.wrap(kCtE2ECivilianPanelRootKey, const [
          ListTile(title: Text('Stub')),
        ]),
      );
      final perf = shared.E2ePerfLog('await_explore_pin');
      late bool result;
      final lines = await panel_host.captureDebugPrints(() async {
        result = await e2eAwaitExploreEnabledFromCivilianPanel(
          tester,
          l10n,
          perf: perf,
          maxUiResponseWait: const Duration(seconds: 5),
          maxBoundedTurnRetries: 0,
        );
      });
      expect(result, isFalse);
      final retryCounterLines = lines
          .where(
            (line) =>
                line.startsWith('E2E_COUNTER|') &&
                line.contains(
                  '|name=$kE2eDefaultBundledExploreRetryIterationCounter|',
                ),
          )
          .toList();
      expect(
        retryCounterLines,
        isEmpty,
        reason:
            'A zero retry budget must structurally skip the retry loop, '
            'returning whatever the initial check reported. A regression '
            'that ran one iteration before testing the bound (`do { ... } '
            'while (...)`) would emit a spurious counter bump and drive '
            'the next-turn UI even when the caller explicitly opted out.',
      );
    });

    testWidgets('maxBoundedTurnRetries: 0 with enabled snapshot -> returns '
        'true (initial-check short-circuit still wins)', (tester) async {
      ctE2eCivilianPanelSnapshot = awaitExploreCivilianSnapshot(
        availableWorkTargets: const {
          'explorer-1': [kWorkTargetExplore],
        },
      );
      await tester.pumpWidget(
        panel_host.wrap(kCtE2ECivilianPanelRootKey, const [
          ListTile(title: Text('Stub')),
        ]),
      );
      final perf = shared.E2ePerfLog('await_explore_pin');
      final result = await e2eAwaitExploreEnabledFromCivilianPanel(
        tester,
        l10n,
        perf: perf,
        maxBoundedTurnRetries: 0,
      );
      expect(
        result,
        isTrue,
        reason:
            'The retry budget bound only governs how many retry iterations '
            'run AFTER the initial check fails. An enabled snapshot must '
            'still return `true` even when `maxBoundedTurnRetries: 0`, '
            'since the initial check is structurally outside the loop.',
      );
    });
  });

  group('e2eAwaitExploreEnabledFromCivilianPanel — retry counter override', () {
    testWidgets('retryIterationCounter override propagates into the bumped '
        'counter name (zero-budget pin guards the no-op path)', (tester) async {
      // With maxBoundedTurnRetries: 0 the override never bumps in this
      // fixture, but the parameter must still be accepted at the call
      // site. A regression that hard-coded the default would surface in
      // the AC1 barrel-forwarding test below; this test pins the
      // implementation-side parameter as part of the contract.
      ctE2eCivilianPanelSnapshot = awaitExploreCivilianSnapshot(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
        },
      );
      await tester.pumpWidget(
        panel_host.wrap(kCtE2ECivilianPanelRootKey, const [
          ListTile(title: Text('Stub')),
        ]),
      );
      final perf = shared.E2ePerfLog('await_explore_pin');
      final result = await e2eAwaitExploreEnabledFromCivilianPanel(
        tester,
        l10n,
        perf: perf,
        maxBoundedTurnRetries: 0,
        retryIterationCounter: 'pin_custom_retry_counter',
      );
      expect(result, isFalse);
    });
  });
}
