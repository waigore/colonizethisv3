// e2eFleetReachTurnLoop bounded loop pins (#4598).
library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

import 'e2e_widget_pump_harness.dart';
import 'expect_panel_texts_harness.dart';

void registerFleetReachTurnLoopBoundedGroup() {
  group('e2eFleetReachTurnLoop — bounded loop', () {
    testWidgets(
      'maxTurns: 0 is a complete no-op — ensureUnderWallClock never invoked '
      'and the loop returns loopExhausted with iterationsRun=0',
      (tester) async {
        await pumpE2eEmptyScaffold(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        final perf = shared.E2ePerfLog('fleet_reach_loop_pin');
        final steps = <String>[];
        late E2eFleetReachLoopResult result;
        final lines = await captureDebugPrints(() async {
          result = await e2eFleetReachTurnLoop(
            tester,
            l10n,
            perf: perf,
            ensureUnderWallClock: steps.add,
            maxTurns: 0,
          );
        });
        expect(
          steps,
          isEmpty,
          reason:
              'A zero-iteration call must not enter the for-body, must '
              'not invoke the wall-clock guard, and must not call any of '
              'the per-iteration helpers (dismiss / region-tab / open '
              'naval / try move / advance turn). Without this, callers '
              'cannot pass `maxTurns: 0` as a safe disarm in tests.',
        );
        expect(
          result.exit,
          E2eFleetReachLoopExit.loopExhausted,
          reason:
              'maxTurns: 0 must return [loopExhausted] so call sites that '
              'switch on the exit branch fall through to their post-loop '
              'path rather than misattributing a no-op to a reach result.',
        );
        expect(
          result.iterationsRun,
          0,
          reason:
              '[iterationsRun] for a zero-budget call must equal the '
              'budget itself — a regression that hardcoded a non-zero '
              'value would break the loop-exhausted invariant '
              '`iterationsRun == maxTurns`.',
        );
        expect(
          result.lastKnownNavalSnapshot,
          isNull,
          reason:
              'Without entering the body, no `ctE2eNavalPanelSnapshot` '
              'capture point ever fires; [lastKnownNavalSnapshot] must '
              'remain null so test 2 diagnostics fall back to the live '
              'global rather than an undefined value.',
        );
        expect(
          lines.where(
            (line) => line.startsWith(
              'E2E_COUNTER|test=fleet_reach_loop_pin|name=turn_loop_iterations|',
            ),
          ),
          isEmpty,
          reason:
              'A zero-iteration call must not bump the '
              '`turn_loop_iterations` counter. A regression that emitted '
              'one before the bounds check would skew Bottleneck 4 '
              'iteration counts on any scenario that disabled the loop.',
        );
      },
    );
  });
}
