// Pins AC1 barrel re-exports for helpers lifted on PR #2731 (Refs #2336).
//
// Kept in a sibling file so `e2e_helpers_barrel_test.dart` stays under the
// `dart_file_non_comment_line_size` cap (`tool/ct_repo_lint.dart`).
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart'
    show
        CtE2eCivilianPanelSnapshot,
        CtE2eNavalPanelSnapshot,
        ctE2eNavalPanelSnapshot;
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

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
          const MaterialApp(home: Scaffold(body: SizedBox())),
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
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        expect(
          await ref(tester, l10n),
          E2eFirstFleetMoveOutcome.noMoveButton,
        );
      },
    );

    test('awaitExploreEnabledFromCivilianPanel is re-exported through the barrel',
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
    });

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
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        // Build a snapshot that reports at least one fogged-or-better NW
        // tile so the topology skip arm does NOT fire — exercising the
        // barrel's forwarding into the regression fail arm. A `null`
        // navalSnapshot would route through the skip arm (matches the
        // pre-lift inline contract) and never raise, defeating the pin.
        const human = 'gp1';
        final regressionNaval = CtE2eNavalPanelSnapshot(
          game: Game(
            id: 'barrel-smoke-bundled-explore-failure',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: const RegionData(),
              newWorld: const RegionData(
                provinces: [
                  Province(id: 'newWorld|nwA', regionId: 'newWorld'),
                ],
              ),
              playerVisibilityByTile: const {
                human: {'newWorld|nwA|0|0': 'fogged'},
              },
            ),
            players: const [
              Player(id: human, displayName: 'You', isHuman: true),
            ],
          ),
          humanPlayerId: human,
          topology: const MapTopology(),
          draftOrders: const Orders(),
        );
        Object? caught;
        try {
          await ref(
            tester,
            navalSnapshot: regressionNaval,
            civilianSnapshot: null,
            maxBoundedTurnRetries: kE2eDefaultBundledExploreMaxTurnRetries,
          );
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<TestFailure>());
        expect(
          caught.toString(),
          contains('Post-bundle #1869 regression'),
          reason:
              'Barrel must forward to the lifted implementation that raises '
              'with the canonical regression message; a regression that '
              'forwarded to a stub or dropped an argument would fail this pin.',
        );
        expect(
          caught.toString(),
          contains(
            '$kE2eDefaultBundledExploreMaxTurnRetries bounded Next turn retries',
          ),
          reason:
              'maxBoundedTurnRetries must be interpolated into the failure '
              'message — a barrel that dropped or hard-coded the arg would '
              'render the wrong retry budget for downstream triage.',
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
        const human = 'gp1';
        ctE2eNavalPanelSnapshot = CtE2eNavalPanelSnapshot(
          game: Game(
            id: 'barrel-smoke-nw-reach',
            worldState: WorldState(
              turnState: TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: RegionData(),
              newWorld: RegionData(),
              fleets: [
                Fleet(
                  id: 'fleet_$human',
                  ownerId: human,
                  regionId: 'oldWorld',
                  inPortAtProvinceId: 'oldWorld|capital',
                ),
                Fleet(
                  id: 'fleet_split',
                  ownerId: human,
                  regionId: 'newWorld',
                  seaZoneId: 'nwSea',
                ),
              ],
            ),
            players: const [
              Player(id: human, displayName: 'You', isHuman: true),
            ],
          ),
          humanPlayerId: human,
          topology: const MapTopology(),
          draftOrders: const Orders(),
        );
        addTearDown(() {
          ctE2eNavalPanelSnapshot = null;
        });
        final perf = E2ePerfLog('e2e_helpers_barrel_pr2731_lifted_test');
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
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
