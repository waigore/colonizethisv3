import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final _log = packageLogger();

/// Canonical PNG-from-asset decode helper for the Flame layer.
///
/// This is the **only** site that may call `ui.decodeImageFromList`; every icon
/// cache and tileset routes its decode through here so the
/// `rootBundle.load` -> `Completer` -> `decodeImageFromList` idiom has a single
/// source of truth (Refs #3699). The callback-completion semantics are
/// deliberate: do not switch to `instantiateImageCodec` here (the synchronous
/// callback avoids the documented region-map decode deadlock).
Future<ui.Image> decodeImageAsset(String assetPath) async {
  final imageData = await rootBundle.load(assetPath);
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(imageData.buffer.asUint8List(), completer.complete);
  return completer.future;
}

/// Shared load lifecycle for keyed asset-image caches in the Flame layer.
///
/// Concrete caches ([ResourceIconCache], [CivilianIconCache], [TownIconCache],
/// [ProvinceLabelIconCache], [FleetIconCache]) supply only their asset-id set,
/// the per-id [assetPath] builder, and the [loadLogLabel]; this base owns the
/// idempotent [load] guard, the decode fan-out, clear-on-error handling,
/// structured `logger` success/error logging, and the keyed image store
/// (Refs #3699).
abstract class AssetImageCache {
  final Map<String, ui.Image> _images = <String, ui.Image>{};
  bool _isLoading = false;
  bool _isLoaded = false;

  /// True once [load] has completed successfully.
  bool get isLoaded => _isLoaded;

  /// Asset ids decoded by [load]; each is resolved to a path via [assetPath].
  Iterable<String> get assetIds;

  /// Resolves an [assetId] to its bundle asset path.
  String assetPath(String assetId);

  /// Human-readable label used in structured load logging (e.g. `resource
  /// icons`); also drives the success-count log line.
  String get loadLogLabel;

  /// Decodes a single asset path. Routed through [decodeImageAsset] so the
  /// `ui.decodeImageFromList` call stays single-sourced; overridable by
  /// subclasses (including test fakes) to bypass real bundle loading.
  @protected
  Future<ui.Image> decodeAsset(String assetPath) =>
      decodeImageAsset(assetPath);

  /// Decoded image for [assetId], or null when not loaded.
  @protected
  ui.Image? imageForId(String assetId) => _images[assetId];

  /// True when an image is cached for [assetId].
  @protected
  bool hasImageForId(String assetId) => _images.containsKey(assetId);

  /// Idempotently decodes every [assetIds] entry into the keyed store.
  ///
  /// Concurrent or repeat calls after a successful load are no-ops. On failure
  /// the partial store is cleared, [isLoaded] stays false, and the error is
  /// rethrown after structured logging.
  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    try {
      await Future.wait(assetIds.map(_loadOne));
      _isLoaded = true;
      _log.i('Loaded ${_images.length} $loadLogLabel');
    } catch (e, stackTrace) {
      _images.clear();
      _isLoaded = false;
      _log.e('Failed to load $loadLogLabel', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadOne(String assetId) async {
    _images[assetId] = await decodeAsset(assetPath(assetId));
  }
}
