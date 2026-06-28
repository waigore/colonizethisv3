// Tests for CtDarkScaffold (issue #3279 §6) — the reusable dark-chrome
// screen wrapper promoted from the private _DarkChromeShell in
// CtGameFeatureScreenShell. SPEC/ui/components/ct-dark-scaffold.md.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_dark_scaffold.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CtDarkScaffold', () {
    testWidgets(
      'defaults background to colorScheme.surface and mounts topBar + body',
      (WidgetTester tester) async {
        await pump(
          tester,
          const CtDarkScaffold(
            topBar: Text('Top bar'),
            body: Text('Body'),
          ),
        );

        final Scaffold scaffold = tester.widget<Scaffold>(
          find.descendant(
            of: find.byType(CtDarkScaffold),
            matching: find.byType(Scaffold),
          ),
        );
        expect(
          scaffold.backgroundColor,
          AppThemes.editorialMonocle.colorScheme.surface,
        );
        expect(find.text('Top bar'), findsOneWidget);
        expect(find.text('Body'), findsOneWidget);
      },
    );

    testWidgets(
      'uses the explicit backgroundColor when provided',
      (WidgetTester tester) async {
        await pump(
          tester,
          CtDarkScaffold(
            backgroundColor: EditorialMonoclePalette.bg,
            topBar: const Text('Top bar'),
            body: const Text('Body'),
          ),
        );

        final Scaffold scaffold = tester.widget<Scaffold>(
          find.descendant(
            of: find.byType(CtDarkScaffold),
            matching: find.byType(Scaffold),
          ),
        );
        expect(scaffold.backgroundColor, EditorialMonoclePalette.bg);
      },
    );

    testWidgets(
      'renders the body inside an Expanded that descends from a SafeArea',
      (WidgetTester tester) async {
        await pump(
          tester,
          const CtDarkScaffold(
            topBar: Text('Top bar'),
            body: Text('Body'),
          ),
        );

        final Finder safeArea = find.descendant(
          of: find.byType(CtDarkScaffold),
          matching: find.byType(SafeArea),
        );
        expect(safeArea, findsOneWidget);
        final Finder expanded = find.descendant(
          of: safeArea,
          matching: find.byType(Expanded),
        );
        expect(expanded, findsOneWidget);
        expect(
          find.descendant(of: expanded, matching: find.text('Body')),
          findsOneWidget,
        );
      },
    );
  });
}
