import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/fleet_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap_png_decode.dart';

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
    ...kTownIconIds.map(townIconCache.assetPath),
    ...TownIconCache.legacyTownIconAssetPaths,
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
