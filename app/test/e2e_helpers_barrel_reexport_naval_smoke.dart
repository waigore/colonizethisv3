// AC1 barrel re-export smoke pins (naval/move segment) — Refs #2336, #4734 Slice J.

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show
        CtE2eCivilianPanelSnapshot,
        CtE2eNavalPanelSnapshot,
        ctE2eCivilianPanelSnapshot;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'app_shell_harness.dart';

void registerE2eHelpersBarrelReexportNavalSmokeTests() {
  group('AC1 barrel: re-export naval/move smokes', () {
    testWidgets(
      'tapMoveOnFirstNonHomeFleet is re-exported through the barrel',
      (tester) async {
        final Future<bool> Function(WidgetTester) ref =
            tapMoveOnFirstNonHomeFleet;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(await ref(tester), isFalse);
      },
    );

    testWidgets(
      'anyExplorerHasEnabledExploreAssignFleet is re-exported through the barrel',
      (tester) async {
        final Future<bool> Function(
          WidgetTester, {
          Duration maxUiResponseWait,
          int maxPanelSweepSteps,
        })
        ref = anyExplorerHasEnabledExploreAssignFleet;
        expect(ref, isNotNull);
        ctE2eCivilianPanelSnapshot = const CtE2eCivilianPanelSnapshot(
          game: Game(
            id: 'barrel-smoke-no-explore',
            worldState: WorldState(
              turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
              oldWorld: RegionData(),
              newWorld: RegionData(),
            ),
            players: [Player(id: 'gp1', displayName: 'You', isHuman: true)],
          ),
          humanPlayerId: 'gp1',
          currentOrders: Orders(),
          availableWorkTargets: <String, List<String>>{},
        );
        addTearDown(() {
          ctE2eCivilianPanelSnapshot = null;
        });
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(await ref(tester, maxPanelSweepSteps: 0), isFalse);
      },
    );

    testWidgets('tryNavalMoveSegment is re-exported through the barrel', (
      tester,
    ) async {
      final Future<void> Function(
        WidgetTester,
        AppLocalizations, {
        bool useNewWorldMapTabFirst,
        bool allowWarpDestinations,
        bool navalPanelAlreadyOpen,
        E2ePerfLog? perf,
        Duration maxUiResponseWait,
      })
      ref = tryNavalMoveSegment;
      expect(ref, isNotNull);
      expect(kE2eDefaultNavalMoveSegmentUiWait, const Duration(seconds: 5));
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        buildAppShellMaterialApp(
          applyEditorialTheme: false,
          home: Scaffold(body: SizedBox()),
        ),
      );
      await ref(tester, l10n, navalPanelAlreadyOpen: true);
    });

    testWidgets(
      'pickMoveDestinationAndConfirm is re-exported through the barrel',
      (tester) async {
        final Future<void> Function(
          WidgetTester,
          AppLocalizations, {
          bool allowWarpDestinations,
          Duration moveDialogBudget,
          int maxWarpDragProbes,
        })
        ref = pickMoveDestinationAndConfirm;
        expect(ref, isNotNull);
        expect(kE2eDefaultMoveFleetDialogBudget, const Duration(seconds: 5));
        expect(kE2eDefaultMoveFleetWarpDragProbes, 8);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        final l10n = lookupAppLocalizations(const Locale('en'));
        Object? caught;
        try {
          await ref(
            tester,
            l10n,
            moveDialogBudget: const Duration(seconds: 10),
          );
        } catch (e) {
          caught = e;
        }
        expect(caught, isNotNull);
      },
    );

    test(
      'e2eTextLooksLikeNewWorldLocationLine is re-exported through the barrel',
      () {
        final bool Function(String?) ref = e2eTextLooksLikeNewWorldLocationLine;
        expect(ref, isNotNull);
        expect(ref('New World — Outer Sea'), isTrue);
      },
    );

    testWidgets(
      'e2eNavalPanelShowsNonHomeFleetInNewWorld is re-exported through the barrel',
      (tester) async {
        final bool Function(WidgetTester) ref =
            e2eNavalPanelShowsNonHomeFleetInNewWorld;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(ref(tester), isFalse);
      },
    );

    test('e2eNonHomeHumanFleetInNewWorldFromCtSnapshot is re-exported through '
        'the barrel', () {
      final bool Function(CtE2eNavalPanelSnapshot?) ref =
          e2eNonHomeHumanFleetInNewWorldFromCtSnapshot;
      expect(ref, isNotNull);
      expect(ref(null), isFalse);
    });
  });
}
