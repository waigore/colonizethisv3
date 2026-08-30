import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'train_military_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  final harness = TrainMilitaryDialogTestHarness(
    handlerHiveDir: './.dart_tool/test_hive_train_military_dialog_affordance',
  );

  setUpAll(() async {
    await harness.ensureHandlerHive();
  });

  tearDownAll(() async {
    await harness.closeHandlerHive();
  });

  group('TrainMilitaryDialog affordance feedback (#3601)', () {
    int redCostLabels(WidgetTester tester) {
      final digits = RegExp(r'^\d+$');
      return tester.widgetList<Text>(find.byType(Text)).where((t) {
        final data = t.data;
        if (data == null || !digits.hasMatch(data)) return false;
        return t.style?.color == EditorialMonoclePalette.danger;
      }).length;
    }

    Iterable<CtNinePatchButton> plusButtons(WidgetTester tester) {
      return tester.widgetList<CtNinePatchButton>(
        find.byWidgetPredicate(
          (w) =>
              w is CtNinePatchButton &&
              w.child is Text &&
              (w.child as Text).data == '+',
        ),
      );
    }

    Orders peasantLevyOrders(int count) {
      final player = harness.player(harness.humanPlayerId);
      final capital =
          (player.capitalProvinceId ?? player.capitalTile?.provinceId)!;
      return Orders(
        buildUnitOrdersByPlayerId: {
          harness.humanPlayerId: [
            for (var i = 0; i < count; i++)
              BuildUnitOrder(
                unitType: RegimentEconomyCatalog.peasantLevies.id,
                isMilitary: true,
                spawnProvinceId: capital,
              ),
          ],
        },
      );
    }

    testWidgets('AC (positive): resource bar chips show remaining / total', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        harness.buildDialog(
          panelGame: harness.gameWithMilitaryResources(),
          currentOrders: peasantLevyOrders(1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('£8,000 / £10,000'), findsOneWidget);
      expect(find.textContaining('19 / 20'), findsOneWidget);
    });

    testWidgets(
      'AC (positive): only the deficient commodity cost renders in danger',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(
              treasury: 1000000,
              stockpile: const Stockpile(
                quantities: {
                  'fabric': 100,
                  'castIron': 0,
                  'lumber': 100,
                  'horses': 100,
                  'steel': 100,
                  'bronze': 100,
                },
              ),
            ),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );
        await tester.pumpWidget(harness.buildDialog(panelGame: game));
        await tester.pumpAndSettle();

        expect(redCostLabels(tester), greaterThan(0));
      },
    );

    testWidgets(
      'AC (negative): fully affordable rows colour no cost labels red',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(treasury: 1000000),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );
        await tester.pumpWidget(harness.buildDialog(panelGame: game));
        await tester.pumpAndSettle();

        expect(redCostLabels(tester), 0);
      },
    );

    testWidgets(
      'AC (positive): disabled [+] uses danger variant when unaffordable',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(treasury: 0),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );
        await tester.pumpWidget(harness.buildDialog(panelGame: game));
        await tester.pumpAndSettle();

        expect(plusButtons(tester).any((b) => b.dangerVariant), isTrue);
      },
    );

    testWidgets(
      'AC (negative): affordable rows never use the danger [+] variant',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(treasury: 1000000),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );
        await tester.pumpWidget(harness.buildDialog(panelGame: game));
        await tester.pumpAndSettle();

        expect(plusButtons(tester).every((b) => !b.dangerVariant), isTrue);
      },
    );

    testWidgets(
      'AC (positive): multi-resource deficit hint joins clauses with ", "',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(
              treasury: 0,
              workerPool: player.workerPool.copyWith(peasants: 0),
            ),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );

        await tester.pumpWidget(
          harness.buildDialog(
            panelGame: game,
            currentOrders: peasantLevyOrders(1),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Treasury low, Peasants low'), findsOneWidget);
        expect(find.textContaining(' and '), findsNothing);
      },
    );

    testWidgets(
      'AC (negative): single-resource deficit shows one "{Name} low" clause',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(treasury: 0),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );

        await tester.pumpWidget(
          harness.buildDialog(
            panelGame: game,
            currentOrders: peasantLevyOrders(1),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Treasury low'), findsOneWidget);
        expect(find.textContaining('low,'), findsNothing);
        expect(find.textContaining('Peasants low'), findsNothing);
      },
    );
  });
}
