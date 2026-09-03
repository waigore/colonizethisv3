// Pin the 320 dp minimum-viewport contract for the in-app
// `DebugLogViewerScreen` (SYS10001) — populated-buffer path.
// Empty-buffer pins live in
// `debug_log_viewer_320dp_min_viewport_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/program/debug-log-viewer.md` § 4 Entry points + § 5a Visual chrome.
// Refs #2870 S10.

import 'package:colonizethis_app/features/debug_log/debug_log_viewer_screen.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

import 'mobile_320dp_min_viewport_test_support.dart';

void main() {
  suppressLogsForTests();

  setUp(() {
    SessionLogBuffer.resetForTest();
    SessionLogBuffer.init();
  });

  tearDown(() {
    SessionLogBuffer.resetForTest();
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — DebugLogViewerScreen (populated '
      'buffer) @ 320 dp (Refs #2870 S10)', () {
    testWidgets(
      'AC (positive) DebugLogViewerScreen populated buffer @ 320×640: '
      'no RenderFlex overflow exception, seeded `Level.warning` line '
      'renders inside a tinted `Container` so the per-entry row chrome '
      'lays out within the 320 dp column',
      (WidgetTester tester) async {
        // Seed two `Level.warning` lines tagged with the `app` prefix
        // so the default-selected package + level filters surface
        // them in the body. Two entries are enough to exercise the
        // per-entry Container chrome from
        // SPEC/program/debug-log-viewer.md § 5a Visual chrome
        // without producing enough vertical content to require
        // scrolling at the 640 dp test height — the goal is the
        // horizontal overflow contract, not scroll behaviour.
        SessionLogBuffer.instance.add(
          // ignore: avoid_hardcoded_strings_in_widgets
          LogEvent(Level.warning, 'app: narrow-viewport pin first line'),
        );
        SessionLogBuffer.instance.add(
          // ignore: avoid_hardcoded_strings_in_widgets
          LogEvent(Level.warning, 'app: narrow-viewport pin second line'),
        );

        await pumpMobileNarrow(
          tester,
          const DebugLogViewerScreen(),
          size: kMobileMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: DebugLogViewerScreen '
              'with two buffered `Level.warning` lines must not emit '
              'a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). Each entry mounts a per-line `Container` '
              'with an `EditorialMonoclePalette`-tinted '
              '`BoxDecoration` wrapping a `SelectableText` body per '
              'SPEC/program/debug-log-viewer.md § 5a Visual chrome; '
              'the tinted rows must still respect the 320 dp '
              'horizontal budget.',
        );

        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('Debug log'), findsOneWidget);

        // Each seeded warning surfaces under the default-selected
        // filters per SPEC/program/debug-log-viewer.md § 3.
        expect(
          find.textContaining('narrow-viewport pin first line'),
          findsOneWidget,
          reason:
              'The default-selected `app` package + `warning` level '
              'filters must surface the first seeded warning at the '
              'minimum viewport per SPEC/program/debug-log-viewer.md '
              '§ 3 defaults.',
        );
        expect(
          find.textContaining('narrow-viewport pin second line'),
          findsOneWidget,
          reason:
              'The default-selected `app` package + `warning` level '
              'filters must surface the second seeded warning at the '
              'minimum viewport per SPEC/program/debug-log-viewer.md '
              '§ 3 defaults.',
        );
      },
    );

    testWidgets('Negative control: DebugLogViewerScreen populated buffer @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the populated-buffer overflow contract)', (
      WidgetTester tester,
    ) async {
      SessionLogBuffer.instance.add(
        // ignore: avoid_hardcoded_strings_in_widgets
        LogEvent(Level.warning, 'app: wide regression pin line'),
      );

      await pumpMobileNarrow(
        tester,
        const DebugLogViewerScreen(),
        size: kMobileWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      // ignore: avoid_hardcoded_strings_in_widgets
      expect(find.text('Debug log'), findsOneWidget);
      expect(find.textContaining('wide regression pin line'), findsOneWidget);
    });
  });
}
