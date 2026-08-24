import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('wave 7 Slice B extraction-cap splits (Refs #4626 AC4)', () {
    test('family libraries exist and do not use part directives', () {
      const names = <String>[
        'tech_extraction_caps_ow_food.dart',
        'tech_extraction_caps_timber_minerals.dart',
        'tech_extraction_caps_nw.dart',
        'tech_extraction_caps_precious.dart',
      ];
      for (final name in names) {
        final file = File('lib/src/$name');
        expect(file.existsSync(), isTrue, reason: name);
        final text = file.readAsStringSync();
        expect(text.contains('part '), isFalse, reason: name);
        expect(text.contains('part of '), isFalse, reason: name);
      }
    });

    test('family tables use kTechId identifiers not raw catalog strings', () {
      const names = <String>[
        'tech_extraction_caps_ow_food.dart',
        'tech_extraction_caps_timber_minerals.dart',
        'tech_extraction_caps_nw.dart',
        'tech_extraction_caps_precious.dart',
      ];
      final rawKey = RegExp(r"'[a-z][a-z0-9_]*'\s*:");
      for (final name in names) {
        final text = File('lib/src/$name').readAsStringSync();
        expect(text.contains('kTechId'), isTrue, reason: name);
        expect(rawKey.hasMatch(text), isFalse, reason: name);
      }
    });

    test('merged cap lookup still raises grain with land enclosure', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdLandEnclosure: true,
        }, Resource.grain.name),
        2,
      );
    });
  });
}
