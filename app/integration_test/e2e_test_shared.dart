import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class E2ePerfLog {
  E2ePerfLog(this.testName);

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

Future<void> e2ePumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

Future<void> e2eWaitUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  Duration diagnoseAfter = Duration.zero,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_found',
}) async {
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_found_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    if (finder.evaluate().isNotEmpty) {
      perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
      return;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = math.min(500, stepMs * 2);
  }
  if (diagnoseAfter > Duration.zero) {
    await e2ePumpFor(tester, diagnoseAfter);
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for $finder. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Returns after the first [Finder] has at least one hit-testable match.
Future<void> e2eWaitUntilAnyFinderHitTestable(
  WidgetTester tester,
  List<Finder> finders, {
  required Duration timeout,
  E2ePerfLog? perf,
  String phaseName = 'wait_until_any',
}) async {
  if (finders.isEmpty) {
    return;
  }
  final sw = Stopwatch()..start();
  perf?.bumpCounter('wait_until_any_calls', meta: 'phase=$phaseName');
  var stepMs = 25;
  while (sw.elapsed < timeout) {
    for (final finder in finders) {
      if (finder.hitTestable().evaluate().isNotEmpty) {
        perf?.timing(phaseName, sw.elapsed, meta: 'result=found');
        return;
      }
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = math.min(500, stepMs * 2);
  }
  perf?.timing(phaseName, sw.elapsed, meta: 'result=timeout');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for any of $finders. '
    'Last exception: ${tester.takeException()}',
  );
}

/// Loads and decodes each path with bounded concurrency (overlapping I/O +
/// image decode completion) instead of strictly serial awaits.
Future<List<String>> e2eDecodePngAssetPathsParallel(
  List<String> assetPaths, {
  int batchSize = 8,
}) async {
  final failures = <String>[];
  for (var i = 0; i < assetPaths.length; i += batchSize) {
    final end = i + batchSize > assetPaths.length
        ? assetPaths.length
        : i + batchSize;
    final chunk = assetPaths.sublist(i, end);
    final chunkFailures = await Future.wait(
      chunk.map((assetPath) async {
        try {
          final data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List();
          final completer = Completer<ui.Image>();
          ui.decodeImageFromList(bytes, completer.complete);
          final image = await completer.future;
          image.dispose();
          return null;
        } catch (e) {
          return '$assetPath ($e)';
        }
      }),
    );
    for (final message in chunkFailures) {
      if (message != null) {
        failures.add(message);
      }
    }
  }
  return failures;
}

Future<void> _e2eTapGameStartIntroOverlayContinueIfPresent(
  WidgetTester tester,
) async {
  if (find.text('Continue').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue').first);
    await tester.pump(const Duration(milliseconds: 200));
    return;
  }
  if (find.text('I shall.').evaluate().isNotEmpty) {
    await tester.tap(find.text('I shall.').first);
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// After [Start] is tapped, polls until the in-game map HUD is visible.
///
/// Evaluates success before the first pump; uses exponential backoff on pump
/// intervals (25ms → … capped at 500ms) per `SPEC/program/e2e-integration-tests.md`
/// / issue #2336 adaptive polling guidance.
Future<void> e2eWaitForMapHudAfterNewGameStart(
  WidgetTester tester, {
  Duration overallCap = const Duration(seconds: 60),
}) async {
  final setupDeadline = DateTime.now().add(overallCap);
  var stepMs = 25;
  while (DateTime.now().isBefore(setupDeadline)) {
    if (find.text('Could not create game').evaluate().isNotEmpty) {
      fail(
        'New game setup failed (error dialog). '
        'Exception: ${tester.takeException()}',
      );
    }
    if (find.byKey(kHomeToCapitalButtonKey).evaluate().isNotEmpty) {
      return;
    }
    if (find.byType(GameStartIntroOverlay).evaluate().isNotEmpty) {
      await _e2eTapGameStartIntroOverlayContinueIfPresent(tester);
      stepMs = 25;
      continue;
    }
    if (find.text('Creating game').evaluate().isNotEmpty) {
      await tester.pump(Duration(milliseconds: stepMs));
      stepMs = math.min(500, stepMs * 2);
      continue;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = math.min(500, stepMs * 2);
  }
  fail(
    'Timed out after ${overallCap.inSeconds}s waiting for '
    'map (home→capital). Last exception: ${tester.takeException()}',
  );
}

/// Canonical new-game → map HUD path shared by E2E scenarios (Refs #2336).
Future<void> e2eBootstrapNewGameToMap(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration overallCap = const Duration(seconds: 60),
}) async {
  final phaseSw = Stopwatch()..start();
  await tester.tap(find.text('New Game'));
  await e2eWaitUntilFound(
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
  await tester.tap(startButton);
  await tester.pump();

  await e2eWaitForMapHudAfterNewGameStart(tester, overallCap: overallCap);

  expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 500));
  perf?.timing('new_game_to_map', phaseSw.elapsed);
}

/// Collects non-empty [Text] data in depth-first preorder (E2E snapshot helpers).
void e2eCollectTextPreorder(Element element, List<String> out) {
  final w = element.widget;
  if (w is Text) {
    final d = w.data;
    if (d != null && d.isNotEmpty) {
      out.add(d);
    }
  }
  element.visitChildren((child) {
    e2eCollectTextPreorder(child, out);
  });
}

/// Sorted list of `assets/icons/64/*.png` entries from the asset manifest.
Future<List<String>> e2eDiscoverRelocated64pxPngAssets() async {
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

/// Asserts manifest contents match [expectedAssets], then decodes via
/// [e2eDecodePngAssetPathsParallel] (Refs #2336 AC3).
Future<void> e2eEnsureRelocated64pxPngDecode(
  Set<String> expectedAssets, {
  String emptyManifestReason =
      'Expected relocated map icon PNGs under assets/icons/64/, but none were found in the asset manifest.',
  String? countMismatchReason,
  String? orderedMismatchReason,
  String decodeFailuresPrefix =
      'Failed to load one or more relocated 64px PNG assets:',
}) async {
  final assets = await e2eDiscoverRelocated64pxPngAssets();
  final expectedSorted = expectedAssets.toList()..sort();
  expect(assets, isNotEmpty, reason: emptyManifestReason);
  expect(
    assets.length,
    expectedAssets.length,
    reason:
        countMismatchReason ??
        'Unexpected number of relocated 64px PNG assets. '
            'Expected ${expectedAssets.length} map-family files, found ${assets.length}.',
  );
  expect(
    assets,
    orderedEquals(expectedSorted),
    reason:
        orderedMismatchReason ??
        'Relocated 64px PNG manifest entries do not match expected map icon families.',
  );
  final failures = await e2eDecodePngAssetPathsParallel(assets);
  expect(
    failures,
    isEmpty,
    reason: failures.isEmpty ? null : '$decodeFailuresPrefix\n${failures.join('\n')}',
  );
}
