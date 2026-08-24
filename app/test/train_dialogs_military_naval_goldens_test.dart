// Widget goldens for train-military and train-naval dialog visual ACs.
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

  testWidgets('golden: UNIT50001/UNIT60001 default + deficit train dialogs '
      '(Refs #3568 AC6, #3601 AC5/AC6/AC8/AC9)', (WidgetTester tester) async {
    for (final case_
        in <
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
      await pumpTrainDialogsGoldenHost(
        tester,
        case_.dialog(case_.game()),
        case_.key,
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      case_.assertUi(tester);
      await expectLater(find.byKey(case_.key), matchesGoldenFile(case_.golden));
    }
  });

  testWidgets(
    'golden: UNIT50001 Train Military — promised-peasant gist under resource '
    'bar (Refs #4566)',
    (WidgetTester tester) async {
      const key = ValueKey<String>('train_military_dialog_promised_golden');
      final base = fx.military();
      final human = base.players.firstWhere((p) => p.id == fx.humanPlayerId);
      final reservedGame = base.copyWith(
        players: [
          human.copyWith(workerPool: human.workerPool.copyWith(peasants: 8)),
          ...base.players.where((p) => p.id != fx.humanPlayerId),
        ],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          fx.humanPlayerId: List<RecruitWorkerOrder>.generate(
            3,
            (_) => const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ),
        },
      );

      await pumpTrainDialogsGoldenHost(
        tester,
        TrainMilitaryDialog(
          game: reservedGame,
          humanPlayerId: fx.humanPlayerId,
          currentOrders: orders,
          bus: AppEventBus.create(),
        ),
        key,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('5 / 8'), findsOneWidget);
      expect(
        find.textContaining('already promised to worker training'),
        findsOneWidget,
      );
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(key),
        matchesGoldenFile(
          'goldens/train_military_dialog_promised_peasants.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: UNIT50001 Train Military — narrow 320 dp with promised gist '
    '(Refs #4566 wrap)',
    (WidgetTester tester) async {
      const key = ValueKey<String>('train_military_promised_320_golden');
      final base = fx.military();
      final human = base.players.firstWhere((p) => p.id == fx.humanPlayerId);
      final reservedGame = base.copyWith(
        players: [
          human.copyWith(workerPool: human.workerPool.copyWith(peasants: 8)),
          ...base.players.where((p) => p.id != fx.humanPlayerId),
        ],
      );
      final orders = Orders(
        recruitWorkerOrdersByPlayerId: {
          fx.humanPlayerId: List<RecruitWorkerOrder>.generate(
            3,
            (_) => const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
          ),
        },
      );

      await pumpTrainDialogsGoldenHost(
        tester,
        TrainMilitaryDialog(
          game: reservedGame,
          humanPlayerId: fx.humanPlayerId,
          currentOrders: orders,
          bus: AppEventBus.create(),
        ),
        key,
        surfaceSize: const Size(320, 900),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('5 / 8'), findsOneWidget);
      expect(
        find.textContaining('already promised to worker training'),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(key),
        matchesGoldenFile(
          'goldens/train_military_dialog_promised_peasants_320.png',
        ),
      );
    },
  );
}
