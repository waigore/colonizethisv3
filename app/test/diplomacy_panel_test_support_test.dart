// Smoke tests for shared diplomacy/civilian panel hosts (Refs #4013).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';

import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('buildCivilianPanel hosts CivilianUnitsPanel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildCivilianPanel(
        game: buildCivilianPanelTestGame(),
        humanPlayerId: kPanelTestHumanPlayerId,
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CivilianUnitsPanel), findsOneWidget);
    expect(find.byType(CivilianPanelBusDialogHost), findsOneWidget);
    expect(find.byType(PanelBusDialogHost), findsOneWidget);
  });

  testWidgets('buildDiplomacyPanel hosts DiplomacyPanel', (
    WidgetTester tester,
  ) async {
    await bindDiplomacyTallTestSurface(tester);
    await tester.pumpWidget(
      buildDiplomacyPanel(
        game: buildDiplomacyPanelTestGame(),
        humanPlayerId: kPanelTestHumanPlayerId,
        topology: const MapTopology(),
      ),
    );
    await pumpDiplomacyPanelBuilt(tester);
    expect(find.byType(DiplomacyPanel), findsOneWidget);
    expect(find.byType(DiplomacyPanelBusDialogHost), findsOneWidget);
    expect(find.byType(PanelBusDialogHost), findsOneWidget);
  });

  testWidgets('buildDiplomacyPanelShell hosts DiplomacyPanel without dialog host', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    await tester.pumpWidget(
      buildDiplomacyPanelShell(
        game: buildDiplomacyPanelTestGame(),
        humanPlayerId: kPanelTestHumanPlayerId,
        topology: const MapTopology(),
        bus: bus,
      ),
    );
    await tester.pump();
    expect(find.byType(DiplomacyPanel), findsOneWidget);
    expect(find.byType(DiplomacyPanelBusDialogHost), findsNothing);
  });
}
