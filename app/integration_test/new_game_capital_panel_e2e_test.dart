import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/l10n/app_localizations.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app/test_support/province_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Drive frames without [WidgetTester.pumpAndSettle]: new-game progress uses a
/// non-idle [CircularProgressIndicator], and the in-game Flame view keeps tickers
/// active, so settle would hang or time out indefinitely.
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

Future<void> _waitUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration diagnoseAfter = Duration.zero,
}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  if (diagnoseAfter > Duration.zero) {
    await _pumpFor(tester, diagnoseAfter);
  }
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for $finder. '
    'Last exception: ${tester.takeException()}',
  );
}

void _collectTextPreorder(Element element, List<String> out) {
  final w = element.widget;
  if (w is Text) {
    final d = w.data;
    if (d != null && d.isNotEmpty) {
      out.add(d);
    }
  }
  element.visitChildren((child) {
    _collectTextPreorder(child, out);
  });
}

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new game → capital province panel matches model (wide layout)',
      (WidgetTester tester) async {
    expect(
      kCtE2EEnabled,
      isTrue,
      reason: 'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
    );

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    await bootstrapForIntegrationTest();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('New Game'));
    await _waitUntilFound(
      tester,
      find.text('Start'),
      timeout: const Duration(seconds: 30),
    );

    final startButton = find.ancestor(
      of: find.text('Start'),
      matching: find.byType(CtNinePatchButton),
    );
    expect(startButton, findsOneWidget);
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pump();

    // Progress dialog spins forever → never use pumpAndSettle here. Also dismiss
    // game-start intro (Yarn) once the map exists under the overlay.
    final setupDeadline = DateTime.now().add(const Duration(minutes: 6));
    var reachedMap = false;
    while (DateTime.now().isBefore(setupDeadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Could not create game').evaluate().isNotEmpty) {
        fail(
          'New game setup failed (error dialog). '
          'Exception: ${tester.takeException()}',
        );
      }
      final introOpen = find.byType(GameStartIntroOverlay).evaluate().isNotEmpty;
      if (introOpen) {
        if (find.text('Continue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue').first);
          await tester.pump(const Duration(milliseconds: 200));
        } else if (find.text('I shall.').evaluate().isNotEmpty) {
          await tester.tap(find.text('I shall.').first);
          await tester.pump(const Duration(milliseconds: 200));
        }
        continue;
      }
      final creating = find.text('Creating game').evaluate().isNotEmpty;
      if (creating) {
        continue;
      }
      if (find.byKey(kHomeToCapitalButtonKey).evaluate().isNotEmpty) {
        reachedMap = true;
        break;
      }
    }
    expect(
      reachedMap,
      isTrue,
      reason:
          'Timed out before map + home control (stuck on Creating game or setup?)',
    );

    expect(
      find.byKey(kHomeToCapitalButtonKey),
      findsOneWidget,
      reason:
          'Expected in-game map with home-to-capital control after setup (Refs #1592)',
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(kHomeToCapitalButtonKey));
    await _pumpFor(tester, const Duration(seconds: 1));

    expect(find.byKey(kCtE2EOpenCapitalProvinceDetailKey), findsOneWidget);
    await tester.tap(find.byKey(kCtE2EOpenCapitalProvinceDetailKey));

    await _waitUntilFound(
      tester,
      find.byKey(kCtE2EProvincePanelRootKey),
      timeout: const Duration(seconds: 30),
    );

    expect(find.byKey(kCtE2EProvincePanelRootKey), findsOneWidget);

    final snap = ctE2eLastPanelSnapshot;
    expect(snap, isNotNull);
    final l10n = lookupAppLocalizations(const Locale('en'));
    final expected = provincePanelWideLayoutExpectedTexts(snap!, l10n);

    final actual = <String>[];
    _collectTextPreorder(
      tester.element(find.byKey(kCtE2EProvincePanelRootKey)),
      actual,
    );
    expect(actual, orderedEquals(expected));
  });
}
