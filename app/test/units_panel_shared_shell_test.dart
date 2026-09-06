// UnitsPanelShell widget tests split from units_panel_shared_widgets_test (Refs #4734 Slice E).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';

import 'units_panel_shared_widgets_test_support.dart';

void main() {
  suppressLogsForTests();

  group('UnitsPanelShell', () {
    testWidgets('shows title and empty message when no content', (
      WidgetTester tester,
    ) async {
      await pumpUnitsSharedBody(
        tester,
        emptyUnitsPanelShell(title: 'Test Panel', emptyMessage: 'Nothing here'),
      );
      expect(find.text('Test Panel'), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('shows list children when hasContent', (
      WidgetTester tester,
    ) async {
      await pumpUnitsSharedBody(
        tester,
        UnitsPanelShell(
          title: 'With rows',
          hasContent: true,
          listChildren: [
            const ListTile(title: Text('Row one')),
            const ListTile(title: Text('Row two')),
          ],
          emptyMessage: 'ignored',
        ),
      );
      expect(find.text('Row one'), findsOneWidget);
      expect(find.text('Row two'), findsOneWidget);
      expect(find.text('ignored'), findsNothing);
    });

    testWidgets('forwards trailing actions', (WidgetTester tester) async {
      await pumpUnitsSharedBody(
        tester,
        emptyUnitsPanelShell(
          title: 'T',
          emptyMessage: 'E',
          actions: [TextButton(onPressed: () {}, child: const Text('Action'))],
        ),
      );
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets(
      'renders title via CtTopBar (showBackButton: false; #2866 S1 chrome)',
      (WidgetTester tester) async {
        await pumpUnitsSharedBody(tester, emptyUnitsPanelShell());

        final Finder topBarFinder = find.byType(CtTopBar);
        expect(topBarFinder, findsOneWidget);
        final CtTopBar topBar = tester.widget(topBarFinder);
        expect(topBar.title, 'Civilian Units');
        expect(topBar.showBackButton, isFalse);
        expect(topBar.trailing, isNull);
        expect(find.byType(CtBackButton), findsNothing);

        final Finder topBarSizedBoxFinder = find.descendant(
          of: topBarFinder,
          matching: find.byWidgetPredicate(
            (Widget w) => w is SizedBox && w.height == CtTopBar.height,
          ),
        );
        expect(topBarSizedBoxFinder, findsOneWidget);

        final Text titleText = tester.widget(
          find.descendant(
            of: topBarFinder,
            matching: find.text('Civilian Units'),
          ),
        );
        expect(titleText.style?.color, EditorialMonoclePalette.accent);
      },
    );

    testWidgets(
      'wraps multiple trailing actions in a Row inside CtTopBar trailing slot',
      (WidgetTester tester) async {
        await pumpUnitsSharedBody(
          tester,
          emptyUnitsPanelShell(
            actions: [
              TextButton(onPressed: () {}, child: const Text('Tile')),
              TextButton(onPressed: () {}, child: const Text('Train')),
            ],
          ),
        );

        final CtTopBar topBar = tester.widget(find.byType(CtTopBar));
        expect(topBar.trailing, isA<Row>());
        final Row trailingRow = topBar.trailing! as Row;
        expect(trailingRow.mainAxisSize, MainAxisSize.min);
        expect(trailingRow.children.length, 3);
        final Widget spacer = trailingRow.children[1];
        expect(spacer, isA<SizedBox>());
        expect((spacer as SizedBox).width, isNonZero);
        expect(find.text('Tile'), findsOneWidget);
        expect(find.text('Train'), findsOneWidget);
      },
    );

    testWidgets(
      'passes a single trailing action through unchanged (no Row wrapper)',
      (WidgetTester tester) async {
        final TextButton soloAction = TextButton(
          onPressed: () {},
          child: const Text('Train'),
        );
        await pumpUnitsSharedBody(
          tester,
          emptyUnitsPanelShell(actions: [soloAction], emptyMessage: 'E'),
        );

        final CtTopBar topBar = tester.widget(find.byType(CtTopBar));
        expect(topBar.trailing, same(soloAction));
      },
    );

    testWidgets(
      'renders empty message in italic --muted (#2866 S1 dark-theme palette)',
      (WidgetTester tester) async {
        await pumpUnitsSharedBody(tester, emptyUnitsPanelShell());

        final Text emptyText = tester.widget(find.text('No civilian units'));
        expect(emptyText.style?.color, EditorialMonoclePalette.muted);
        expect(emptyText.style?.fontStyle, FontStyle.italic);
      },
    );

    testWidgets('omits the empty message when hasContent is true', (
      WidgetTester tester,
    ) async {
      await pumpUnitsSharedBody(
        tester,
        const UnitsPanelShell(
          title: 'Civilian Units',
          hasContent: true,
          listChildren: [ListTile(title: Text('Row one'))],
          emptyMessage: 'No civilian units',
        ),
      );

      expect(find.text('Row one'), findsOneWidget);
      expect(find.text('No civilian units'), findsNothing);
    });
  });
}
