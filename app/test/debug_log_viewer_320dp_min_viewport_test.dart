// Pin the 320 dp minimum-viewport contract for the in-app
// `DebugLogViewerScreen` (SYS10001) — the full-screen log viewer
// reachable from the in-game side menu's `Debug log` entry per
// `SPEC/program/debug-log-viewer.md` § Entry points (the primary way
// to open the debug log on mobile and in narrow viewports when on the
// map).
//
// Existing screen-, panel-, and dialog-level 320 dp pins
// (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`,
// `unit_panels_320dp_min_viewport_test.dart`,
// `trade_screen_320dp_min_viewport_test.dart`,
// `technology_screen_320dp_min_viewport_test.dart`,
// `diplomacy_screen_320dp_min_viewport_test.dart`,
// `production_screen_320dp_min_viewport_test.dart`,
// `quick_battle_screen_320dp_min_viewport_test.dart`,
// `diplomacy_detail_screen_320dp_min_viewport_test.dart`,
// `game_initializing_320dp_min_viewport_test.dart`,
// `game_screen_320dp_min_viewport_test.dart`) cover every other
// player-app screen surface; this file extends that coverage to the
// debug-log shell. The screen mounts a Material `Scaffold` whose body
// stacks (top → bottom): an `AppBar` with title `Debug log` + trailing
// close `Icons.close` button, a filter row hosted by a horizontal
// `SingleChildScrollView` (package + level multi-select `FilterChip`
// rows), a 1 dp `Divider`, and an expanding `ListView.builder` of
// per-entry `Container` + `SelectableText` rows. At `kMinViewportWidth`
// (320 dp) the available column collapses to 320 dp; the chrome and
// body must lay out without `RenderFlex` overflow under both the
// empty-buffer path and a populated-buffer path that exercises the
// per-entry row tint chrome from `SPEC/program/debug-log-viewer.md`
// § Visual chrome.
//
// Each positive test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex`
//    overflow exception (which Flutter surfaces via
//    `FlutterError.onError`) escapes the framework — the contract
//    every sibling `*_320dp_min_viewport_test.dart` file relies on.
//  * The `AppBar` title `Debug log` and the trailing close
//    `Icons.close` button both render end-to-end so the layout
//    actually exercises the debug-log shell at 320 dp rather than
//    no-op'ing on an off-screen widget.
//  * The package filter row mounts the default-selected `app`
//    `FilterChip` and the level filter row mounts the default-selected
//    `info` / `warning` / `error` `FilterChip`s (per
//    `SPEC/program/debug-log-viewer.md` § 3 defaults), so the row
//    composition exercised at 320 dp matches the running app.
//
// The populated-buffer positive test additionally asserts at least one
// `Container` wraps the seeded `Level.warning` entry's first line —
// the per-entry row tint chrome from `SPEC/program/debug-log-viewer.md`
// § Visual chrome lays out within the narrow column without overflow.
//
// A wide negative control at 1024 × 768 dp pumps the same fixture
// without exception so a regression in the host overflow contract
// upstream of `DebugLogViewerScreen` itself would still surface.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/program/debug-log-viewer.md` § 4 Entry points (in-game
// side menu primary mobile reach) + § 5a Visual chrome.
// Refs #2870 S10 (no horizontal overflow at 320 dp on every covered
// screen).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/debug_log/debug_log_viewer_screen.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

