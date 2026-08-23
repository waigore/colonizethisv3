// initial-check short-circuit pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

import 'await_explore_enabled_fixtures.dart';
import 'expect_panel_texts_harness.dart' as panel_host;

void registerAwaitExploreEnabledInitialGroup(AppLocalizations l10n) {
  group('e2eAwaitExploreEnabledFromCivilianPanel — initial-check '
      'short-circuit', () {
    testWidgets('snapshot says Explore enabled -> returns true and never '
        'increments the retry counter', (tester) async {
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
      late bool result;
      final lines = await panel_host.captureDebugPrints(() async {
        result = await e2eAwaitExploreEnabledFromCivilianPanel(
          tester,
          l10n,
          perf: perf,
          maxUiResponseWait: const Duration(seconds: 5),
        );
      });
      expect(result, isTrue);
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
            'A successful initial check must short-circuit without entering '
            'the retry loop. Bumping `bundled_explore_retry_iterations` '
            'on a first-pass success would inflate every post-bundle '
            'Explore-enabled run\'s retry attribution and skew Bottleneck 5 '
            'cost dashboards.',
      );
    });

    testWidgets('perf is null -> no E2E_COUNTER markers emitted on initial '
        'short-circuit', (tester) async {
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
      late bool result;
      final lines = await panel_host.captureDebugPrints(() async {
        result = await e2eAwaitExploreEnabledFromCivilianPanel(
          tester,
          l10n,
          maxUiResponseWait: const Duration(seconds: 5),
        );
      });
      expect(result, isTrue);
      expect(
        lines.where(
          (line) =>
              line.startsWith('E2E_COUNTER|') &&
              line.contains(
                '|name=$kE2eDefaultBundledExploreRetryIterationCounter|',
              ),
        ),
        isEmpty,
        reason:
            'Callers that opt out of perf logging (no shared `E2ePerfLog`) '
            'must not trigger spurious counter markers; the helper must '
            'guard the `perf?.bumpCounter(...)` call with a null check so '
            'unit tests / future stand-alone callers can use the helper '
            'without instantiating a perf log.',
      );
    });
  });
}
