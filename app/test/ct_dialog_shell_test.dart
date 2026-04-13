import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';

void main() {
  suppressLogsForTests();

  group('CtDialogShell', () {
    testWidgets('short content: scroll viewport shorter than maxHeight', (
      WidgetTester tester,
    ) async {
      const maxH = 500.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CtDialogShell(
                maxHeight: maxH,
                maxWidth: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 48, child: Text('Short')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollBox = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byType(CtDialogShell),
          matching: find.byType(CustomScrollView),
        ),
      );
      expect(scrollBox.size.height, lessThan(maxH - 32));
    });

    testWidgets('tall content: one outer scroll; drag reveals bottom', (
      WidgetTester tester,
    ) async {
      const maxH = 200.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CtDialogShell(
                maxHeight: maxH,
                maxWidth: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 24; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('block-$i'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('block-0'), findsOneWidget);
      expect(find.text('block-23').hitTestable(), findsNothing);

      final scrollable = find.descendant(
        of: find.byType(CtDialogShell),
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);

      final scrollBox = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byType(CtDialogShell),
          matching: find.byType(CustomScrollView),
        ),
      );
      expect(scrollBox.size.height, lessThanOrEqualTo(maxH + 1));

      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('block-23'), findsOneWidget);
    });
  });
}
