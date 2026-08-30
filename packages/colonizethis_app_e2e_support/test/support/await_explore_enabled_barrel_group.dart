// AC1 barrel forwarding pins (#4598).
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

void registerAwaitExploreEnabledBarrelGroup(AppLocalizations l10n) {
  group('e2eAwaitExploreEnabledFromCivilianPanel — AC1 barrel forwarding', () {
    testWidgets(
      'awaitExploreEnabledFromCivilianPanel (barrel alias) returns the '
      'same boolean as the lifted form',
      (tester) async {
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
        final result = await awaitExploreEnabledFromCivilianPanel(tester, l10n);
        expect(
          result,
          isTrue,
          reason:
              'The AC1 barrel wrapper must forward all named arguments in '
              'the documented order and preserve the boolean return '
              'value. A regression that dropped `tester` / `l10n` from '
              'the signature, swapped `perf` with `maxUiResponseWait`, '
              'or fail-opened to `false` would surface here, not in the '
              'slow CI lane.',
        );
      },
    );

    test('awaitExploreEnabledFromCivilianPanel is re-exported as a '
        'tear-off (compile-time signature pin)', () {
      final Future<bool> Function(
        WidgetTester,
        AppLocalizations, {
        shared.E2ePerfLog? perf,
        Duration maxUiResponseWait,
        int maxBoundedTurnRetries,
        String retryIterationCounter,
      })
      ref = awaitExploreEnabledFromCivilianPanel;
      expect(
        ref,
        isNotNull,
        reason:
            'The AC1 barrel must continue to export the helper with the '
            'documented signature. A silent removal from the `show` '
            'clause, an arg-order swap on the wrapper, or a changed '
            'default for `maxBoundedTurnRetries` / '
            '`retryIterationCounter` / `maxUiResponseWait` would fail '
            'this assignment at compile time.',
      );
    });
  });
}
