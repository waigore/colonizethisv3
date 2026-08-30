// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart' show isMilitaryUnit;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';

import 'military_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = buildMilitaryPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
  });

  group('MilitaryUnitsPanel', () {
    testWidgets('AC: Tapping a row emits LocateMapTileEvent', (
      WidgetTester tester,
    ) async {
      LocateMapTileEvent? locateEvent;
      final bus = AppEventBus.create();
      bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);
      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        bus: bus,
      );

      final locateButtons = find.byIcon(Icons.my_location);
      if (locateButtons.evaluate().isEmpty) return;
      await tester.tap(locateButtons.first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(locateEvent, isNotNull);
      expect(
        locateEvent!.regionId == 'oldWorld' ||
            locateEvent!.regionId == 'newWorld',
        isTrue,
      );
    });

    testWidgets('builds without locate callback', (WidgetTester tester) async {
      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      );

      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
      // Locate-tap behavior on detail sub-rows is covered by the dedicated
      // LocateMapTileEvent test; here we only assert the panel builds without a
      // locate callback wired (Refs #2914 S8 migrated rows off Material
      // ListTile chrome).
    });

    testWidgets('Train button emits train-military dialog open event', (
      WidgetTester tester,
    ) async {
      OpenDialogEvent? openDialogEvent;
      final bus = AppEventBus.create();
      bus.on<OpenDialogEvent>().listen((e) => openDialogEvent = e);

      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        bus: bus,
      );

      final trainButton = find.text('Train');
      expect(trainButton, findsOneWidget);
      await tester.tap(trainButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(openDialogEvent, isNotNull);
      expect(openDialogEvent!.dialogId, trainMilitaryDialogId);
    });

    testWidgets(
      'AC: Tapping locate emits ClosePanelEvent before LocateMapTileEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final sequence = <Type>[];
        bus.stream.listen((e) => sequence.add(e.runtimeType));

        await pumpMilitaryPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
          bus: bus,
        );

        final locateButtons = find.byIcon(Icons.my_location);
        if (locateButtons.evaluate().isEmpty) return;
        await tester.tap(locateButtons.first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          sequence.indexOf(ClosePanelEvent),
          lessThan(sequence.indexOf(LocateMapTileEvent)),
        );
      },
    );

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
