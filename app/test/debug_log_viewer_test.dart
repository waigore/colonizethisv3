// Widget tests for debug log viewer. SPEC/program/debug-log-viewer.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

import 'package:colonizethis_app/features/debug_log/debug_log_viewer_screen.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';

import 'debug_log_viewer_test_support.dart';

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
      await pumpDebugLogLightViewer(tester);

      expect(find.text('Debug log'), findsOneWidget);
      expect(find.byType(CtBackButton), findsOneWidget);
    });

    testWidgets('shows filter chips for package and level', (
      WidgetTester tester,
    ) async {
      await pumpDebugLogLightViewer(tester);

      expect(find.text('logic'), findsOneWidget);
      expect(find.text('debug'), findsOneWidget);
    });

    testWidgets('default package filter is app only and ctdev chip is hidden', (
      WidgetTester tester,
    ) async {
      await pumpDebugLogLightViewer(tester);

      expect(find.text('ctdev'), findsNothing);
      expect(debugLogViewerChipWithLabel(tester, 'app').selected, isTrue);
      expect(debugLogViewerChipWithLabel(tester, 'logic').selected, isFalse);
    });

    testWidgets('default level filter is info warning error without debug', (
      WidgetTester tester,
    ) async {
      await pumpDebugLogLightViewer(tester);

      expect(debugLogViewerChipWithLabel(tester, 'debug').selected, isFalse);
      expect(debugLogViewerChipWithLabel(tester, 'info').selected, isTrue);
      expect(debugLogViewerChipWithLabel(tester, 'warning').selected, isTrue);
      expect(debugLogViewerChipWithLabel(tester, 'error').selected, isTrue);
    });

    testWidgets('selecting debug level shows app debug lines', (
      WidgetTester tester,
    ) async {
      SessionLogBuffer.instance.add(
        LogEvent(Level.debug, 'app: hidden until debug'),
      );
      await pumpDebugLogLightViewer(tester);

      expect(find.textContaining('hidden until debug'), findsNothing);

      await tester.ensureVisible(find.text('debug'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('debug'));
      await tester.pumpAndSettle();

      expect(find.textContaining('hidden until debug'), findsOneWidget);
    });

    testWidgets('close button pops route', (WidgetTester tester) async {
      await pumpDebugLogLightViewer(
        tester,
        child: Builder(
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
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Debug log'), findsOneWidget);
      await tester.tap(find.byType(CtBackButton));
      await tester.pumpAndSettle();

      expect(find.text('Debug log'), findsNothing);
    });

    testWidgets('displays session log entries when present', (
      WidgetTester tester,
    ) async {
      SessionLogBuffer.instance.add(LogEvent(Level.info, 'app: test message'));
      await pumpDebugLogLightViewer(tester);

      expect(find.textContaining('test message'), findsOneWidget);
    });
  });
}
