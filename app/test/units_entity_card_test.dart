// Widget tests for the shared UnitsEntityCard chrome (issue #3514 AC-6).
// SPEC/ui/components/units-entity-card.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_card.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpCard(
    WidgetTester tester, {
    bool initiallyExpanded = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: UnitsEntityCard(
              title: const Text('Army A'),
              subtitle: const Text('2 regiments'),
              initiallyExpanded: initiallyExpanded,
              children: const [Text('Child detail')],
            ),
          ),
        ),
      ),
    );
  }

  // Outermost DecoratedBox descendant of the card is the chrome surface; when
  // expanded a second (child top-divider) DecoratedBox appears deeper in the
  // tree, so the depth-first `.first` match stays the card chrome.
  BoxDecoration cardDecoration(WidgetTester tester) {
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(UnitsEntityCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  group('UnitsEntityCard', () {
    testWidgets(
      'collapsed card paints the bg-deep->surface gradient with a 1 px '
      'border outline and no flat fill (#3514 AC-6)',
      (WidgetTester tester) async {
        await pumpCard(tester);

        final BoxDecoration deco = cardDecoration(tester);
        expect(deco.gradient, UnitsEntityCard.collapsedGradient);
        expect(deco.color, isNull);
        final Border border = deco.border! as Border;
        expect(border.top.color, EditorialMonoclePalette.border);
        expect(border.top.width, 1);
      },
    );

    testWidgets(
      'inner ExpansionTile is transparent so only the card chrome shows '
      '(#3514 AC-6)',
      (WidgetTester tester) async {
        await pumpCard(tester);

        final ExpansionTile tile = tester.widget<ExpansionTile>(
          find.byType(ExpansionTile),
        );
        expect(tile.backgroundColor, Colors.transparent);
        expect(tile.collapsedBackgroundColor, Colors.transparent);
      },
    );

    testWidgets(
      'retains the ExpansionTile RotationTransition expand affordance for '
      'e2e helpers (#3514 AC-6)',
      (WidgetTester tester) async {
        await pumpCard(tester);

        expect(
          find.descendant(
            of: find.byType(ExpansionTile),
            matching: find.byType(RotationTransition),
          ),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'expanded card switches to a flat surface fill with an accent-dim '
      'outline and reveals its children (#3514 AC-6)',
      (WidgetTester tester) async {
        await pumpCard(tester, initiallyExpanded: true);

        final BoxDecoration deco = cardDecoration(tester);
        expect(deco.gradient, isNull);
        expect(deco.color, EditorialMonoclePalette.surface);
        final Border border = deco.border! as Border;
        expect(border.top.color, EditorialMonoclePalette.accentDim);
        expect(border.top.width, 1);

        expect(find.text('Child detail'), findsOneWidget);
      },
    );

    testWidgets(
      'expanded children sit under a 1 px border top divider (#3514 AC-6)',
      (WidgetTester tester) async {
        await pumpCard(tester, initiallyExpanded: true);

        final Finder dividerFinder = find.descendant(
          of: find.byType(UnitsEntityCard),
          matching: find.byWidgetPredicate((Widget w) {
            if (w is! DecoratedBox) return false;
            final BoxDecoration? d = w.decoration as BoxDecoration?;
            final Border? b = d?.border as Border?;
            return b != null &&
                b.top.color == EditorialMonoclePalette.border &&
                b.bottom == BorderSide.none &&
                b.left == BorderSide.none;
          }),
        );
        expect(dividerFinder, findsOneWidget);
      },
    );

    testWidgets(
      'tapping a collapsed card expands it to the expanded chrome (#3514 AC-6)',
      (WidgetTester tester) async {
        await pumpCard(tester);

        // Collapsed: child not yet mounted.
        expect(find.text('Child detail'), findsNothing);

        await tester.tap(find.text('Army A'));
        await tester.pumpAndSettle();

        expect(find.text('Child detail'), findsOneWidget);
        final BoxDecoration deco = cardDecoration(tester);
        expect(deco.color, EditorialMonoclePalette.surface);
        expect((deco.border! as Border).top.color,
            EditorialMonoclePalette.accentDim);
      },
    );
  });
}
