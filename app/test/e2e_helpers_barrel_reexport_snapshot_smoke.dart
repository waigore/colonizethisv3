// AC1 barrel re-export smoke pins (snapshot/region tab) — Refs #2336, #4734 Slice J.

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show CtE2eCivilianPanelSnapshot, CtE2eNavalPanelSnapshot;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'app_shell_harness.dart';

void registerE2eHelpersBarrelReexportSnapshotSmokeTests() {
  group('AC1 barrel: re-export snapshot/region smokes', () {
    test(
      'e2eFleetReachDoneFromCtSnapshotOnly is re-exported through the barrel',
      () {
        final bool Function(CtE2eNavalPanelSnapshot?) ref =
            e2eFleetReachDoneFromCtSnapshotOnly;
        expect(ref, isNotNull);
        expect(ref(null), isFalse);
      },
    );

    testWidgets(
      'e2eHarnessDetectsNonHomeFleetInNewWorld is re-exported through the barrel',
      (tester) async {
        final bool Function(WidgetTester, CtE2eNavalPanelSnapshot?) ref =
            e2eHarnessDetectsNonHomeFleetInNewWorld;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(ref(tester, null), isFalse);
      },
    );

    test('e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot is '
        're-exported through the barrel', () {
      final bool Function(CtE2eNavalPanelSnapshot?) ref =
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot;
      expect(ref, isNotNull);
      expect(ref(null), isFalse);
    });

    test('e2eNwCoastalProvincesAdjacentToFleetSea is re-exported through the '
        'barrel', () {
      final Set<String> Function(MapTopology, String, String) ref =
          e2eNwCoastalProvincesAdjacentToFleetSea;
      expect(ref, isNotNull);
      expect(ref(const MapTopology(), 'sea1', 'newWorld'), isEmpty);
    });

    test('e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot is re-exported '
        'through the barrel', () {
      final bool Function(CtE2eNavalPanelSnapshot?) ref =
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot;
      expect(ref, isNotNull);
      expect(ref(null), isFalse);
    });

    test('e2eExploreAssignEnabledFromCivilianSnapshot is re-exported '
        'through the barrel', () {
      final bool? Function(CtE2eCivilianPanelSnapshot?) ref =
          e2eExploreAssignEnabledFromCivilianSnapshot;
      expect(ref, isNotNull);
      expect(ref(null), isNull);
      const Game game = Game(
        id: 'barrel-smoke',
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [Player(id: 'gp1', displayName: 'You', isHuman: true)],
      );
      final emptySnap = const CtE2eCivilianPanelSnapshot(
        game: game,
        humanPlayerId: 'gp1',
        currentOrders: Orders(),
        availableWorkTargets: <String, List<String>>{},
      );
      expect(ref(emptySnap), isFalse);
    });

    testWidgets(
      'e2eRadioListTilesInAlertDialogs is re-exported through the barrel',
      (tester) async {
        final Finder Function() ref = e2eRadioListTilesInAlertDialogs;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        expect(ref(), findsNothing);
      },
    );

    testWidgets(
      'e2eTapNewWorldRegionTabIfPresent is re-exported through the barrel',
      (tester) async {
        final Future<void> Function(WidgetTester) ref =
            e2eTapNewWorldRegionTabIfPresent;
        expect(ref, isNotNull);
        await tester.pumpWidget(
          buildAppShellMaterialApp(
            applyEditorialTheme: false,
            home: Scaffold(body: SizedBox()),
          ),
        );
        await ref(tester);
      },
    );

    testWidgets('e2eTapOldWorldRegionTab is re-exported through the barrel', (
      tester,
    ) async {
      final Future<void> Function(WidgetTester, AppLocalizations) ref =
          e2eTapOldWorldRegionTab;
      expect(ref, isNotNull);
    });
  });
}
