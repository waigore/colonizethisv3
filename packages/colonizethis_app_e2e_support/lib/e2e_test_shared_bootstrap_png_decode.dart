import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'package:colonizethis_app_e2e_support/e2e_support_validation_exception.dart';

/// Loads and decodes each path with bounded concurrency (overlapping I/O +
/// image decode completion) instead of strictly serial awaits.
///
/// Larger batches reduce the number of synchronization points where the loop
/// awaits *all* in-flight decodes before scheduling the next group, so a slow
/// decode no longer blocks every other decode in the same batch. The default
/// is sized to comfortably cover the relocated 64px icon manifest (~60 assets)
/// in a single batch, while still allowing callers on memory-constrained CI
/// runners to opt back into smaller chunks. Refs GitHub #2336 AC3.
Future<List<String>> e2eDecodePngAssetPathsParallel(
  List<String> assetPaths, {
  int batchSize = 64,
}) async {
  if (batchSize <= 0) {
    throw E2eSupportValidationException('batchSize must be positive');
  }
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
