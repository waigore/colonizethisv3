import 'dart:convert';

import 'package:colonizethis_test/test.dart';
import 'package:flutter/services.dart';

void main() {
  test('transport tilesets are wired in map terrain config', () async {
    final raw = await rootBundle.loadString('assets/data/map_terrain_tilesets.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final transport =
        json['transport_tilesets'] as Map<String, dynamic>? ?? const {};

    expect(transport.containsKey('road'), isTrue);
    expect(transport.containsKey('rail'), isTrue);
  });

  test('transport overlay specs define masks 0..15 for road and rail', () async {
    const specs = [
      'assets/images/terrain/tilesets/tileset_transport_road_64.json',
      'assets/images/terrain/tilesets/tileset_transport_rail_64.json',
    ];

    for (final specPath in specs) {
      final raw = await rootBundle.loadString(specPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final tiles = json['tiles'] as List<dynamic>? ?? const [];
      final masks = <int>{};
      for (final tile in tiles) {
        final row = tile as Map<String, dynamic>;
        final mask = (row['mask'] as num).toInt();
        masks.add(mask);
      }

      expect(masks.length, 16, reason: 'Expected 16 masks in $specPath');
      for (var i = 0; i < 16; i++) {
        expect(masks.contains(i), isTrue, reason: '$specPath missing mask $i');
      }
    }
  });
}
