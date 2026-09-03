// Pin the 320 dp minimum-viewport contract for the in-app
// `DebugLogViewerScreen` (SYS10001) — empty-buffer path.
// Populated-buffer pins live in
// `debug_log_viewer_320dp_min_viewport_populated_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/program/debug-log-viewer.md` § 4 Entry points + § 5a Visual chrome.
// Refs #2870 S10.

import 'package:colonizethis_app/features/debug_log/debug_log_viewer_screen.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
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

  group('SPEC/ui/mobile-adaptation.md § 7 — DebugLogViewerScreen (empty '
      'buffer) @ 320 dp (Refs #2870 S10)', () {
    testWidgets('AC (positive) DebugLogViewerScreen empty buffer @ 320×640: no '
        'RenderFlex overflow exception, CtTopBar title `Debug log` + '
        'leading CtBackButton + default-selected `app` package chip + '
        'default-selected `info`/`warning`/`error` level chips all '
        'render', (WidgetTester tester) async {
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
            'must not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The `CtScreenShell` '
            'chrome — CtTopBar (title + leading CtBackButton) above '
            'the horizontal-scroll `SingleChildScrollView` filter '
            'row + 1 dp Divider + expanding ListView body — must '
            'lay out within the 320 dp column. The filter row '
            'hosts package + level multi-select `CtChoiceChip` `Wrap`s '
            "wrapped in a horizontal `SingleChildScrollView` so its "
            'intrinsic width is not bound by the 320 dp viewport, '
            'but the surrounding shell + Divider + body chain '
            'must still respect the 320 dp horizontal budget.',
      );

      // SPEC/program/debug-log-viewer.md § 4 Entry points pins the
      // localized `Debug log` title for the in-app shell. The
      // `appL10n` helper falls back to English for widget tests
      // that mount without full MaterialApp localization
      // delegates, so the literal renders at 320 dp without locale
      // plumbing.
      // ignore: avoid_hardcoded_strings_in_widgets
      expect(find.text('Debug log'), findsOneWidget);
      expect(
        find.byType(CtBackButton),
        findsOneWidget,
        reason:
            'The CtTopBar leading CtBackButton must remain mounted '
            'at 320 dp so the screen stays dismissable on the '
            'minimum viewport (the side menu flow is the primary '
            'mobile reach per SPEC/program/debug-log-viewer.md § 4).',
      );

      // SPEC/program/debug-log-viewer.md § 3 Filters pins the
      // default-selected `app` package and `info` / `warning` /
      // `error` level chips for the in-app viewer. Each chip must
      // remain reachable inside the 320 dp `SingleChildScrollView`
      // host without overflowing horizontally.
      expect(
        find.descendant(
          of: find.byType(CtChoiceChip),
          // ignore: avoid_hardcoded_strings_in_widgets
          matching: find.text('app'),
        ),
        findsOneWidget,
        reason:
            'Default-selected `app` package chip must mount inside '
            'the 320 dp filter row per SPEC/program/debug-log-viewer.md '
            '§ 3 defaults.',
      );
      for (final String label
          // ignore: avoid_hardcoded_strings_in_widgets
          in const <String>['info', 'warning', 'error']) {
        expect(
          find.descendant(
            of: find.byType(CtChoiceChip),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason:
              'Default-selected `$label` level chip must mount '
              'inside the 320 dp filter row per '
              'SPEC/program/debug-log-viewer.md § 3 defaults.',
        );
      }
    });

    testWidgets(
      'Negative control: DebugLogViewerScreen empty buffer @ 1024×768 '
      'also pumps without exception (regression sentinel for the '
      'overflow contract — keeps the 320 dp positive pin meaningful)',
      (WidgetTester tester) async {
        await pumpMobileNarrow(
          tester,
          const DebugLogViewerScreen(),
          size: kMobileWideRegressionViewport,
        );

        expect(tester.takeException(), isNull);
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(find.text('Debug log'), findsOneWidget);
        expect(find.byType(CtBackButton), findsOneWidget);
      },
    );
  });
}
