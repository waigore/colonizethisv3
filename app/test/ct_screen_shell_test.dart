// Tests for CtScreenShell widget. Refs #2859 R4 / S5 — top chrome migrated
// to CtTopBar (36 px gradient + 1 px --accent-dim bottom border, leading
// CtBackButton chevron) so the dark editorial-monocle theme participates
// through a single shared primitive. The legacy Material AppBar / arrow_back
// chrome is gone; tests assert against the new contract.

import 'dart:async';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpShell(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CtScreenShell', () {
    testWidgets('renders title correctly', (WidgetTester tester) async {
      await pumpShell(
        tester,
        CtScreenShell(
          title: 'Test Title',
          child: const Text('Content'),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders child content', (WidgetTester tester) async {
      await pumpShell(
        tester,
        CtScreenShell(
          title: 'Title',
          child: const Column(children: [Text('Child A'), Text('Child B')]),
        ),
      );

      expect(find.text('Child A'), findsOneWidget);
      expect(find.text('Child B'), findsOneWidget);
    });

    testWidgets('embeds CtTopBar so the 36 px top chrome is shared (R4 / S5)', (
      WidgetTester tester,
    ) async {
      await pumpShell(
        tester,
        CtScreenShell(title: 'Title', child: const Text('Content')),
      );

      expect(
        find.descendant(
          of: find.byType(CtScreenShell),
          matching: find.byType(CtTopBar),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'does not embed a CtBackButton when showBackButton is false (default)',
      (WidgetTester tester) async {
        await pumpShell(
          tester,
          CtScreenShell(title: 'Title', child: const Text('Content')),
        );

        expect(
          find.descendant(
            of: find.byType(CtScreenShell),
            matching: find.byType(CtBackButton),
          ),
          findsNothing,
        );
        // Legacy AppBar chevron — confirm the regression-trigger icon is also
        // gone so older finders fail loudly rather than silently passing.
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      },
    );

    testWidgets(
      'embeds a CtBackButton (chevron-left) when showBackButton is true',
      (WidgetTester tester) async {
        await pumpShell(
          tester,
          CtScreenShell(
            title: 'Title',
            showBackButton: true,
            child: const Text('Content'),
          ),
        );

        expect(
          find.descendant(
            of: find.byType(CtScreenShell),
            matching: find.byType(CtBackButton),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(CtBackButton),
            matching: find.byIcon(Icons.chevron_left),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'back button pops navigator when tapped (pushed route variant)',
      (WidgetTester tester) async {
        final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.editorialMonocle,
            navigatorKey: navKey,
            home: const Text('Home'),
          ),
        );
        await tester.pumpAndSettle();

        unawaited(
          navKey.currentState!.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => CtScreenShell(
                title: 'Title',
                showBackButton: true,
                child: const Text('Content'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Content'), findsOneWidget);

        await tester.tap(find.byType(CtBackButton));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Content'), findsNothing);
      },
    );

    testWidgets(
      'embedded CtTopBar renders at the 36 px contract height',
      (WidgetTester tester) async {
        await pumpShell(
          tester,
          CtScreenShell(
            title: 'Title',
            showBackButton: true,
            child: const Text('Content'),
          ),
        );

        final SizedBox heightBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(CtScreenShell),
                matching: find.byKey(
                  const ValueKey<String>('ctTopBarHeightBox'),
                ),
              )
              .first,
        );
        expect(heightBox.height, CtTopBar.height);
        expect(CtTopBar.height, 36);
      },
    );
  });
}
