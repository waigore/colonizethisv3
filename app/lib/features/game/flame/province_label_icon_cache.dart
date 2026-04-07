import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:flutter/services.dart';

import '../../../config/app_assets.dart';

final _log = gameLogger();

const Set<String> kProvinceLabelIconIds = {
  'map_capital_star',
  'map_presence_civilian',
  'map_presence_regiment',
  'map_presence_ship',
};

class ProvinceLabelIconCache {
  final Map<String, ui.Image> _icons = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  static const double iconSize = 32.0;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    try {
      await Future.wait(kProvinceLabelIconIds.map(_loadIcon));
      _isLoaded = true;
      _log.i('Loaded ${_icons.length} province label icons');
    } catch (e, stackTrace) {
      _icons.clear();
      _isLoaded = false;
      _log.e(
        'Failed to load province label icons',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadIcon(String iconId) async {
    final pngPath = '${kAppIconAssetPrefix}ui_icon_$iconId.png';
    final imageData = await rootBundle.load(pngPath);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageData.buffer.asUint8List(), completer.complete);
    final image = await completer.future;
    _icons[iconId] = image;
  }

  ui.Image? getIcon(String iconId) => _icons[iconId];
}

final provinceLabelIconCache = ProvinceLabelIconCache();
