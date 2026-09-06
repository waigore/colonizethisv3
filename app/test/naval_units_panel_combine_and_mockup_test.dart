// Tests for NavalUnitsPanel combine outcomes. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'naval_panel_combine_cases.dart';
import 'naval_panel_mockup_pins.dart';
import 'naval_units_panel_sea_mission_scenarios.dart';
import 'naval_units_panel_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  group('NavalUnitsPanel combine', () {
    for (final case_ in navalPanelCombineDisabledCases()) {
      testWidgets(case_.name, (WidgetTester tester) async {
        await pumpNavalCheckCombineDisabled(
          tester,
          game: case_.build(),
          humanId: case_.humanId,
          fleetLabels: case_.labels,
        );
      });
    }

    testWidgets(
      'AC: Combining into Home Fleet merges ships into home id when Home is selected',
      (WidgetTester tester) async {
        const humanId = 'gp_home_combine';
        final homeId = homeFleetIdFor(humanId);

        final updated = await pumpNavalHomeFleetTransferAll(
          tester,
          game: buildNavalPanelCapitalHomeAndPeersGame(
            humanId: humanId,
            gameId: 'g_home_combine',
            displayName: 'Home combine tester',
            homeMission: FleetMission.patrol,
            homeShips: const [ShipInstance(id: 'ship_h', typeId: 'carrack')],
            nextShipInstanceSeq: 3,
            peerFleets: [
              navalPanelPortShipFleet(
                id: 'at_capital',
                humanId: humanId,
                port: kNavalPanelCapProvince,
                shipId: 'ship_v',
                typeId: 'fluyte',
              ),
            ],
          ),
          humanId: humanId,
          fleetLabels: const ['Home Fleet', 'Fleet at_capital'],
          transferTypeId: 'fluyte',
        );

        expect(updated, isNotNull);
        final fleetsAfter = updated!.game.worldState.fleets;
        expect(fleetsAfter.where((f) => f.id == 'at_capital'), isEmpty);

        final home = fleetsAfter.firstWhere((f) => f.id == homeId);
        final shipIds = home.ships.map((s) => s.id).toList()..sort();
        expect(shipIds, ['ship_h', 'ship_v']);
        expect(home.mission, FleetMission.none);
      },
    );

    testWidgets(
      'AC: Home Fleet and adjacent sea source enable selected-ship transfer',
      (WidgetTester tester) async {
        const humanId = 'gp_home_adjacent';
        await pumpNavalPanel(
          tester,
          game: buildNavalPanelHomeAdjacentSeaSourceGame(humanId: humanId),
          humanPlayerId: humanId,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
        );
        await tapNavalFleetCheckboxes(tester, ['Home Fleet', 'Fleet sea_source']);
        expectNavalCombineEnabled(tester, enabled: true);
        await tapNavalCombine(tester);
        expect(find.text('Transfer Ships to Home Fleet'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: Home Fleet transfer moves selected ships and keeps source when ships remain',
      (WidgetTester tester) async {
        await pumpNavalHomePartialTransfer(
          tester,
          humanId: 'gp_home_transfer_apply',
        );
      },
    );

    testWidgets(
      'AC: Home Fleet and non-adjacent sea source keep Combine disabled',
      (WidgetTester tester) async {
        const humanId = 'gp_home_non_adjacent';
        await pumpNavalCheckCombineDisabled(
          tester,
          game: buildNavalPanelHomeNonAdjacentSeaGame(humanId: humanId),
          humanId: humanId,
          fleetLabels: const ['Home Fleet', 'Fleet sea_far'],
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(
            seaZoneId: 'zone_far',
            includeEdge: false,
          ),
        );
      },
    );

    for (final case_ in navalPanelCombineOutcomeCases()) {
      testWidgets(case_.name, (WidgetTester tester) async {
        await pumpNavalCombineOutcomeCase(tester, case_);
      });
    }
  });

  group('Naval mockup fidelity (UNIT30001)', () {
    registerNavalMockupFidelityTests(
      testWidgets,
      buildNavalPanelMockupFidelityGame(),
    );
  });
}
