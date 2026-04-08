import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/services.dart';

import '../../../config/app_assets.dart';

final _log = packageLogger();

const Map<String, String> kCivilianTypeToIconSlug = {
  'builder': 'builder',
  'engineer': 'engineer',
  'rail builder': 'rail_builder',
  'rail_builder': 'rail_builder',
  'railbuilder': 'rail_builder',
  'explorer': 'explorer',
  'merchant': 'merchant',
  'spy': 'spy',
};

const Set<String> kCivilianIconSlugs = {
  'builder',
  'engineer',
  'rail_builder',
  'explorer',
  'merchant',
  'spy',
};

class CivilianIconCache {
  final Map<String, ui.Image> _icons = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  static const double iconSize = 32.0;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      await Future.wait(kCivilianIconSlugs.map(_loadColorIcon));
      _isLoaded = true;
      _log.i('Loaded ${_icons.length} civilian map icons');
    } catch (e, stackTrace) {
      _icons.clear();
      _isLoaded = false;
      _log.e(
        'Failed to load civilian map icons',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadColorIcon(String slug) async {
    final pngPath = '${kAppIconAssetPrefix}ui_icon_civ_$slug.png';
    _icons[slug] = await _decodePng(pngPath);
  }

  Future<ui.Image> _decodePng(String assetPath) async {
    final imageData = await rootBundle.load(assetPath);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageData.buffer.asUint8List(), completer.complete);
    return completer.future;
  }

  String? _normalizeSlug(String unitType) {
    final normalized = unitType.trim().toLowerCase();
    return kCivilianTypeToIconSlug[normalized];
  }

  ui.Image? getIcon({required String unitType, required bool grayscale}) {
    // `grayscale` is handled at paint-time in the renderer so we keep only
    // one decoded asset per civilian type in cache.
    final _ = grayscale;
    final slug = _normalizeSlug(unitType);
    if (slug == null) return null;
    return _icons[slug];
  }
}

final civilianIconCache = CivilianIconCache();
