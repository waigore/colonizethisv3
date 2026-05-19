import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/fleet_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

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
      await e2eAdvanceGameStartIntroUntilDismissed(tester);
      return;
    }
    if (e2eGameStartIntroBlocksUi(tester)) {
      await e2eAdvanceGameStartIntroUntilDismissed(tester);
      stepMs = 25;
      continue;
    }
    if (find.text('Creating game').evaluate().isNotEmpty) {
      await tester.pump(Duration(milliseconds: stepMs));
      stepMs = stepMs < 500 ? stepMs * 2 : 500;
      continue;
    }
    await tester.pump(Duration(milliseconds: stepMs));
    stepMs = stepMs < 500 ? stepMs * 2 : 500;
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
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => startButton.hitTestable().evaluate().isNotEmpty,
    timeout: const Duration(milliseconds: 600),
    perf: perf,
    phaseName: 'pump_until_start_button_tappable_after_drag',
  );
  await tester.ensureVisible(startButton);
  await tester.tap(startButton);
  await tester.pump();

  await e2eWaitForMapHudAfterNewGameStart(tester, overallCap: overallCap);

  expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () =>
        find.byKey(kHomeToCapitalButtonKey).hitTestable().evaluate().isNotEmpty,
    timeout: const Duration(milliseconds: 800),
    perf: perf,
    phaseName: 'pump_until_home_capital_tappable_after_map',
  );
  await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
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

/// Relocated 64px map icon paths from the asset manifest (sorted).
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
    reason: failures.isEmpty
        ? null
        : '$decodeFailuresPrefix\n${failures.join('\n')}',
  );
}

/// Asserts the manifest matches the canonical map icon families, then decodes
/// every PNG via [e2eDecodePngAssetPathsParallel] (bounded concurrency).
///
/// Used by new-game E2E tests that need the same warm-cache behavior.
///
/// Prefer [e2eEnsureAllRelocated64pxPngsLoadSuiteOnce] when each scenario needs
/// the same decode/assert path so work runs at most once per test VM (GitHub
/// #2336 AC3).
Future<void> e2eEnsureAllRelocated64pxPngsLoad() async {
  await e2eEnsureRelocated64pxPngDecode(<String>{
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
  });
}

Future<void>? _e2eAllRelocated64pxPngLoadSuiteFuture;

/// Runs [e2eEnsureAllRelocated64pxPngsLoad] at most once per isolate.
///
/// Subsequent calls await the same future so multiple E2E scenarios in one run
/// do not repeat manifest + parallel decode work (GitHub #2336 AC3).
Future<void> e2eEnsureAllRelocated64pxPngsLoadSuiteOnce() async {
  _e2eAllRelocated64pxPngLoadSuiteFuture ??= e2eEnsureAllRelocated64pxPngsLoad();
  return _e2eAllRelocated64pxPngLoadSuiteFuture!;
}
