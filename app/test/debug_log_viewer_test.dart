// Widget tests for debug log viewer. SPEC/program/debug-log-viewer.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/debug_log/debug_log_viewer_screen.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';

import 'support/app_shell_harness.dart';

CtChoiceChip _chipWithLabel(WidgetTester tester, String label) {
  return tester.widget<CtChoiceChip>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(CtChoiceChip),
    ),
  );
}

/// Returns the resolved row-tint Color for the first line of the matching
/// log entry, or `null` when no tinted container is found. The viewer wraps
/// each line in a `Container` and only the first line of each entry receives
/// a `BoxDecoration` with the level row tint.
Color? _rowTintColorContaining(WidgetTester tester, String pattern) {
  final containerFinder = find.ancestor(
    of: find.textContaining(pattern),
    matching: find.byType(Container),
  );
  for (final element in containerFinder.evaluate()) {
    final container = element.widget as Container;
    final decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration.color;
    }
  }
  return null;
}

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
      expect(find.byType(CtBackButton), findsOneWidget);
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

    testWidgets('default package filter is app only and ctdev chip is hidden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.light,
          home: const DebugLogViewerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ctdev'), findsNothing);
      expect(_chipWithLabel(tester, 'app').selected, isTrue);
      expect(_chipWithLabel(tester, 'logic').selected, isFalse);
    });

    testWidgets('default level filter is info warning error without debug', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.light,
          home: const DebugLogViewerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(_chipWithLabel(tester, 'debug').selected, isFalse);
      expect(_chipWithLabel(tester, 'info').selected, isTrue);
      expect(_chipWithLabel(tester, 'warning').selected, isTrue);
      expect(_chipWithLabel(tester, 'error').selected, isTrue);
    });

    testWidgets('selecting debug level shows app debug lines', (WidgetTester tester) async {
      SessionLogBuffer.instance.add(LogEvent(Level.debug, 'app: hidden until debug'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.light,
          home: const DebugLogViewerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('hidden until debug'), findsNothing);

      await tester.ensureVisible(find.text('debug'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('debug'));
      await tester.pumpAndSettle();

      expect(find.textContaining('hidden until debug'), findsOneWidget);
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
      await tester.tap(find.byType(CtBackButton));
      await tester.pumpAndSettle();

      expect(find.text('Debug log'), findsNothing);
    });

    testWidgets('displays session log entries when present', (WidgetTester tester) async {
      SessionLogBuffer.instance.add(LogEvent(Level.info, 'app: test message'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.light,
          home: const DebugLogViewerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('test message'), findsOneWidget);
    });

    // Refs #2914 S3 — level row tints resolve through canonical
    // [EditorialMonoclePalette] tokens, not raw Material `Colors.*`.
    // SPEC: `SPEC/program/debug-log-viewer.md` § Visual chrome.
    group('level row tint resolves through EditorialMonoclePalette', () {
      testWidgets(
        'Level.error → EditorialMonoclePalette.danger',
        (WidgetTester tester) async {
          SessionLogBuffer.instance.add(
            LogEvent(Level.error, 'app: tint_error_token'),
          );
          await _pumpEditorialMonocleViewer(tester);
          expect(_chipWithLabel(tester, 'error').selected, isTrue);

          _expectTintMatches(
            _rowTintColorContaining(tester, 'tint_error_token'),
            EditorialMonoclePalette.danger,
            reason: 'Level.error must tint with EditorialMonoclePalette.danger',
          );
        },
      );

      testWidgets(
        'Level.warning → EditorialMonoclePalette.accent',
        (WidgetTester tester) async {
          SessionLogBuffer.instance.add(
            LogEvent(Level.warning, 'app: tint_warning_token'),
          );
          await _pumpEditorialMonocleViewer(tester);
          expect(_chipWithLabel(tester, 'warning').selected, isTrue);

          _expectTintMatches(
            _rowTintColorContaining(tester, 'tint_warning_token'),
            EditorialMonoclePalette.accent,
            reason:
                'Level.warning must tint with EditorialMonoclePalette.accent',
          );
        },
      );

      testWidgets(
        'Level.info → EditorialMonoclePalette.accentDim',
        (WidgetTester tester) async {
          SessionLogBuffer.instance.add(
            LogEvent(Level.info, 'app: tint_info_token'),
          );
          await _pumpEditorialMonocleViewer(tester);
          expect(_chipWithLabel(tester, 'info').selected, isTrue);

          _expectTintMatches(
            _rowTintColorContaining(tester, 'tint_info_token'),
            EditorialMonoclePalette.accentDim,
            reason:
                'Level.info must tint with EditorialMonoclePalette.accentDim',
          );
        },
      );

      testWidgets(
        'Level.debug → EditorialMonoclePalette.muted (default branch)',
        (WidgetTester tester) async {
          SessionLogBuffer.instance.add(
            LogEvent(Level.debug, 'app: tint_default_token'),
          );
          await _pumpEditorialMonocleViewer(tester);

          await tester.ensureVisible(find.text('debug'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('debug'));
          await tester.pumpAndSettle();

          _expectTintMatches(
            _rowTintColorContaining(tester, 'tint_default_token'),
            EditorialMonoclePalette.muted,
            reason: 'Level.debug (default branch) must tint with '
                'EditorialMonoclePalette.muted',
          );
        },
      );

      testWidgets(
        'level row tints do not use raw Material Colors.* values',
        (WidgetTester tester) async {
          SessionLogBuffer.instance.add(
            LogEvent(Level.error, 'app: not_raw_material_red'),
          );
          SessionLogBuffer.instance.add(
            LogEvent(Level.warning, 'app: not_raw_material_orange'),
          );
          SessionLogBuffer.instance.add(
            LogEvent(Level.info, 'app: not_raw_material_blue'),
          );
          await _pumpEditorialMonocleViewer(tester);

          const bannedSamples = <Color>[
            Colors.red,
            Colors.orange,
            Colors.blue,
            Colors.grey,
          ];
          for (final pattern in <String>[
            'not_raw_material_red',
            'not_raw_material_orange',
            'not_raw_material_blue',
          ]) {
            final tint = _rowTintColorContaining(tester, pattern);
            expect(
              tint,
              isNotNull,
              reason: 'expected a tinted row for $pattern',
            );
            for (final banned in bannedSamples) {
              final bannedAt08 = banned.withValues(alpha: _expectedRowAlpha);
              final close = (tint!.r - bannedAt08.r).abs() < 0.005 &&
                  (tint.g - bannedAt08.g).abs() < 0.005 &&
                  (tint.b - bannedAt08.b).abs() < 0.005;
              expect(
                close,
                isFalse,
                reason: '$pattern must not tint with raw Material $banned',
              );
            }
          }
        },
      );
    });
  });
}

const double _expectedRowAlpha = 0.08;

Future<void> _pumpEditorialMonocleViewer(WidgetTester tester) async {
  await pumpAppShell(
    tester,
    settle: true,
    child: const DebugLogViewerScreen(),
  );
}

void _expectTintMatches(
  Color? actual,
  Color base, {
  required String reason,
}) {
  expect(actual, isNotNull, reason: reason);
  final expected = base.withValues(alpha: _expectedRowAlpha);
  expect(actual!.r, closeTo(expected.r, 0.01), reason: '$reason (r)');
  expect(actual.g, closeTo(expected.g, 0.01), reason: '$reason (g)');
  expect(actual.b, closeTo(expected.b, 0.01), reason: '$reason (b)');
  expect(
    actual.a,
    closeTo(_expectedRowAlpha, 0.005),
    reason: '$reason (a)',
  );
}
