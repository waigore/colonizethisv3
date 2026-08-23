// coastal/fogged short-circuit pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'await_nw_coastal_fixtures.dart';
import 'e2e_widget_pump_harness.dart';

void registerAwaitNwCoastalShortCircuitGroup() {
  group(
    'e2eAwaitNwCoastalOrVisibleLandForBundledExplore — coastal short-circuit',
    () {
      testWidgets(
        'coastal-NW snapshot exits on iteration 0 — single step recorded',
        (tester) async {
          await pumpE2eEmptyScaffold(tester);
          final l10n = lookupAppLocalizations(const Locale('en'));
          ctE2eNavalPanelSnapshot = awaitNwCoastalArrivalSnapshot();
          final steps = <String>[];
          await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
            tester,
            l10n,
            ensureUnderWallClock: steps.add,
            maxTurns: kE2eDefaultBundledExploreReadinessMaxTurns,
          );
          expect(
            steps,
            equals(<String>['NW bundled-explore readiness i=0']),
            reason:
                'A snapshot satisfying '
                '`e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot` '
                'at iteration 0 must short-circuit after one '
                '`ensureUnderWallClock` callback and one snapshot probe — '
                'never advancing to the open-naval-panel / move-segment / '
                'next-turn path. A regression that re-opened the naval '
                'sheet anyway would burn ~5 s per turn × 35 turns.',
          );
        },
      );
    },
  );

  group(
    'e2eAwaitNwCoastalOrVisibleLandForBundledExplore — fogged-or-better short-circuit',
    () {
      testWidgets(
        'NW-fogged snapshot exits on iteration 0 — single step recorded',
        (tester) async {
          await pumpE2eEmptyScaffold(tester);
          final l10n = lookupAppLocalizations(const Locale('en'));
          ctE2eNavalPanelSnapshot = awaitNwFoggedSnapshot();
          final steps = <String>[];
          await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
            tester,
            l10n,
            ensureUnderWallClock: steps.add,
            maxTurns: kE2eDefaultBundledExploreReadinessMaxTurns,
          );
          expect(
            steps,
            equals(<String>['NW bundled-explore readiness i=0']),
            reason:
                'The disjunction with '
                '`e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot` '
                'must short-circuit on the first iteration even when the '
                'coastal predicate is false (no fleets in NW). A '
                'regression that required both predicates to be true '
                'would stall the readiness wait whenever the player '
                'reached NW visibility via warp/scout rather than via '
                'a coastal sea zone.',
          );
        },
      );
    },
  );

  group(
    'e2eAwaitNwCoastalOrVisibleLandForBundledExplore — step label format',
    () {
      testWidgets(
        'step label uses `NW bundled-explore readiness i=<idx>` form',
        (tester) async {
          await pumpE2eEmptyScaffold(tester);
          final l10n = lookupAppLocalizations(const Locale('en'));
          ctE2eNavalPanelSnapshot = awaitNwCoastalArrivalSnapshot();
          final steps = <String>[];
          await e2eAwaitNwCoastalOrVisibleLandForBundledExplore(
            tester,
            l10n,
            ensureUnderWallClock: steps.add,
            maxTurns: 1,
          );
          expect(
            steps.single,
            matches(RegExp(r'^NW bundled-explore readiness i=\d+$')),
            reason:
                'Wall-clock guards captured for `#2336` debug runs key '
                'on this label prefix to attribute readiness-loop '
                'overshoot to the correct helper. A silent rename '
                'would surface in CI as an opaque `wall_clock_exceeded` '
                'failure with no helper attribution.',
          );
          expect(
            steps.single,
            equals('NW bundled-explore readiness i=0'),
            reason:
                'Iteration index must be 0-based and embedded into the '
                'label so a regression that reset the counter or used '
                '1-based indexing surfaces here, not as a confusing '
                'off-by-one in CI logs.',
          );
        },
      );
    },
  );
}
