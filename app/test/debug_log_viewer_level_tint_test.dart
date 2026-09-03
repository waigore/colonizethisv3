// Debug log viewer level row-tint ACs (Refs #4720 Slice G).
// SPEC/program/debug-log-viewer.md § Visual chrome.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

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
    // Refs #2914 S3 — level row tints resolve through canonical
    // [EditorialMonoclePalette] tokens, not raw Material `Colors.*`.
    // SPEC: `SPEC/program/debug-log-viewer.md` § Visual chrome.
    group('level row tint resolves through EditorialMonoclePalette', () {
      testWidgets('Level.error → EditorialMonoclePalette.danger', (
        WidgetTester tester,
      ) async {
        SessionLogBuffer.instance.add(
          LogEvent(Level.error, 'app: tint_error_token'),
        );
        await pumpDebugLogEditorialMonocleViewer(tester);
        expect(debugLogViewerChipWithLabel(tester, 'error').selected, isTrue);

        expectDebugLogTintMatches(
          debugLogViewerRowTintColorContaining(tester, 'tint_error_token'),
          EditorialMonoclePalette.danger,
          reason: 'Level.error must tint with EditorialMonoclePalette.danger',
        );
      });

      testWidgets('Level.warning → EditorialMonoclePalette.accent', (
        WidgetTester tester,
      ) async {
        SessionLogBuffer.instance.add(
          LogEvent(Level.warning, 'app: tint_warning_token'),
        );
        await pumpDebugLogEditorialMonocleViewer(tester);
        expect(debugLogViewerChipWithLabel(tester, 'warning').selected, isTrue);

        expectDebugLogTintMatches(
          debugLogViewerRowTintColorContaining(tester, 'tint_warning_token'),
          EditorialMonoclePalette.accent,
          reason: 'Level.warning must tint with EditorialMonoclePalette.accent',
        );
      });

      testWidgets('Level.info → EditorialMonoclePalette.accentDim', (
        WidgetTester tester,
      ) async {
        SessionLogBuffer.instance.add(
          LogEvent(Level.info, 'app: tint_info_token'),
        );
        await pumpDebugLogEditorialMonocleViewer(tester);
        expect(debugLogViewerChipWithLabel(tester, 'info').selected, isTrue);

        expectDebugLogTintMatches(
          debugLogViewerRowTintColorContaining(tester, 'tint_info_token'),
          EditorialMonoclePalette.accentDim,
          reason: 'Level.info must tint with EditorialMonoclePalette.accentDim',
        );
      });

      testWidgets(
        'Level.debug → EditorialMonoclePalette.muted (default branch)',
        (WidgetTester tester) async {
          SessionLogBuffer.instance.add(
            LogEvent(Level.debug, 'app: tint_default_token'),
          );
          await pumpDebugLogEditorialMonocleViewer(tester);

          await tester.ensureVisible(find.text('debug'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('debug'));
          await tester.pumpAndSettle();

          expectDebugLogTintMatches(
            debugLogViewerRowTintColorContaining(tester, 'tint_default_token'),
            EditorialMonoclePalette.muted,
            reason:
                'Level.debug (default branch) must tint with '
                'EditorialMonoclePalette.muted',
          );
        },
      );

      testWidgets('level row tints do not use raw Material Colors.* values', (
        WidgetTester tester,
      ) async {
        SessionLogBuffer.instance.add(
          LogEvent(Level.error, 'app: not_raw_material_red'),
        );
        SessionLogBuffer.instance.add(
          LogEvent(Level.warning, 'app: not_raw_material_orange'),
        );
        SessionLogBuffer.instance.add(
          LogEvent(Level.info, 'app: not_raw_material_blue'),
        );
        await pumpDebugLogEditorialMonocleViewer(tester);

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
          final tint = debugLogViewerRowTintColorContaining(tester, pattern);
          expect(tint, isNotNull, reason: 'expected a tinted row for $pattern');
          for (final banned in bannedSamples) {
            final bannedAt08 = banned.withValues(
              alpha: debugLogViewerExpectedRowAlpha,
            );
            final close =
                (tint!.r - bannedAt08.r).abs() < 0.005 &&
                (tint.g - bannedAt08.g).abs() < 0.005 &&
                (tint.b - bannedAt08.b).abs() < 0.005;
            expect(
              close,
              isFalse,
              reason: '$pattern must not tint with raw Material $banned',
            );
          }
        }
      });
    });
  });
}
