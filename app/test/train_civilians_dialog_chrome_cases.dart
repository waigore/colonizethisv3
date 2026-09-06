// Train civilians dialog chrome AC scenario table (Refs #4734 Slice E, #4021).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'train_civilians_dialog_test_support.dart';

typedef TrainCiviliansChromeCase = ({
  String name,
  Game Function() game,
  Orders Function() orders,
  void Function(WidgetTester tester) expectUi,
});

List<TrainCiviliansChromeCase> trainCiviliansDialogChromeCases(
  TrainCiviliansDialogTestHarness harness,
) =>
    [
      (
        name: 'Dialog shows title Train Civilians',
        game: () => harness.game,
        orders: () => const Orders(),
        expectUi: (tester) =>
            expect(find.text('Train Civilians'), findsOneWidget),
      ),
      (
        name: 'Resource bar shows Treasury and Paper',
        game: () => harness.game,
        orders: () => const Orders(),
        expectUi: (tester) {
          expect(find.textContaining('Treasury:'), findsOneWidget);
          expect(find.textContaining('Paper:'), findsOneWidget);
        },
      ),
      (
        name: 'Treasury renders with £ + comma grouping (£5,000), not 5k',
        game: () => harness.gameWithResources(treasury: 5000, paper: 12),
        orders: () => const Orders(),
        expectUi: (tester) {
          expect(find.textContaining('£5,000'), findsOneWidget);
          expect(find.textContaining('5k'), findsNothing);
        },
      ),
      (
        name: 'Unlocked cost line reads "£1,000 + 2 paper" (lowercase paper)',
        game: () => harness.gameWithResources(treasury: 10000, paper: 100),
        orders: () => const Orders(),
        expectUi: (tester) =>
            expect(find.textContaining('£1,000 + 2 paper'), findsWidgets),
      ),
      (
        name: 'Both-resource deficit reads "Treasury low, Paper low" (comma-join)',
        game: () => harness.gameWithCapital(treasury: 1500, paper: 3),
        orders: () => harness.builderOrders(2),
        expectUi: (tester) {
          expect(find.text('Treasury low, Paper low'), findsOneWidget);
          expect(find.text('Treasury low and Paper low'), findsNothing);
        },
      ),
      (
        name: 'All 6 civilian unit types are listed',
        game: () => harness.game,
        orders: () => const Orders(),
        expectUi: (tester) {
          for (final econ in CivilianEconomyCatalog.all) {
            final bare = find.text(econ.id);
            final locked = find.text('\u{1F512} ${econ.id}');
            expect(
              bare.evaluate().isNotEmpty || locked.evaluate().isNotEmpty,
              isTrue,
              reason:
                  '${econ.id} row should render (bare or 🔒-prefixed if locked)',
            );
          }
        },
      ),
      (
        name: 'Stepper starts at 0 for each unit type',
        game: () => harness.game,
        orders: () => const Orders(),
        expectUi: (tester) {
          expect(find.text('0'), findsWidgets);
          expect(
            find.text('+'),
            findsNWidgets(CivilianEconomyCatalog.all.length),
          );
          expect(
            find.text('−'),
            findsNWidgets(CivilianEconomyCatalog.all.length),
          );
        },
      ),
      (
        name: 'Steppers reflect existing train-at-capital civilian build orders',
        game: () => harness.gameWithResources(treasury: 10000, paper: 100),
        orders: () => harness.builderOrders(2),
        expectUi: (tester) => expect(find.text('2'), findsWidgets),
      ),
      (
        name: 'Locked units show 🔒 name prefix and tech requirement',
        game: () => harness.gameWithNoTech(),
        orders: () => const Orders(),
        expectUi: (tester) {
          expect(find.textContaining('\u{1F512}'), findsWidgets);
          expect(find.textContaining('Requires:'), findsNWidgets(2));
        },
      ),
    ];
