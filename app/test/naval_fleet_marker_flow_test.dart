// Fleet-marker routing tests (Refs #4343, #4625).
// SPEC: SPEC/ui/map-widget.md, naval-mission-menu-dialog.md, move-fleet-dialog.md.

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_fleet_marker_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_fleet_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  const humanId = 'gp_marker_route';
  const locationScope = 'port:oldWorld|cap1';
  const tileKey = 'oldWorld|cap1|0|0';

  Game homeOnlyGame() => buildNavalPanelCapitalHomeAndPeersGame(
    humanId: humanId,
    gameId: 'g_marker_home',
    displayName: 'Marker Home',
    peerFleets: const [],
  );

  Game atSeaPeerGame() => buildNavalPanelNamedSeaZoneGame(humanId: humanId);

  Future<void> pumpOpenButton(
    WidgetTester tester, {
    required Future<void> Function(BuildContext context) onPressed,
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => onPressed(context),
                child: const Text('open-flow'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('showNavalFleetMarkerFlow', () {
    testWidgets('non-empty Home Fleet opens detach-then-sail split', (
      tester,
    ) async {
      final game = homeOnlyGame();
      final bus = AppEventBus();
      OpenNavalUnitsPanelEvent? opened;
      addTearDown(
        bus.on<OpenNavalUnitsPanelEvent>().listen((e) => opened = e).cancel,
      );

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: [homeFleetIdFor(humanId)],
          locationScopeKey: locationScope,
          tileScopeTileKey: tileKey,
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      expect(opened, isNull);
      expect(find.byType(SplitFleetDialog), findsOneWidget);
      expect(find.byType(MoveFleetDialog), findsNothing);
      expect(find.byType(NavalMissionMenuDialog), findsNothing);
    });

    testWidgets('empty Home Fleet only opens tile-scoped Naval Units event', (
      tester,
    ) async {
      final game = buildNavalPanelCapitalHomeAndPeersGame(
        humanId: humanId,
        gameId: 'g_marker_home_empty',
        displayName: 'Marker Home Empty',
        peerFleets: const [],
        homeShips: const [],
      );
      final bus = AppEventBus();
      OpenNavalUnitsPanelEvent? opened;
      addTearDown(
        bus.on<OpenNavalUnitsPanelEvent>().listen((e) => opened = e).cancel,
      );

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: const MapTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: [homeFleetIdFor(humanId)],
          locationScopeKey: locationScope,
          tileScopeTileKey: tileKey,
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      expect(opened, isNotNull);
      expect(opened!.locationScopeKey, locationScope);
      expect(opened!.tileScopeTileKey, tileKey);
      expect(opened!.initialSelectedFleetId, homeFleetIdFor(humanId));
      expect(find.byType(MoveFleetDialog), findsNothing);
      expect(find.byType(NavalMissionMenuDialog), findsNothing);
      expect(find.byType(SplitFleetDialog), findsNothing);
    });

    testWidgets('at-sea marker opens mission menu with Sail row', (
      tester,
    ) async {
      final game = atSeaPeerGame();
      final bus = AppEventBus();

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: const MapTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: const ['sea_named'],
          locationScopeKey: 'sea:oldWorld|zone_alpha',
          tileScopeTileKey: 'oldWorld|zone_alpha|0|0',
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      expect(find.byType(NavalMissionMenuDialog), findsOneWidget);
      expect(find.text('Sail / Move'), findsOneWidget);
      expect(find.text('Patrol'), findsOneWidget);
    });
  });
}
