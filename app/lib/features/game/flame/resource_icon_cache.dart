import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/services.dart';

import '../../../config/app_assets.dart';

final _log = packageLogger();

/// Resource IDs for which icons exist (excludes commodities without tile resources).
const Set<String> kResourceIconIds = {
  'grain',
  'meat',
  'timber',
  'iron',
  'wool',
  'cotton',
  'coal',
  'sugar_cane',
  'tobacco',
  'furs',
  'copper',
  'tin',
  'horses',
  'lumber',
  'cast_iron',
  'fabric',
  'refined_sugar',
  'cigars',
  'fur_hats',
  'steel',
  'paper',
  'bronze',
  'gold',
  'silver',
  'gems',
  'diamonds',
  'spices',
};

/// Cache for loaded resource icons.
/// Loads all resource icons at startup and stores them keyed by resource ID.
class ResourceIconCache {
  final Map<String, ui.Image> _icons = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Size of resource icons in pixels.
  static const double iconSize = 64.0;

  /// Loads all resource icons asynchronously.
  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      await Future.wait(kResourceIconIds.map((id) => _loadIcon(id)));
      _isLoaded = true;
      _log.i('Loaded ${_icons.length} resource icons');
    } catch (e, stackTrace) {
      _icons.clear();
      _isLoaded = false;
      _log.e('Failed to load resource icons', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadIcon(String resourceId) async {
    final pngPath = '${kAppIcon64AssetPrefix}ui_icon_com_$resourceId.png';
    final imageData = await rootBundle.load(pngPath);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageData.buffer.asUint8List(), completer.complete);
    final image = await completer.future;
    _icons[resourceId] = image;
  }

  /// Returns the icon image for the given resource ID, or null if not loaded.
  ui.Image? getIcon(String? resourceId) {
    if (resourceId == null || resourceId.isEmpty) return null;
    return _icons[resourceId];
  }

  /// Returns true if an icon exists for the given resource ID.
  bool hasIcon(String? resourceId) {
    if (resourceId == null || resourceId.isEmpty) return false;
    return _icons.containsKey(resourceId);
  }
}

/// Global resource icon cache instance.
final resourceIconCache = ResourceIconCache();
