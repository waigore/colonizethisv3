import 'dart:io';

import 'package:image/image.dart' as img;

const Set<String> _resourceIconIds = <String>{
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

const String _iconsDirPath = 'app/assets/icons/64';

/// Optional design-time output: commodity dominant hues from icons.
/// Region-map extraction discs use fixed gold/brown (SPEC/ui/map-widget.md).
const String _outputPath =
    'app/lib/features/game/flame/resource_icon_disc_palette.dart';

void main() {
  final out = StringBuffer()
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln()
    ..writeln(
      '/// Optional commodity hue reference generated from resource icons.',
    )
    ..writeln(
      '/// Region-map extraction throughput discs use fixed gold/brown fills',
    )
    ..writeln(
      '/// (`region_map_component_shared.dart`; SPEC/ui/map-widget.md).',
    )
    ..writeln('///')
    ..writeln('/// Regenerate with:')
    ..writeln('/// `dart run tool/generate_resource_icon_disc_palette.dart`')
    ..writeln(
      'const Map<String, Color> kResourceIconDiscPalette = <String, Color>{',
    );

  final sortedIds = _resourceIconIds.toList()..sort();
  for (final resourceId in sortedIds) {
    final color = _dominantColorForIcon(resourceId);
    final hex = _argbHex(color.$1, color.$2, color.$3);
    out.writeln("  '$resourceId': Color($hex),");
  }
  out
    ..writeln('};')
    ..writeln()
    ..writeln('Color discColorForResourceId(String resourceId) {')
    ..writeln(
      "  return kResourceIconDiscPalette[resourceId] ?? const Color(0xFF888888);",
    )
    ..writeln('}');

  File(_outputPath).writeAsStringSync(out.toString());
  stdout.writeln('Wrote $_outputPath');
}

(int, int, int) _dominantColorForIcon(String resourceId) {
  final path = '$_iconsDirPath/ui_icon_com_$resourceId.png';
  final bytes = File(path).readAsBytesSync();
  final image = img.decodePng(bytes);
  if (image == null) {
    throw StateError('Failed to decode PNG: $path');
  }

  final hist = <int, int>{};
  for (final pixel in image) {
    if (pixel.a < 24) {
      continue;
    }
    final r = pixel.r;
    final g = pixel.g;
    final b = pixel.b;
    final luma = ((r * 299) + (g * 587) + (b * 114)) ~/ 1000;
    // Skip very dark outline pixels so fill colors reflect icon interiors.
    if (luma < 36) {
      continue;
    }
    final qr = (r ~/ 16) * 16;
    final qg = (g ~/ 16) * 16;
    final qb = (b ~/ 16) * 16;
    final key = (qr << 16) | (qg << 8) | qb;
    hist[key] = (hist[key] ?? 0) + 1;
  }
  if (hist.isEmpty) {
    return (136, 136, 136);
  }

  final winner = hist.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  final r = (winner >> 16) & 0xFF;
  final g = (winner >> 8) & 0xFF;
  final b = winner & 0xFF;
  return (r, g, b);
}

String _argbHex(int r, int g, int b) {
  final rr = r.toRadixString(16).padLeft(2, '0').toUpperCase();
  final gg = g.toRadixString(16).padLeft(2, '0').toUpperCase();
  final bb = b.toRadixString(16).padLeft(2, '0').toUpperCase();
  return '0xFF$rr$gg$bb';
}
