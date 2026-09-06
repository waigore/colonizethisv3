// Peasant reservation widget-test fixtures (Refs #4734 Slice E, #4566).

import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

const kTrainPeasantReservationCapital = 'oldWorld|cap';

Game trainPeasantReservationGame({int peasants = 8, int treasury = 50000}) {
  return buildPanelTestGame(
    id: 'train-peasant-reservation-widget',
    players: [
      Player(
        id: kPanelTestHumanPlayerId,
        displayName: 'Test Human',
        isHuman: true,
        capitalProvinceId: kTrainPeasantReservationCapital,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: kTrainPeasantReservationCapital,
          x: 0,
          y: 0,
        ),
        treasury: treasury,
        workerPool: WorkerPool(peasants: peasants),
        stockpile: Stockpile(
          quantities: {
            for (final id in [
              'fabric',
              'castIron',
              'lumber',
              'horses',
              'steel',
              'bronze',
              'coal',
            ])
              id: 100,
          },
        ),
        techUnlocked: {
          for (final techId in unlockingTechByRegimentId.values) techId: true,
          for (final techId in unlockingTechByShipId.values) techId: true,
        },
      ),
    ],
  );
}

Orders trainPeasantReservationWorkerTrains(int count) => Orders(
      recruitWorkerOrdersByPlayerId: {
        kPanelTestHumanPlayerId: List<RecruitWorkerOrder>.generate(
          count,
          (_) => const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        ),
      },
    );

Orders trainPeasantReservationShipBuilds(int count) => Orders(
      buildUnitOrdersByPlayerId: {
        kPanelTestHumanPlayerId: List<BuildUnitOrder>.generate(
          count,
          (_) => BuildUnitOrder(
            unitType: 'carrack',
            isMilitary: false,
            spawnProvinceId: kTrainPeasantReservationCapital,
          ),
        ),
      },
    );

Orders trainPeasantReservationRegimentBuilds(int count) => Orders(
      buildUnitOrdersByPlayerId: {
        kPanelTestHumanPlayerId: List<BuildUnitOrder>.generate(
          count,
          (_) => BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary: true,
            spawnProvinceId: kTrainPeasantReservationCapital,
          ),
        ),
      },
    );

Future<void> pumpTrainPeasantReservationMilitary(
  WidgetTester tester, {
  required Game game,
  Orders currentOrders = const Orders(),
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: TrainMilitaryDialog(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          currentOrders: currentOrders,
          bus: AppEventBus.create(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpTrainPeasantReservationNaval(
  WidgetTester tester, {
  required Game game,
  Orders currentOrders = const Orders(),
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: TrainNavalDialog(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          currentOrders: currentOrders,
          bus: AppEventBus.create(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
