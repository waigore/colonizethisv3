// Tests for TrainCiviliansDialog. SPEC/ui/train-civilians-dialog.md.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'train_civilians_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  late TrainCiviliansDialogTestHarness harness;

  setUpAll(() {
    harness = TrainCiviliansDialogTestHarness();
  });

  group('TrainCiviliansDialog', () {
    // Table-registered chrome pins (isolated testWidgets per case — Refs #4021).
    for (final case_
        in <
          ({
            String name,
            Game Function() game,
            Orders Function() orders,
            void Function(WidgetTester tester) expectUi,
          })
        >[
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
            name:
                'Unlocked cost line reads "£1,000 + 2 paper" (lowercase paper)',
            game: () => harness.gameWithResources(treasury: 10000, paper: 100),
            orders: () => const Orders(),
            expectUi: (tester) =>
                expect(find.textContaining('£1,000 + 2 paper'), findsWidgets),
          ),
          (
            name:
                'Both-resource deficit reads "Treasury low, Paper low" (comma-join)',
            game: () => harness.gameWithCapital(treasury: 1500, paper: 3),
            orders: () => harness.builderOrders(2),
            expectUi: (tester) {
              expect(find.text('Treasury low, Paper low'), findsOneWidget);
              // Comma-join only — not "Treasury low and Paper low".
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
            name:
                'Steppers reflect existing train-at-capital civilian build orders',
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
        ]) {
      testWidgets('AC: ${case_.name}', (WidgetTester tester) async {
        await harness.pumpDialog(
          tester,
          panelGame: case_.game(),
          currentOrders: case_.orders(),
        );
        case_.expectUi(tester);
      });
    }

    testWidgets('AC: stepper interactions', (WidgetTester tester) async {
      final rich = harness.gameWithResources(treasury: 10000, paper: 100);
      await harness.pumpDialog(tester, panelGame: rich);
      await harness.tapStepper(tester, '+');
      expect(find.text('1'), findsWidgets);
      await harness.tapStepper(tester, '−');
      expect(find.text('1'), findsNothing);

      await harness.pumpDialog(tester, panelGame: harness.game);
      await harness.tapStepper(tester, '−');
      expect(find.text('0'), findsWidgets);

      // Builder costs 1000 treasury + 2 paper; 1500 treasury allows 1 not 2.
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithResources(treasury: 1500, paper: 10),
      );
      final builderIndex = CivilianEconomyCatalog.all.indexWhere(
        (e) => e.id == kUnitTypeBuilder,
      );
      await harness.tapStepper(tester, '+', index: builderIndex);
      expect(find.text('1'), findsWidgets);
      await harness.tapStepper(tester, '+', index: builderIndex);
      expect(find.text('1'), findsWidgets);

      await harness.pumpDialog(tester, panelGame: harness.gameWithNoTech());
      final merchantIndex = CivilianEconomyCatalog.all.indexWhere(
        (e) => e.id == kUnitTypeMerchant,
      );
      await harness.tapStepper(tester, '+', index: merchantIndex);
      expect(find.text('0'), findsWidgets);

      await harness.pumpDialog(tester, panelGame: rich);
      await harness.tapStepper(tester, '+');
      await harness.tapStepper(tester, '+', index: 1);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsNothing);
    });

    testWidgets(
      'AC: Closing dialog emits TrainCivilianBuildOrdersCommittedEvent with correct orders',
      (WidgetTester tester) async {
        List<BuildUnitOrder>? capturedOrders;
        final bus = AppEventBus.create();
        final sub = bus.on<TrainCivilianBuildOrdersCommittedEvent>().listen((
          e,
        ) {
          capturedOrders = e.orders;
        });
        addTearDown(sub.cancel);

        final richGame = harness.gameWithResources(treasury: 10000, paper: 100);

        await tester.pumpWidget(
          buildAppShell(
            child: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: ctx,
                      builder: (dialogCtx) => TrainCiviliansDialog(
                        game: richGame,
                        humanPlayerId: harness.humanPlayerId,
                        currentOrders: const Orders(),
                        bus: bus,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await harness.tapStepper(tester, '+');
        await harness.tapStepper(tester, '+');
        expect(find.text('2'), findsWidgets);

        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));

        expect(capturedOrders, isNotNull);
        expect(capturedOrders!.length, 2);
        expect(capturedOrders![0].unitType, kUnitTypeBuilder);
        expect(capturedOrders![0].isMilitary, false);
        expect(capturedOrders![1].unitType, kUnitTypeBuilder);
      },
    );

    testWidgets('AC: Train button visible in CivilianUnitsPanel header', (
      WidgetTester tester,
    ) async {
      await harness.pumpCivilianPanel(tester);
      expect(find.text('Train'), findsOneWidget);
    });

    testWidgets(
      'AC: Train button opens TrainCiviliansDialog via app event bus',
      (WidgetTester tester) async {
        await harness.pumpCivilianPanel(tester);
        await tester.tap(find.text('Train'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(TrainCiviliansDialog), findsOneWidget);
        expect(find.text('Train Civilians'), findsOneWidget);
      },
    );
  });
}
