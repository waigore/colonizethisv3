import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_dialog_chrome.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
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
    'Train presents dialog after opening Civilian Units from rail (regression)',
    (WidgetTester tester) async {
      final humanId = empireLeftRailHumanId(game);
      await tester.pumpWidget(
        empireLeftRailScaffold(
          game: game,
          gamesBox: gamesBox,
          child: EmpireLeftRailOnlyHost(game: game, humanPlayerId: humanId),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Train'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainCiviliansDialog), findsOneWidget);
      expect(find.text('Train Civilians'), findsOneWidget);
    },
  );

  testWidgets('TrainCiviliansDialog onClose completes without error', (
    WidgetTester tester,
  ) async {
    final humanId = empireLeftRailHumanId(game);
    await tester.pumpWidget(
      empireLeftRailScaffold(
        game: game,
        gamesBox: gamesBox,
        child: EmpireLeftRailOnlyHost(game: game, humanPlayerId: humanId),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(kEmpireCivilianUnitsButtonKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();

    expect(find.byType(TrainCiviliansDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TrainDialogHeader),
        matching: find.byType(CtNinePatchButton),
      ),
      findsNothing,
    );
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    expect(find.byType(TrainCiviliansDialog), findsNothing);
  });

  testWidgets(
    'GameMapEmpireLeftRail Military Train opens TrainMilitaryDialog via bus',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        empireLeftRailScaffold(game: game, gamesBox: gamesBox),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(kEmpireMilitaryUnitsButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Train'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainMilitaryDialog), findsOneWidget);
      expect(find.text('Train Military'), findsOneWidget);
    },
  );
}
