import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'panel_test_fixtures.dart';
import 'app_test_hive_harness.dart';
import 'game_map_empire_left_rail_test_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    game = buildTrainPanelTestGame();
    gamesBox = await openAppTestHiveBox(suiteId: 'empire_rail');
  });

  testWidgets(
    'GameMapEmpireLeftRail tapping Production navigates to ProductionScreen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        empireLeftRailScaffold(
          game: game,
          gamesBox: gamesBox,
          onGenerateRoute: Routes.generate,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(kEmpireProductionButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(ProductionScreen), findsOneWidget);
    },
  );

  testWidgets('GameMapEmpireLeftRail tapping Technology navigates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(
        game: game,
        gamesBox: gamesBox,
        onGenerateRoute: Routes.generate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireTechnologyButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Technology'), findsOneWidget);
  });

  testWidgets('GameMapEmpireLeftRail opens Military Units panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(
        game: game,
        gamesBox: gamesBox,
        viewport: const Size(480, 1600),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireMilitaryUnitsButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
  });

  testWidgets('GameMapEmpireLeftRail opens Naval Units panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(
        game: game,
        gamesBox: gamesBox,
        viewport: const Size(480, 1600),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireNavalUnitsButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(NavalUnitsPanel), findsOneWidget);
  });

  testWidgets('GameMapEmpireLeftRail opens Civilian Units sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(game: game, gamesBox: gamesBox),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(CivilianUnitsPanel), findsOneWidget);
  });

  testWidgets('GameMapEmpireLeftRail hides debug console icon by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(game: game, gamesBox: gamesBox),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(kEmpireDebugConsoleButtonKey), findsNothing);
  });

  testWidgets('GameMapEmpireLeftRail shows debug console icon when enabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(
        game: game,
        gamesBox: gamesBox,
        debugConsoleEnabled: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(kEmpireDebugConsoleButtonKey), findsOneWidget);
  });

  testWidgets('GameMapEmpireLeftRail Diplomacy pushes DiplomacyScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      empireLeftRailScaffold(
        game: game,
        gamesBox: gamesBox,
        onGenerateRoute: Routes.generate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireDiplomacyButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(DiplomacyScreen), findsOneWidget);
  });
}
