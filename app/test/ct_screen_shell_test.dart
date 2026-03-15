// Tests for CtScreenShell widget.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_screen_shell.dart';

void main() {
  suppressLogsForTests();

  group('CtScreenShell', () {
    testWidgets('renders title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CtScreenShell(
            title: 'Test Title',
            child: const Text('Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders child content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CtScreenShell(
            title: 'Title',
            child: const Column(children: [Text('Child A'), Text('Child B')]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Child A'), findsOneWidget);
      expect(find.text('Child B'), findsOneWidget);
    });

    testWidgets('does not show back button by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CtScreenShell(title: 'Title', child: const Text('Content')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('shows back button when showBackButton is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CtScreenShell(
            title: 'Title',
            showBackButton: true,
            child: const Text('Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back button pops navigator when tapped', (
      WidgetTester tester,
    ) async {
      var popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            pages: [
              MaterialPage(
                child: CtScreenShell(
                  title: 'Title',
                  showBackButton: true,
                  child: const Text('Content'),
                ),
              ),
            ],
            onPopPage: (route, result) {
              popped = true;
              return false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('back button has correct size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CtScreenShell(
            title: 'Title',
            showBackButton: true,
            child: const Text('Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_back));
      expect(icon.size, equals(20));
    });
  });
}
