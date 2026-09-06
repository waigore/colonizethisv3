// Widget golden coverage for in-game unit panels (Refs #3514, #3627).

import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_card.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'game_fixture.dart';
import 'map_view_fixture.dart';
import 'unit_panels_goldens_harness.dart';

void main() {
  suppressLogsForTests();

  late final Game game;
  late final String humanPlayerId;
  late final MapTopology combinedTopology;

  setUpAll(() {
    game = loadSeed42Game();
    combinedTopology = loadSeed42MapViewData().combinedTopology;
    humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  });

  testWidgets('golden: UNIT10001 Civilian Units panel chrome (Refs #3514)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_civilian_golden');
    await pumpUnitPanelsGoldenHost(
      tester,
      CivilianUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CivilianUnitsPanel), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_civilian_default.png'),
    );
  });

  testWidgets('golden: UNIT20001 Military Units panel chrome (Refs #3514)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_military_golden');
    await pumpUnitPanelsGoldenHost(
      tester,
      MilitaryUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
        topology: combinedTopology,
        draftOrders: const Orders(),
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_military_default.png'),
    );
  });

  testWidgets('golden: UNIT30001 Naval Units panel chrome (Refs #3514)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_naval_golden');
    await pumpUnitPanelsGoldenHost(
      tester,
      NavalUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
        topology: combinedTopology,
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavalUnitsPanel), findsOneWidget);
    expect(find.byType(UnitsEntityCard), findsWidgets);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_naval_default.png'),
    );
  });

  testWidgets('golden: UNIT10001 Civilian Units panel mobile (Refs #3627)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_civilian_mobile_golden');
    await pumpUnitPanelsGoldenMobileHost(
      tester,
      CivilianUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CivilianUnitsPanel), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_civilian_mobile.png'),
    );
  });

  testWidgets('golden: UNIT20001 Military Units panel mobile (Refs #3627)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_military_mobile_golden');
    await pumpUnitPanelsGoldenMobileHost(
      tester,
      MilitaryUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
        topology: combinedTopology,
        draftOrders: const Orders(),
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_military_mobile.png'),
    );
  });

  testWidgets('golden: UNIT30001 Naval Units panel mobile (Refs #3627)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_naval_mobile_golden');
    await pumpUnitPanelsGoldenMobileHost(
      tester,
      NavalUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
        topology: combinedTopology,
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavalUnitsPanel), findsOneWidget);
    expect(find.byType(UnitsEntityCard), findsWidgets);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_naval_mobile.png'),
    );
  });
}
