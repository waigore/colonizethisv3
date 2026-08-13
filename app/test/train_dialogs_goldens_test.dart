// Widget goldens for the train-dialog visual acceptance criteria of issue
// ~7-11s `getDebugInitGameResult()` map generation (Refs #3656), and
// SPEC: SPEC/ui/train-civilians-dialog.md (`UNIT40001`),
// SPEC/ui/components/train-dialog-chrome.md, SPEC/ui/train-military-dialog.md,
// SPEC/ui/train-naval-dialog.md (`UNIT60001`).
import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'train_dialogs_goldens_test_support.dart';

void main() {
  suppressLogsForTests();

  late TrainDialogsGoldenFixtures fx;

  setUpAll(() {
    fx = loadTrainDialogsGoldenFixtures();
  });

  testWidgets(
    'golden: UNIT40001 Train Civilians dialog — £+comma treasury, boxed '
    'resource bar, name-over-cost rows (Refs #3568 AC1/AC3/AC4)',
    (WidgetTester tester) async {
      const key = ValueKey<String>('train_civilians_dialog_golden');
      await pumpTrainDialogsGoldenHost(
        tester,
        TrainCiviliansDialog(
          game: fx.withResources(treasury: 5000, paper: 12),
          humanPlayerId: fx.humanPlayerId,
          currentOrders: const Orders(),
          bus: AppEventBus.create(),
        ),
        key,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TrainCiviliansDialog), findsOneWidget);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('£5,000'), findsOneWidget);
      expect(find.textContaining('5k'), findsNothing);
      expectTrainDialogChromeParity(tester);

      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/train_civilians_dialog_default.png'),
      );
    },
  );

  testWidgets(
    'golden: UNIT40001 Train Civilians dialog — both-resource deficit hint '
    '"Treasury low, Paper low" (Refs #3568 AC5)',
    (WidgetTester tester) async {
      const key = ValueKey<String>('train_civilians_dialog_deficit_golden');
      final player = fx.player(fx.humanPlayerId);
      final capital =
          player.capitalProvinceId ?? player.capitalTile?.provinceId;
      expect(capital, isNotNull, reason: 'debug game needs capital');
      final limitedGame = fx.game.copyWith(
        players: [
          player.copyWith(
            treasury: 1500,
            stockpile: const Stockpile(quantities: {'paper': 3}),
            capitalProvinceId: capital,
          ),
          ...fx.game.players.where((p) => p.id != fx.humanPlayerId),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          fx.humanPlayerId: [
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary: false,
              spawnProvinceId: capital!,
            ),
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary: false,
              spawnProvinceId: capital,
            ),
          ],
        },
      );

      await pumpTrainDialogsGoldenHost(
        tester,
        TrainCiviliansDialog(
          game: limitedGame,
          humanPlayerId: fx.humanPlayerId,
          currentOrders: orders,
          bus: AppEventBus.create(),
        ),
        key,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Treasury low, Paper low'), findsOneWidget);

      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/train_civilians_dialog_deficit.png'),
      );
    },
  );

  testWidgets(
    'golden: UNIT40001 Train Civilians dialog — Reset restores remaining == '
    'total in the resource bar (Refs #3601 AC3, gap G2)',
    (WidgetTester tester) async {
      const key = ValueKey<String>('train_civilians_dialog_reset_golden');
      final player = fx.player(fx.humanPlayerId);
      final capital =
          (player.capitalProvinceId ?? player.capitalTile?.provinceId)!;
      final richGame = fx.game.copyWith(
        players: [
          player.copyWith(
            treasury: 5000,
            stockpile: const Stockpile(quantities: {'paper': 12}),
            capitalProvinceId: capital,
          ),
          ...fx.game.players.where((p) => p.id != fx.humanPlayerId),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          fx.humanPlayerId: [
            for (var i = 0; i < 2; i++)
              BuildUnitOrder(
                unitType: kUnitTypeBuilder,
                isMilitary: false,
                spawnProvinceId: capital,
              ),
          ],
        },
      );

      await pumpTrainDialogsGoldenHost(
        tester,
        TrainCiviliansDialog(
          game: richGame,
          humanPlayerId: fx.humanPlayerId,
          currentOrders: orders,
          bus: AppEventBus.create(),
        ),
        key,
      );

      expect(find.textContaining('£3,000 / £5,000'), findsOneWidget);
      expect(find.textContaining('8 / 12'), findsOneWidget);

      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TrainCiviliansDialog), findsOneWidget);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('£5,000 / £5,000'), findsOneWidget);
      expect(find.textContaining('12 / 12'), findsOneWidget);

      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/train_civilians_dialog_reset.png'),
      );
    },
  );

  testWidgets(
    'golden: UNIT50001/UNIT60001 default + deficit train dialogs '
    '(Refs #3568 AC6, #3601 AC5/AC6/AC8/AC9)',
    (WidgetTester tester) async {
      for (final case_ in <
        ({
          Key key,
          Widget Function(Game) dialog,
          Game Function() game,
          void Function(WidgetTester) assertUi,
          String golden,
        })
      >[
        (
          key: const ValueKey<String>('train_military_dialog_golden'),
          dialog: (g) => TrainMilitaryDialog(
            game: g,
            humanPlayerId: fx.humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
          game: fx.military,
          assertUi: (t) {
            expect(find.byType(TrainMilitaryDialog), findsOneWidget);
            expect(find.textContaining('£10,000'), findsOneWidget);
            expectTrainDialogChromeParity(t);
          },
          golden: 'goldens/train_military_dialog_default.png',
        ),
        (
          key: const ValueKey<String>('train_military_dialog_deficit_golden'),
          dialog: (g) => TrainMilitaryDialog(
            game: g,
            humanPlayerId: fx.humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
          game: () => fx.military(treasury: 0),
          assertUi: (t) {
            expect(find.byType(TrainMilitaryDialog), findsOneWidget);
            expect(trainDialogsDangerColoredTextCount(t), greaterThan(0));
            expect(trainDialogsHasDangerPlusButton(t), isTrue);
          },
          golden: 'goldens/train_military_dialog_deficit.png',
        ),
        (
          key: const ValueKey<String>('train_naval_dialog_golden'),
          dialog: (g) => TrainNavalDialog(
            game: g,
            humanPlayerId: fx.humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
          game: fx.naval,
          assertUi: (t) {
            expect(find.byType(TrainNavalDialog), findsOneWidget);
            expect(find.textContaining('£50,000 / £50,000'), findsOneWidget);
            expectTrainDialogChromeParity(t);
          },
          golden: 'goldens/train_naval_dialog_default.png',
        ),
        (
          key: const ValueKey<String>('train_naval_dialog_deficit_golden'),
          dialog: (g) => TrainNavalDialog(
            game: g,
            humanPlayerId: fx.humanPlayerId,
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
          game: () => fx.naval(treasury: 0),
          assertUi: (t) {
            expect(find.byType(TrainNavalDialog), findsOneWidget);
            expect(trainDialogsDangerColoredTextCount(t), greaterThan(0));
            expect(trainDialogsHasDangerPlusButton(t), isTrue);
          },
          golden: 'goldens/train_naval_dialog_deficit.png',
        ),
      ]) {
        await pumpTrainDialogsGoldenHost(tester, case_.dialog(case_.game()), case_.key);
        expect(tester.takeException(), isNull);
        expectEditorialMonocleDarkChrome(tester);
        case_.assertUi(tester);
        await expectLater(
          find.byKey(case_.key),
          matchesGoldenFile(case_.golden),
        );
      }
    },
  );
}