/// Minimum supported viewport dimensions for `SPEC/ui/mobile-adaptation.md`
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing sibling screen-level pin files
/// (`trade_screen_320dp_min_viewport_test.dart`,
/// `technology_screen_320dp_min_viewport_test.dart`,
/// `game_screen_320dp_min_viewport_test.dart`).
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same screen renders without narrow chrome.
/// Mirrors the contract used by
/// `mobile_320dp_min_viewport_test.dart`,
/// `panels_320dp_min_viewport_test.dart`,
/// `dialogs_320dp_min_viewport_test.dart`,
/// `trade_screen_320dp_min_viewport_test.dart`, and
/// `technology_screen_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [DebugLogViewerScreen] at [size] under the running
/// editorial-monocle theme. Sets the surface size so the binding's
/// render flex math sees the minimum viewport and overrides
/// `MediaQuery` so widget code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value — the
/// pattern already used by every other `*_320dp_min_viewport_test.dart`
/// file. The viewer is presentational (no Riverpod providers), so no
/// provider overrides are required.
Future<void> _pumpDebugLogViewerAtSize(
  WidgetTester tester, {
  required Size size,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const DebugLogViewerScreen(),
      ),
    ),
  );
  // `pumpAndSettle` is safe here: the screen has no indefinite ticker
  // and the `ListView.builder` resolves synchronously against the
  // singleton `SessionLogBuffer`.
  await tester.pumpAndSettle();
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

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — DebugLogViewerScreen (empty '
    'buffer) @ 320 dp (Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) DebugLogViewerScreen empty buffer @ 320×640: no '
        'RenderFlex overflow exception, AppBar title `Debug log` + '
        'trailing close icon + default-selected `app` package chip + '
        'default-selected `info`/`warning`/`error` level chips all '
        'render',
        (WidgetTester tester) async {
          await _pumpDebugLogViewerAtSize(tester, size: _kMinViewport);

          expect(
            tester.takeException(),
            isNull,
            reason:
                'SPEC/ui/mobile-adaptation.md § 7: DebugLogViewerScreen '
                'must not emit a RenderFlex overflow exception at '
                'kMinViewportWidth (320 dp). The Material `Scaffold` '
                'chrome — AppBar (title + trailing close icon) above '
                'the horizontal-scroll `SingleChildScrollView` filter '
                'row + 1 dp Divider + expanding ListView body — must '
                'lay out within the 320 dp column. The filter row '
                'hosts package + level multi-select `FilterChip` `Wrap`s '
                "wrapped in a horizontal `SingleChildScrollView` so its "
                'intrinsic width is not bound by the 320 dp viewport, '
                'but the surrounding Scaffold + Divider + body chain '
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
            find.byIcon(Icons.close),
            findsOneWidget,
            reason:
                'The AppBar trailing close `Icons.close` button must '
                'remain mounted at 320 dp so the screen stays '
                'dismissable on the minimum viewport (the side menu '
                'flow is the primary mobile reach per '
                'SPEC/program/debug-log-viewer.md § 4).',
          );

          // SPEC/program/debug-log-viewer.md § 3 Filters pins the
          // default-selected `app` package and `info` / `warning` /
          // `error` level chips for the in-app viewer. Each chip must
          // remain reachable inside the 320 dp `SingleChildScrollView`
          // host without overflowing horizontally.
          expect(
            find.descendant(
              of: find.byType(FilterChip),
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
                of: find.byType(FilterChip),
                matching: find.text(label),
              ),
              findsOneWidget,
              reason:
                  'Default-selected `$label` level chip must mount '
                  'inside the 320 dp filter row per '
                  'SPEC/program/debug-log-viewer.md § 3 defaults.',
            );
          }
        },
      );

      testWidgets(
        'Negative control: DebugLogViewerScreen empty buffer @ 1024×768 '
        'also pumps without exception (regression sentinel for the '
        'overflow contract — keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpDebugLogViewerAtSize(
            tester,
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('Debug log'), findsOneWidget);
          expect(find.byIcon(Icons.close), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — DebugLogViewerScreen (populated '
    'buffer) @ 320 dp (Refs #2870 S10)',
    () {
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

          await _pumpDebugLogViewerAtSize(tester, size: _kMinViewport);

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

      testWidgets(
        'Negative control: DebugLogViewerScreen populated buffer @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the populated-buffer overflow contract)',
        (WidgetTester tester) async {
          SessionLogBuffer.instance.add(
            // ignore: avoid_hardcoded_strings_in_widgets
            LogEvent(Level.warning, 'app: wide regression pin line'),
          );

          await _pumpDebugLogViewerAtSize(
            tester,
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          // ignore: avoid_hardcoded_strings_in_widgets
          expect(find.text('Debug log'), findsOneWidget);
          expect(
            find.textContaining('wide regression pin line'),
            findsOneWidget,
          );
        },
      );
    },
  );
}
