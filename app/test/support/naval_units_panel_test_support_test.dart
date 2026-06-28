// Smoke tests for the shared `NavalUnitsPanel` widget-test scaffolding.
//
// Verifies the consolidated helpers in `naval_units_panel_test_support.dart`
// (extracted from the five `naval_units_panel_part*_test.dart` files, Refs
// #3730) build the canonical panel host and bridge the split/transfer events
// the same way the running shell does, so the part files keep their behavior.
//
// SPEC: SPEC/ui/naval-units-panel.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';

import 'naval_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'buildNavalPanel hosts NavalUnitsPanel inside a MaterialApp scaffold',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildNavalPanel(
          game: buildNavalPanelTestGame(),
          humanPlayerId: kPanelTestHumanPlayerId,
        ),
      );
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(NavalUnitsPanel), findsOneWidget);
    },
  );

  test(
    'wireNavalSplitForWidgetTest applies the split and re-emits the update',
    () async {
      final bus = AppEventBus.create();
      final game = buildNavalPanelTestGame();
      final originalFleetCount = game.worldState.fleets.length;
      final sub = wireNavalSplitForWidgetTest(
        bus: bus,
        gameSnapshot: () => game,
      );
      addTearDown(sub.cancel);

      final updated = bus.on<NavalFleetsUpdatedEvent>().first;
      bus.emit(
        NavalSplitFleetRequestedEvent(
          humanPlayerId: kPanelTestHumanPlayerId,
          originalFleetId: 'fleet_nh1',
          shipInstanceIdsToNewFleet: const ['n2'],
        ),
      );

      final event = await updated;
      expect(
        event.game.worldState.fleets.length,
        greaterThan(originalFleetCount),
      );
    },
  );

  test(
    'wireNavalTransferForWidgetTest moves the ship and re-emits the update',
    () async {
      final bus = AppEventBus.create();
      final game = buildNavalPanelTestGame();
      final homeFleetId = homeFleetIdFor(kPanelTestHumanPlayerId);
      final sub = wireNavalTransferForWidgetTest(
        bus: bus,
        gameSnapshot: () => game,
      );
      addTearDown(sub.cancel);

      final updated = bus.on<NavalFleetsUpdatedEvent>().first;
      bus.emit(
        NavalTransferShipsRequestedEvent(
          humanPlayerId: kPanelTestHumanPlayerId,
          sourceFleetId: 'fleet_nh1',
          targetFleetId: homeFleetId,
          shipInstanceIdsToTransfer: const ['n2'],
        ),
      );

      final event = await updated;
      final source = event.game.worldState.fleets.firstWhere(
        (f) => f.id == 'fleet_nh1',
      );
      expect(source.ships.length, 1);
    },
  );
}
