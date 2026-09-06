// Part1 scenario pumps and pins (Refs #4224 Slice D densify).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'naval_units_panel_test_support.dart';

export 'naval_panel_part1_pin_pumps.dart';

typedef NavalPanelPart1PinCase = ({
  String name,
  Future<void> Function(WidgetTester tester) run,
});

List<NavalPanelPart1PinCase> navalPanelPart1PinCases() => [
  (
    name: 'AC: Beachhead status and empty-naval empty-state pins',
    run: (tester) async {
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelBeachheadMissionGame(humanId: 'p_beach'),
        humanPlayerId: 'p_beach',
      );
      expect(find.textContaining('Beachhead'), findsWidgets);
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelEmptyHumanGame(humanId: 'p_empty'),
        humanPlayerId: 'p_empty',
      );
      expect(find.text('No naval units'), findsOneWidget);
    },
  ),
  (
    name:
        'AC: Marker-scoped capital port view shows Home Fleet and not empty state',
    run: (tester) async {
      const humanId = 'gp_marker_scope';
      const capital = 'oldWorld|p1';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelMarkerScopeCapitalGame(humanId: humanId),
        humanPlayerId: humanId,
        locationScopeKey: 'port:$capital',
      );
      expect(find.widgetWithText(ExpansionTile, 'Home Fleet'), findsOneWidget);
      expect(find.text('No naval units'), findsNothing);
    },
  ),
  (
    name:
        'AC: Cross-region projected marker scope shows destination region rows',
    run: (tester) async {
      const humanId = 'gp_cross_region_scope';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelSingleSeaFleetGame(
          humanId: humanId,
          gameId: 'g_cross_region_scope',
          displayName: 'Cross Scope',
        ),
        humanPlayerId: humanId,
        topology: buildNavalTwoSeaZonesTopology(
          fromZoneId: 'oldWorld|s1',
          toZoneId: 'newWorld|s2',
        ),
        draftOrders: const Orders(
          navalMoveOrdersByPlayerId: {
            humanId: [
              NavalMoveOrder(
                fleetId: 'f1',
                destinationSeaZoneId: 'newWorld|s2',
              ),
            ],
          },
        ),
        locationScopeKey: 'sea:newWorld|s2',
      );
      expect(find.text('NEW WORLD'), findsOneWidget);
      expect(find.text('OLD WORLD'), findsNothing);
      expect(find.textContaining('Fleet f1'), findsOneWidget);
    },
  ),
  (
    name: 'AC: expanded composition lists ship display names not raw ids',
    run: (tester) async {
      const humanId = 'gp_ship_display';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_ship_labels',
          displayName: 'Ship Label Tester',
          peerFleets: const [],
          homeShips: const [ShipInstance(id: 'h1', typeId: 'carrack')],
        ),
        humanPlayerId: humanId,
      );
      final homeTile = navalFleetTileFinder('Home Fleet');
      await expandNavalFleetTile(tester, homeTile);
      expect(find.text('Carrack'), findsOneWidget);
      expect(find.text('×1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('carrack:'), findsNothing);
    },
  ),
];
