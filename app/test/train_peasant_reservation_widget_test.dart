// Widget ACs for Train Military/Naval peasant reservation (Refs #4566).

import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'train_peasant_reservation_widget_cases.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'UNIT50001: 3 apprentice trains → Peasants 5/8 + worker-training gist',
    (tester) async {
      await pumpTrainPeasantReservationMilitary(
        tester,
        game: trainPeasantReservationGame(),
        currentOrders: trainPeasantReservationWorkerTrains(3),
      );
      expect(find.textContaining('5 / 8'), findsOneWidget);
      expect(
        find.textContaining('already promised to worker training'),
        findsOneWidget,
      );
      expect(find.textContaining('already promised to ships'), findsNothing);
    },
  );

  testWidgets(
    'UNIT50001: + accepts five then refuses sixth when 3 workers reserved',
    (tester) async {
      await pumpTrainPeasantReservationMilitary(
        tester,
        game: trainPeasantReservationGame(),
        currentOrders: trainPeasantReservationWorkerTrains(3),
      );
      final plusButtons = find.widgetWithText(CtNinePatchButton, '+');
      expect(plusButtons, findsWidgets);
      for (var i = 0; i < 5; i++) {
        await tester.ensureVisible(plusButtons.first);
        await tester.tap(plusButtons.first);
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('0 / 8'), findsOneWidget);
      await tester.tap(plusButtons.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('0 / 8'), findsOneWidget);
      expect(find.textContaining('-1 / 8'), findsNothing);
    },
  );

  testWidgets('UNIT50001: 2 ships → Peasants 6/8 + ships gist', (tester) async {
    await pumpTrainPeasantReservationMilitary(
      tester,
      game: trainPeasantReservationGame(),
      currentOrders: trainPeasantReservationShipBuilds(2),
    );
    expect(find.textContaining('6 / 8'), findsOneWidget);
    expect(find.textContaining('already promised to ships'), findsOneWidget);
    expect(
      find.textContaining('already promised to worker training'),
      findsNothing,
    );
  });

  testWidgets(
    'UNIT50001: own staged regiments counted once; gist omitted',
    (tester) async {
      await pumpTrainPeasantReservationMilitary(
        tester,
        game: trainPeasantReservationGame(),
        currentOrders: trainPeasantReservationRegimentBuilds(2),
      );
      expect(find.textContaining('6 / 8'), findsOneWidget);
      expect(find.textContaining('already promised'), findsNothing);
    },
  );

  testWidgets('UNIT50001: clean pool omits promised gist', (tester) async {
    await pumpTrainPeasantReservationMilitary(
      tester,
      game: trainPeasantReservationGame(),
    );
    expect(find.textContaining('8 / 8'), findsOneWidget);
    expect(find.textContaining('already promised'), findsNothing);
  });

  testWidgets(
    'UNIT50001: Peasants chip tooltip lists families without order class names',
    (tester) async {
      await pumpTrainPeasantReservationMilitary(
        tester,
        game: trainPeasantReservationGame(),
        currentOrders: trainPeasantReservationWorkerTrains(2),
      );
      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byType(TrainMilitaryDialog),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Tooltip &&
                (w.message?.contains('already promised') ?? false),
          ),
        ),
      );
      expect(tooltip.message, contains('already promised to worker training'));
      expect(tooltip.message, isNot(contains('RecruitWorkerOrder')));
      expect(tooltip.message, isNot(contains('BuildUnitOrder')));
    },
  );

  testWidgets(
    'UNIT60001: military builds reduce available ship peasants',
    (tester) async {
      await pumpTrainPeasantReservationNaval(
        tester,
        game: trainPeasantReservationGame(),
        currentOrders: trainPeasantReservationRegimentBuilds(2),
      );
      expect(find.textContaining('6 / 8'), findsOneWidget);
      expect(
        find.textContaining('already promised to regiments'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'UNIT60001: worker trains reduce available ship peasants',
    (tester) async {
      await pumpTrainPeasantReservationNaval(
        tester,
        game: trainPeasantReservationGame(),
        currentOrders: trainPeasantReservationWorkerTrains(3),
      );
      expect(find.textContaining('5 / 8'), findsOneWidget);
      expect(
        find.textContaining('already promised to worker training'),
        findsOneWidget,
      );
    },
  );
}
