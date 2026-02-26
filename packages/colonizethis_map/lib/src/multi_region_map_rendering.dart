// Multi-region map composition: Old World + New World side by side.
// SPEC/program/map-visualization.md § Multi-region rendering.

import 'dart:typed_data';

import 'package:image/image.dart' as img;

const int _gapBetweenMaps = 24;
const int _labelHeight = 24;

/// Composes two map PNGs (Old World, New World) side by side with labels.
/// Returns combined PNG bytes.
Uint8List composeMultiRegionMapPng({
  required Uint8List oldWorldPng,
  required Uint8List newWorldPng,
}) {
  final owImg = img.decodeImage(oldWorldPng)!;
  final nwImg = img.decodeImage(newWorldPng)!;

  final totalWidth = owImg.width + _gapBetweenMaps + nwImg.width;
  final maxHeight = owImg.height > nwImg.height ? owImg.height : nwImg.height;
  final totalHeight = _labelHeight + maxHeight;

  final composite = img.Image(width: totalWidth, height: totalHeight);
  final white = composite.getColor(255, 255, 255);
  final black = composite.getColor(0, 0, 0);
  composite.clear(white);

  img.compositeImage(composite, owImg, dstX: 0, dstY: _labelHeight);
  img.compositeImage(
    composite,
    nwImg,
    dstX: owImg.width + _gapBetweenMaps,
    dstY: _labelHeight,
  );

  img.drawString(
    composite,
    'Old World',
    font: img.arial14,
    x: owImg.width ~/ 2 - 30,
    y: 2,
    color: black,
  );
  img.drawString(
    composite,
    'New World',
    font: img.arial14,
    x: owImg.width + _gapBetweenMaps + nwImg.width ~/ 2 - 35,
    y: 2,
    color: black,
  );

  return img.encodePng(composite);
}
