import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/services.dart';

import '../../../config/app_assets.dart';

final _log = packageLogger();

class FleetIconCache {
  ui.Image? _icon;
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  static const double iconSize = 64.0;

  Future<void> load() async {
    if (_isLoaded || _isLoading) {
      return;
    }
    _isLoading = true;
    try {
      _icon = await _decodePng('${kAppIcon64AssetPrefix}ui_icon_map_fleet.png');
      _isLoaded = true;
      _log.i('Loaded fleet map icon');
    } catch (e, stackTrace) {
      _icon = null;
      _isLoaded = false;
      _log.e(
        'Failed to load fleet map icon',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<ui.Image> _decodePng(String assetPath) async {
    final imageData = await rootBundle.load(assetPath);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageData.buffer.asUint8List(), completer.complete);
    return completer.future;
  }

  ui.Image? getIcon() => _icon;
}

final fleetIconCache = FleetIconCache();
