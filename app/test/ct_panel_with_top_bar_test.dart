// Tests for CtPanelWithTopBar (issue #3279 §5) — the shared CtPanel +
// Column(stretch) + optional top-bar skeleton extracted from CtScreenShell
// and UnitsPanelShell. SPEC/ui/components/ct-panel-with-top-bar.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_panel_with_top_bar.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CtPanelWithTopBar', () {
    testWidgets(
      'mounts one CtPanel, the supplied CtTopBar, and the children',
      (WidgetTester tester) async {
        await pump(
          tester,
          const CtPanelWithTopBar(
            topBar: CtTopBar(title: 'Roster', showBackButton: false),
            children: <Widget>[Text('Body content')],
          ),
        );

        expect(
          find.descendant(
            of: find.byType(CtPanelWithTopBar),
            matching: find.byType(CtPanel),
          ),
          findsOneWidget,
        );
        final Finder topBar = find.descendant(
          of: find.byType(CtPanelWithTopBar),
          matching: find.byType(CtTopBar),
        );
        expect(topBar, findsOneWidget);
        expect(tester.widget<CtTopBar>(topBar).title, 'Roster');
        expect(find.text('Body content'), findsOneWidget);
      },
    );

    testWidgets(
      'omits the CtTopBar slot entirely when topBar is null',
      (WidgetTester tester) async {
        await pump(
          tester,
          const CtPanelWithTopBar(
            children: <Widget>[Text('Only body')],
          ),
        );

        expect(
          find.descendant(
            of: find.byType(CtPanelWithTopBar),
            matching: find.byType(CtTopBar),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(CtPanelWithTopBar),
            matching: find.byType(CtPanel),
          ),
          findsOneWidget,
        );
        expect(find.text('Only body'), findsOneWidget);
      },
    );

    testWidgets(
      'forwards mainAxisSize: min to the inner Column (stretch cross-axis)',
      (WidgetTester tester) async {
        await pump(
          tester,
          const CtPanelWithTopBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[Text('Body')],
          ),
        );

        // With topBar == null the only Column under the CtPanel is the
        // skeleton's own Column.
        final Column column = tester.widget<Column>(
          find.descendant(
            of: find.byType(CtPanel),
            matching: find.byType(Column),
          ),
        );
        expect(column.mainAxisSize, MainAxisSize.min);
        expect(column.crossAxisAlignment, CrossAxisAlignment.stretch);
      },
    );

    testWidgets(
      'defaults mainAxisSize to max',
      (WidgetTester tester) async {
        await pump(
          tester,
          const CtPanelWithTopBar(
            children: <Widget>[Expanded(child: Text('Body'))],
          ),
        );

        final Column column = tester.widget<Column>(
          find.descendant(
            of: find.byType(CtPanel),
            matching: find.byType(Column),
          ),
        );
        expect(column.mainAxisSize, MainAxisSize.max);
      },
    );
  });
}
