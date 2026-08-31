// Open-to-interactive profiling anchors for empire-rail UNIT* bottom sheets
// (Refs #4688 Slice 11).
//
// Split from empire_rail_panel_open_surface_budget_test.dart for repo
// app/test file-size gate (330 physical lines).

import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_test/flutter_test.dart';

import 'empire_rail_panel_open_surface_budget_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  testWidgets('empire-rail UNIT20001 Military Units cold and warm open (Refs #4688)', (
    WidgetTester tester,
  ) async {
    final game = buildMilitaryPanelTestGame();
    final bus = AppEventBus.create();
    await coldWarmEmpireRailUnitsSheetOpenCycle(
      tester,
      panel: MilitaryUnitsPanel(
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
        bus: bus,
        topology: const MapTopology(),
        draftOrders: const Orders(),
      ),
      interactiveProbe: find.byType(MilitaryUnitsPanel),
    );
  });

  testWidgets('empire-rail UNIT30001 Naval Units cold and warm open (Refs #4688)', (
    WidgetTester tester,
  ) async {
    final game = buildNavalPanelTestGame();
    final bus = AppEventBus.create();
    await coldWarmEmpireRailUnitsSheetOpenCycle(
      tester,
      panel: NavalUnitsPanel(
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
        bus: bus,
        topology: const MapTopology(),
        draftOrders: const Orders(),
      ),
      interactiveProbe: find.byType(NavalUnitsPanel),
    );
  });

  testWidgets('empire-rail UNIT10001 Civilian Units cold and warm open (Refs #4688)', (
    WidgetTester tester,
  ) async {
    final game = buildCivilianPanelTestGame();
    final bus = AppEventBus.create();
    await coldWarmEmpireRailUnitsSheetOpenCycle(
      tester,
      panel: CivilianUnitsPanel(
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
        bus: bus,
        currentOrders: const Orders(),
      ),
      interactiveProbe: find.byType(CivilianUnitsPanel),
    );
  });
}
