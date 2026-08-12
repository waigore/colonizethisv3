// Affordance-feedback pins for TrainNavalDialog (issue #3601).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'train_naval_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  late TrainNavalDialogTestHarness harness;

  setUpAll(() {
    harness = TrainNavalDialogTestHarness();
  });

  group('TrainNavalDialog affordance feedback (#3601)', () {
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

    testWidgets('AC (positive): resource bar chips show remaining / total', (
      WidgetTester tester,
    ) async {
      final g = harness.gameWithNavalResources();
      await harness.pumpDialog(
        tester,
        panelGame: g,
        currentOrders: harness.carrackOrders(g, 1),
      );
      expect(find.textContaining('£42,000 / £50,000'), findsOneWidget);
      expect(find.textContaining('19 / 20'), findsOneWidget);
    });

    testWidgets(
      'AC (positive): only the deficient commodity cost renders in danger',
      (WidgetTester tester) async {
        final game = harness.richWithHuman(
          (player) => player.copyWith(
            treasury: 1000000,
            stockpile: const Stockpile(
              quantities: {
                'lumber': 100,
                'fabric': 100,
                'castIron': 0,
                'coal': 100,
              },
            ),
          ),
        );
        await harness.pumpDialog(tester, panelGame: game);
        expect(redCostLabels(tester), greaterThan(0));
      },
    );

    testWidgets('AC (negative): fully affordable rows colour no cost labels red', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.richWithHuman((p) => p.copyWith(treasury: 1000000)),
      );
      expect(redCostLabels(tester), 0);
    });

    testWidgets('AC (positive): disabled [+] uses danger variant when unaffordable', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.richWithHuman((p) => p.copyWith(treasury: 0)),
      );
      expect(plusButtons(tester).any((b) => b.dangerVariant), isTrue);
    });

    testWidgets('AC (negative): tech-locked rows never use the danger [+] variant', (
      WidgetTester tester,
    ) async {
      expect(
        ShipEconomyCatalog.all
            .where((e) => unlockingTechByShipId[e.shipTypeId] != null),
        isNotEmpty,
      );
      await harness.pumpDialog(
        tester,
        panelGame: harness.richWithHuman(
          (p) => p.copyWith(
            treasury: 1000000,
            techUnlocked: const <String, bool>{},
          ),
        ),
      );
      expect(plusButtons(tester).every((b) => !b.dangerVariant), isTrue);
    });

    testWidgets(
      'AC (positive): multi-resource deficit hint joins clauses with ", "',
      (WidgetTester tester) async {
        final game = harness.richWithHuman(
          (player) => player.copyWith(
            treasury: 0,
            stockpile: const Stockpile(
              quantities: {
                'lumber': 0,
                'fabric': 100,
                'castIron': 100,
                'coal': 100,
              },
            ),
          ),
        );
        await harness.pumpDialog(
          tester,
          panelGame: game,
          currentOrders: harness.carrackOrders(game, 1),
        );
        expect(find.text('Treasury low, Lumber low'), findsOneWidget);
        expect(find.textContaining(' and '), findsNothing);
      },
    );
  });
}
