// PNG analysis helpers for plains plantation terrain goldens (#3961, #4734 Slice J).

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const kPlantationFieldMidTones = <String, (int, int, int)>{
  'tile_plains_sugar_cane': (109, 137, 77),
  'tile_plains_tobacco': (128, 108, 42),
  'tile_plains_cotton': (181, 179, 173),
  'tile_plains_spices': (149, 102, 59),
};

const kOwPlainsKeys = <String>[
  'tile_plains_grain',
  'tile_plains_meat',
  'tile_plains_horses',
];

const kPlantationKeys = <String>[
  'tile_plains_sugar_cane',
  'tile_plains_tobacco',
  'tile_plains_cotton',
  'tile_plains_spices',
];

bool isPlantationFieldHighlight(int r, int g, int b, int a) {
  if (a < 16) return false;
  return g > r + 8 && g > b + 8 && g >= 55 && r >= 40;
}

Future<ui.Image> decodePlantationPngFile(File file) async {
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<ByteData> plantationPngRawRgba(ui.Image image) async {
  final bd = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  expect(bd, isNotNull);
  return bd!;
}

String plantationRepoRootPath() {
  return Directory.current.path.endsWith('/app')
      ? Directory.current.parent.path
      : Directory.current.path;
}

Future<void> assertPlantationPngSilhouetteAndMidTones() async {
  final repoRoot = plantationRepoRootPath();
  final terrainDir = Directory('$repoRoot/app/assets/images/terrain');
  final baseFile = File(
    '$repoRoot/pytool/assets/terrain/tile_plains_plantation_base.png',
  );
  expect(baseFile.existsSync(), isTrue);

  final baseImage = await decodePlantationPngFile(baseFile);
  final baseBytes = await plantationPngRawRgba(baseImage);
  expect(baseImage.width, 64);
  expect(baseImage.height, 64);

  final meanRgbByKey = <String, (double, double, double)>{};

  for (final key in kPlantationKeys) {
    final file = File('${terrainDir.path}/$key.png');
    expect(file.existsSync(), isTrue, reason: 'missing $key.png');
    final image = await decodePlantationPngFile(file);
    expect(image.width, baseImage.width);
    expect(image.height, baseImage.height);
    final bytes = await plantationPngRawRgba(image);

    var alphaMismatches = 0;
    var fieldCount = 0;
    var sumR = 0.0;
    var sumG = 0.0;
    var sumB = 0.0;
    final pixelCount = image.width * image.height;
    for (var i = 0; i < pixelCount; i++) {
      final o = i * 4;
      final aBase = baseBytes.getUint8(o + 3);
      final aVar = bytes.getUint8(o + 3);
      if (aBase != aVar) alphaMismatches++;

      final r = bytes.getUint8(o);
      final g = bytes.getUint8(o + 1);
      final b = bytes.getUint8(o + 2);
      final br = baseBytes.getUint8(o);
      final bg = baseBytes.getUint8(o + 1);
      final bb = baseBytes.getUint8(o + 2);
      if (isPlantationFieldHighlight(br, bg, bb, aBase)) {
        fieldCount++;
        sumR += r;
        sumG += g;
        sumB += b;
        expect(aVar, aBase);
      }
    }
    expect(alphaMismatches, 0, reason: '$key alpha must match base silhouette');
    expect(fieldCount, greaterThan(100), reason: '$key field mask');
    meanRgbByKey[key] = (sumR / fieldCount, sumG / fieldCount, sumB / fieldCount);

    final target = kPlantationFieldMidTones[key]!;
    final mean = meanRgbByKey[key]!;
    expect((mean.$1 - target.$1).abs(), lessThan(55), reason: '$key mean R');
    expect((mean.$2 - target.$2).abs(), lessThan(55), reason: '$key mean G');
    expect((mean.$3 - target.$3).abs(), lessThan(55), reason: '$key mean B');
  }

  for (final a in kPlantationKeys) {
    for (final b in kPlantationKeys) {
      if (a == b) continue;
      final ma = meanRgbByKey[a]!;
      final mb = meanRgbByKey[b]!;
      final dist = math.sqrt(
        math.pow(ma.$1 - mb.$1, 2) +
            math.pow(ma.$2 - mb.$2, 2) +
            math.pow(ma.$3 - mb.$3, 2),
      );
      expect(dist, greaterThan(25), reason: '$a vs $b field means must differ');
    }
  }

  baseImage.dispose();
}
