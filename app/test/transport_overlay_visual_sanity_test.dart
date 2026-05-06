import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart';
import 'package:flutter/services.dart';

const _kMinOpaquePixelsPerTransportAtlas = 2500;

Future<int> _countOpaquePixels(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (rgba == null) {
    throw StateError('Failed to decode RGBA bytes for $assetPath');
  }

  final bytes = rgba.buffer.asUint8List();
  var opaqueCount = 0;
  for (var i = 3; i < bytes.length; i += 4) {
    if (bytes[i] > 0) {
      opaqueCount++;
    }
  }
  return opaqueCount;
}

void main() {
  test('transport overlay atlases are not near-empty placeholders', () async {
    const atlasAssets = <String>[
      'assets/images/terrain/tilesets/tileset_transport_road_64.png',
      'assets/images/terrain/tilesets/tileset_transport_rail_64.png',
    ];

    for (final assetPath in atlasAssets) {
      final opaquePixels = await _countOpaquePixels(assetPath);
      expect(
        opaquePixels,
        greaterThanOrEqualTo(_kMinOpaquePixelsPerTransportAtlas),
        reason:
            '$assetPath contains too few visible pixels ($opaquePixels), expected at least '
            '$_kMinOpaquePixelsPerTransportAtlas',
      );
    }
  });
}
