import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/fleet_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/l10n/app_localizations.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app/test_support/province_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _E2ePerfLog {
  _E2ePerfLog(this.testName);

  final String testName;
  final Map<String, int> _counters = <String, int>{};

  void bumpCounter(String name, {int by = 1, String? meta}) {
    _counters[name] = (_counters[name] ?? 0) + by;
    final metaPart = meta == null ? '' : '|meta=$meta';
    debugPrint(
      'E2E_COUNTER|test=$testName|name=$name|value=${_counters[name]}$metaPart',
    );
  }

  void timing(String phase, Duration elapsed, {String? meta}) {
    final metaPart = meta == null ? '' : '|meta=$meta';
    debugPrint(
      'E2E_TIMING|test=$testName|phase=$phase|ms=${elapsed.inMilliseconds}$metaPart',
    );
  }
}

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
  _E2ePerfLog? perf,
  String phaseName = 'wait_until_found',
}) async {
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_found_calls', meta: 'phase=$phaseName');
  while (sw.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
      return;
    }
  }
  if (diagnoseAfter > Duration.zero) {
    await _pumpFor(tester, diagnoseAfter);
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
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

Future<List<String>> _discoverRelocated64pxPngAssets() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets =
      manifest
          .listAssets()
          .where(
            (assetPath) =>
                assetPath.startsWith('assets/icons/64/') &&
                assetPath.endsWith('.png'),
          )
          .toList()
        ..sort();
  return assets;
}

Future<void> _ensureAllRelocated64pxPngsLoad() async {
  final assets = await _discoverRelocated64pxPngAssets();
  final expectedAssets = <String>{
    ...kCivilianIconSlugs.map(
      (slug) => 'assets/icons/64/ui_icon_civ_$slug.png',
    ),
    ...kResourceIconIds.map(
      (resourceId) => 'assets/icons/64/ui_icon_com_$resourceId.png',
    ),
    ...kTownIconIds.map((iconId) => 'assets/icons/64/ui_icon_com_$iconId.png'),
    ...kProvinceLabelIconIds.map(
      (iconId) => 'assets/icons/64/ui_icon_$iconId.png',
    ),
    kFleetMapIcon64PngAssetPath,
  };
  final expectedSorted = expectedAssets.toList()..sort();

  expect(
    assets,
    isNotEmpty,
    reason:
        'Expected relocated map icon PNGs under assets/icons/64/, but none were found in the asset manifest.',
  );
  expect(
    assets.length,
    expectedAssets.length,
    reason:
        'Unexpected number of relocated 64px PNG assets. '
        'Expected ${expectedAssets.length} map-family files, found ${assets.length}.',
  );
  expect(
    assets,
    orderedEquals(expectedSorted),
    reason:
        'Relocated 64px PNG manifest entries do not match expected map icon families.',
  );

  final failures = <String>[];
  for (final assetPath in assets) {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      final image = await completer.future;
      image.dispose();
    } catch (e) {
      failures.add('$assetPath ($e)');
    }
  }

  expect(
    failures,
    isEmpty,
    reason:
        'Failed to load one or more relocated 64px PNG assets:\n${failures.join('\n')}',
  );
}

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new game → capital province panel matches model (wide layout)', (
    WidgetTester tester,
  ) async {
    const testName = 'new_game_capital_panel';
    final perf = _E2ePerfLog(testName);
    final testSw = Stopwatch()..start();
    expect(
      kCtE2EEnabled,
      isTrue,
      reason:
          'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
    );

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    final bootstrapSw = Stopwatch()..start();
    await bootstrapForIntegrationTest();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    perf.timing('bootstrap_for_integration_test', bootstrapSw.elapsed);
    final preloadSw = Stopwatch()..start();
    await _ensureAllRelocated64pxPngsLoad();
    perf.timing('asset_preload', preloadSw.elapsed);

    await tester.tap(find.text('New Game'));
    await _waitUntilFound(
      tester,
      find.text('Start'),
      timeout: const Duration(seconds: 30),
      perf: perf,
      phaseName: 'wait_until_found_start_button',
    );

    final startButton = find.ancestor(
      of: find.text('Start'),
      matching: find.byType(CtNinePatchButton),
    );
    expect(startButton, findsOneWidget);

    final shellScrollable = find.descendant(
      of: find.byType(CtDialogShell),
      matching: find.byType(Scrollable),
    );
    await tester.dragUntilVisible(
      startButton,
      shellScrollable,
      const Offset(0, -120),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.ensureVisible(startButton);
    final newGameToMapSw = Stopwatch()..start();
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
      final introOpen = find
          .byType(GameStartIntroOverlay)
          .evaluate()
          .isNotEmpty;
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
    perf.timing('new_game_to_map', newGameToMapSw.elapsed);

    await tester.tap(find.byKey(kHomeToCapitalButtonKey));
    await _pumpFor(tester, const Duration(seconds: 1));

    expect(find.byKey(kCtE2EOpenCapitalProvinceDetailKey), findsOneWidget);
    await tester.tap(find.byKey(kCtE2EOpenCapitalProvinceDetailKey));

    await _waitUntilFound(
      tester,
      find.byKey(kCtE2EProvincePanelRootKey),
      timeout: const Duration(seconds: 30),
      perf: perf,
      phaseName: 'open_panel_province',
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
    perf.timing('test_total', testSw.elapsed);
  });
}
