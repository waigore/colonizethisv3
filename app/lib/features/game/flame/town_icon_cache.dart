import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:flutter/services.dart';

import '../../../config/app_assets.dart';

final _log = gameLogger();

const Set<String> kTownIconIds = {'port', 'town_inland'};

class TownIconCache {
  final Map<String, ui.Image> _icons = {};
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  static const double townRenderSize = 64.0;
  static const double portRenderSize = 32.0;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      await Future.wait(kTownIconIds.map((id) => _loadIcon(id)));
      _isLoaded = true;
      _log.i('Loaded ${_icons.length} town/port icons');
    } catch (e, stackTrace) {
      _icons.clear();
      _isLoaded = false;
      _log.e(
        'Failed to load town/port icons',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadIcon(String iconId) async {
    final pngPath = '${kAppIconAssetPrefix}ui_icon_com_$iconId.png';
    final imageData = await rootBundle.load(pngPath);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageData.buffer.asUint8List(), completer.complete);
    final image = await completer.future;
    _icons[iconId] = image;
  }

  ui.Image? getIcon(String? iconId) {
    if (iconId == null || iconId.isEmpty) return null;
    return _icons[iconId];
  }

  bool hasIcon(String? iconId) {
    if (iconId == null || iconId.isEmpty) return false;
    return _icons.containsKey(iconId);
  }
}

final townIconCache = TownIconCache();
