// Affordance-feedback pins for TrainCiviliansDialog (issue #3601).
// SPEC/ui/train-civilians-dialog.md.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'train_civilians_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  late TrainCiviliansDialogTestHarness harness;

  setUpAll(() {
    harness = TrainCiviliansDialogTestHarness();
  });

  group('TrainCiviliansDialog affordance feedback (#3601)', () {
    List<InlineSpan> costLineSpans(WidgetTester tester, String plainText) {
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (t) => t.textSpan?.toPlainText() == plainText,
            orElse: () => throw StateError('cost line "$plainText" not found'),
          );
      return (text.textSpan! as TextSpan).children!;
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

    testWidgets('AC: resource bar remaining/total and Reset restore', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithCapital(treasury: 5000, paper: 12),
        currentOrders: harness.builderOrders(2),
      );
      expect(find.textContaining('£3,000 / £5,000'), findsOneWidget);
      expect(find.textContaining('8 / 12'), findsOneWidget);

      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.textContaining('£5,000 / £5,000'), findsOneWidget);
      expect(find.textContaining('12 / 12'), findsOneWidget);
    });

    testWidgets('AC: cost-line danger segments follow affordability', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithCapital(treasury: 1500, paper: 5),
        currentOrders: harness.builderOrders(1),
      );
      final deficient = costLineSpans(tester, '£1,000 + 2 paper');
      expect(
        (deficient.first as TextSpan).style?.color,
        EditorialMonoclePalette.danger,
      );
      expect(
        (deficient.last as TextSpan).style?.color,
        isNot(EditorialMonoclePalette.danger),
      );

      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithCapital(treasury: 10000, paper: 100),
      );
      for (final span in costLineSpans(tester, '£1,000 + 2 paper')) {
        expect(
          (span as TextSpan).style?.color,
          isNot(EditorialMonoclePalette.danger),
        );
      }
    });

    testWidgets('AC: [+] danger variant tracks unaffordable vs locked rows', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithCapital(treasury: 1500, paper: 5),
        currentOrders: harness.builderOrders(1),
      );
      expect(plusButtons(tester).any((b) => b.dangerVariant), isTrue);

      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithCapital(treasury: 100000, paper: 1000),
      );
      expect(plusButtons(tester).every((b) => !b.dangerVariant), isTrue);

      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithNoTech(treasury: 0),
      );
      final lockedCount = CivilianEconomyCatalog.all
          .where((e) => unlockingTechByCivilianId[e.id] != null)
          .length;
      expect(lockedCount, greaterThan(0));
      expect(
        plusButtons(tester).where((b) => b.dangerVariant).length,
        CivilianEconomyCatalog.all.length - lockedCount,
      );
    });

    testWidgets('AC: role gist visible unlocked and locked without raw ids', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithCapital(treasury: 10000, paper: 100),
      );
      expect(
        find.text('Explores provinces · Prospects minerals'),
        findsOneWidget,
      );
      expect(find.text('Improves tiles · Upgrades towns'), findsOneWidget);
      expect(find.text('Builds roads, ports, and forts'), findsOneWidget);
      expect(
        find.text('Holds foreign intel · Counter-espionage at home'),
        findsOneWidget,
      );
      expect(find.textContaining('build_improvement'), findsNothing);
      expect(find.textContaining('counter_spy'), findsNothing);

      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithNoTech(treasury: 10000),
      );
      expect(
        find.text('Purchases land in Minor/Tribe provinces'),
        findsOneWidget,
      );
      expect(find.text('Upgrades roads to railroad'), findsOneWidget);
      expect(find.textContaining('Requires:'), findsWidgets);
    });
  });
}
