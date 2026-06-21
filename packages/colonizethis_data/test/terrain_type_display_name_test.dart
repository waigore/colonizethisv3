import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('terrainDisplayName (#3573 R13/AC11)', () {
    test('hardwood and scrub forest use canonical title-cased names', () {
      expect(terrainDisplayName(TerrainType.hardwoodForest), 'Hardwood Forest');
      expect(terrainDisplayName(TerrainType.scrubForest), 'Scrub Forest');
    });

    test('every TerrainType maps to a non-empty title-cased label', () {
      for (final t in TerrainType.values) {
        final label = terrainDisplayName(t);
        expect(label, isNotEmpty, reason: '$t must have a display name');
        // First letter of every space-separated word is upper case.
        for (final word in label.split(' ')) {
          expect(
            word.isNotEmpty && word[0] == word[0].toUpperCase(),
            isTrue,
            reason: '$t label "$label" must be title-cased',
          );
        }
        // Never the raw enum name or a camelCase/lowercase variant.
        expect(
          label,
          isNot(equals(t.name)),
          reason: '$t must not render the raw enum .name',
        );
      }
    });

    test('forest labels never use lower-case "forest" or a no-space variant', () {
      for (final t in [TerrainType.hardwoodForest, TerrainType.scrubForest]) {
        final label = terrainDisplayName(t);
        expect(label.contains('forest'), isFalse,
            reason: 'must be capital F: "$label"');
        expect(label.contains('Forest'), isTrue);
        expect(label.contains(' '), isTrue,
            reason: 'must be spaced: "$label"');
        expect(label, isNot(contains('hardwoodForest')));
        expect(label, isNot(contains('scrubForest')));
      }
    });
  });
}
