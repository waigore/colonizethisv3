// Widget tests for debug log viewer. SPEC/program/debug-log-viewer.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/debug_log/debug_log_viewer_screen.dart';

void main() {
  suppressLogsForTests();

  setUp(() {
    SessionLogBuffer.resetForTest();
    SessionLogBuffer.init();
  });

  tearDown(() {
    SessionLogBuffer.resetForTest();
  });

  group('DebugLogViewerScreen', () {
    testWidgets('shows title and close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.light,
          home: const DebugLogViewerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Debug log'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows filter chips for package and level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.light,
          home: const DebugLogViewerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('logic'), findsOneWidget);
      expect(find.text('debug'), findsOneWidget);
    });

    testWidgets('close button pops route', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.light,
          home: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const DebugLogViewerScreen(),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Debug log'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Debug log'), findsNothing);
    });

    testWidgets('displays session log entries when present', (WidgetTester tester) async {
      SessionLogBuffer.instance.add(LogEvent(Level.info, 'logic: test message'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.light,
          home: const DebugLogViewerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('test message'), findsOneWidget);
    });
  });
}
