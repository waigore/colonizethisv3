import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';

import 'move_fleet_dialog_fixtures.dart';
import 'move_fleet_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('labels warp-zone destinations with warp copy only', (
    WidgetTester tester,
  ) async {
    await openMoveFleetDialog(tester, bus: AppEventBus.create());

    expect(
      find.textContaining('Move fleet — Fleet f_move (3 destinations)'),
      findsOneWidget,
    );
    // CtSectionLabel upper-cases its content per #2859 R9.
    expect(find.text('SEA ZONES'), findsOneWidget);
    expect(find.text('Warp OW Sea links'), findsOneWidget);
    expect(find.text('Plain OW Sea'), findsOneWidget);
    expect(find.text('Cross NW Sea links to New World'), findsOneWidget);
    expect(find.textContaining('Plain OW Sea links'), findsNothing);
    expect(find.textContaining('· Old World'), findsNothing);
    expect(find.textContaining('(cross-region)'), findsNothing);
  });

  testWidgets(
    'shows links-to Old World for new-world fleet cross-region picks',
    (WidgetTester tester) async {
      final fixture = buildMoveFleetNwFixture();
      await openMoveFleetDialog(
        tester,
        bus: AppEventBus.create(),
        playerId: fixture.playerId,
        game: fixture.game,
        topology: fixture.topology,
        fleet: fixture.fleet,
      );

      expect(find.text('Adjacent NW Sea'), findsOneWidget);
      expect(find.text('Cross OW Sea links to Old World'), findsOneWidget);
      expect(find.textContaining('· New World'), findsNothing);
      expect(find.textContaining('(cross-region)'), findsNothing);
    },
  );

  testWidgets('confirm / cancel / locate bus events', (tester) async {
    final confirmBus = AppEventBus.create();
    final latestMove = captureMoveFleetBusEvent<NavalMoveFleetRequestedEvent>(
      confirmBus,
    );
    await openMoveFleetDialog(tester, bus: confirmBus);
    await tester.tap(find.text('Cross NW Sea links to New World'));
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    final captured = latestMove();
    expect(captured, isNotNull);
    expect(captured!.humanPlayerId, kMoveFleetHumanId);
    expect(captured.moveOrder.fleetId, 'f_move');
    expect(
      captured.moveOrder.destinationSeaZoneId,
      kMoveFleetCrossRegionWarpSea,
    );
    expect(captured.moveOrder.destinationPortProvinceId, isNull);
    expect(find.text('Move fleet — f_move'), findsNothing);

    final cancelBus = AppEventBus.create();
    final cancelled = captureMoveFleetBusEvent<NavalMoveFleetRequestedEvent>(
      cancelBus,
    );
    await openMoveFleetDialog(tester, bus: cancelBus);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(cancelled(), isNull);
    expect(find.text('Move fleet — f_move'), findsNothing);

    final locateBus = AppEventBus.create();
    final latestLocate = captureMoveFleetBusEvent<LocateMapTileEvent>(
      locateBus,
    );
    await openMoveFleetDialog(tester, bus: locateBus);
    final locateButtons = find.descendant(
      of: find.byType(MoveFleetDialog),
      matching: find.byTooltip('Locate on map'),
    );
    expect(locateButtons, findsNWidgets(3));
    await tester.tap(locateButtons.first);
    await tester.pump();
    final locate = latestLocate();
    expect(locate, isNotNull);
    expect(locate!.regionId, 'newWorld');
    expect(locate.tileKey, 'newWorld|port_nw|0|0');
  });

  testWidgets(
    'in-port fleet with combined topology shows Sea zones (issue #1446)',
    (WidgetTester tester) async {
      final fixture = buildMoveFleetInPortFixture();
      await openMoveFleetDialog(
        tester,
        bus: AppEventBus.create(),
        topology: fixture.topology,
        game: fixture.game,
        fleet: fixture.fleet,
      );

      expect(
        find.text('No adjacent sea zones (check map topology).'),
        findsNothing,
      );
      expect(find.text('SEA ZONES'), findsOneWidget);
      expect(find.text('Second Sea'), findsOneWidget);
    },
  );

  testWidgets('sea zone section lists S–S neighbors only, not provinces', (
    WidgetTester tester,
  ) async {
    final fixture = buildMoveFleetMixFixture();
    await openMoveFleetDialog(
      tester,
      bus: AppEventBus.create(),
      playerId: fixture.playerId,
      game: fixture.game,
      topology: fixture.topology,
      fleet: fixture.fleet,
    );
    await tester.pumpAndSettle();

    expect(find.text('SEA ZONES'), findsOneWidget);
    expect(find.text('PROVINCES (DOCK)'), findsOneWidget);
    expect(find.text('Coastal Province'), findsOneWidget);
    expect(find.textContaining('Beta Sea'), findsOneWidget);
    expect(find.textContaining('Alpha Sea'), findsNothing);
  });
}
