// Counsel screen Military tab train-Agree confirm / affordability (Refs #4307).

import 'package:colonizethis_app/features/game/screens/counsel/counsel_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'counsel_military_screen_train_agree_confirm_support.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(
      suiteId: 'counsel_military_screen_train_confirm',
    );
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'train Agree emits snackbar when recommendation is no longer affordable (Refs #4307)',
    (WidgetTester tester) async {
      const human = kPanelTestHumanPlayerId;
      const capProvince = 'oldWorld|cap';
      const unitType = 'peasant_levies';
      final game = buildCounselMilitaryTrainConfirmGame(peasants: 2);
      final bus = AppEventBus.create();
      final snackbars = <ShowSnackBarEvent>[];
      bus.on<ShowSnackBarEvent>().listen(snackbars.add);
      final ordersNotifier = CurrentOrdersNotifier(const Orders());

      await pumpCounselMilitaryTrainConfirmScreen(
        tester,
        gamesBox: gamesBox,
        game: game,
        bus: bus,
        ordersNotifier: ordersNotifier,
        gameService: CounselMilitaryTrainMapGameServiceConfirm(
          gamesBox,
          GameSaveAdapter(),
        ),
        initialTab: CounselTab.military,
      );

      final agree = find.byKey(
        ValueKey<String>('counsel_agree_military_train_$unitType'),
      );
      expect(agree, findsOneWidget);

      ordersNotifier.replaceAll(
        Orders(
          buildUnitOrdersByPlayerId: {
            human: [
              BuildUnitOrder(
                unitType: unitType,
                isMilitary: true,
                spawnProvinceId: capProvince,
              ),
              BuildUnitOrder(
                unitType: unitType,
                isMilitary: true,
                spawnProvinceId: capProvince,
              ),
            ],
          },
        ),
      );

      await tester.tap(agree);
      await pumpSettleCapped(tester);

      expect(snackbars, hasLength(1));
      expect(
        snackbars.single.message,
        'Cannot raise those units right now — check treasury, stockpile, peasants, and queued orders.',
      );
    },
  );
}
