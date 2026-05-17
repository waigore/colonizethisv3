import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('naming rules', () {
    test('allGreatPowerIds matches config ids exactly', () {
      final idsFromConfig = defaultNamingConfig.greatPowers
          .map((gp) => gp.id)
          .toList();
      expect(idsFromConfig, allGreatPowerIds);
      expect(idsFromConfig.toSet().length, idsFromConfig.length);
    });

    test('default naming config has expected top-level counts', () {
      expect(defaultNamingConfig.greatPowers, hasLength(7));
      expect(defaultNamingConfig.minorNations, hasLength(6));
      expect(defaultNamingConfig.tribes, hasLength(10));
    });

    test('every naming entry has required non-empty fields', () {
      for (final gp in defaultNamingConfig.greatPowers) {
        expect(gp.id, isNotEmpty);
        expect(gp.countryName, isNotEmpty);
        expect(gp.adjective, isNotEmpty);
        expect(gp.capitalCityName, isNotEmpty);
        expect(gp.leaderVariants, isNotEmpty);
        for (final variant in gp.leaderVariants) {
          expect(variant.id, isNotEmpty);
          expect(variant.name, isNotEmpty);
          expect(variant.leaderKey, isNotEmpty);
          expect(variant.provinceNamePool, isNotEmpty);
        }
      }

      for (final minor in defaultNamingConfig.minorNations) {
        expect(minor.id, isNotEmpty);
        expect(minor.displayName, isNotEmpty);
        expect(minor.provinceNamePool, isNotEmpty);
      }

      for (final tribe in defaultNamingConfig.tribes) {
        expect(tribe.id, isNotEmpty);
        expect(tribe.displayName, isNotEmpty);
        expect(tribe.provinceNamePool, isNotEmpty);
      }
    });

    test('resolved config lookups return values for known ids', () {
      expect(defaultNamingConfig.gpById('england')?.countryName, 'England');
      expect(defaultNamingConfig.minorById('minor2')?.displayName, 'Germany');
      expect(defaultNamingConfig.tribeById('tribe3')?.displayName, 'Inca');
    });

    test('resolved config lookups return null for unknown ids', () {
      expect(defaultNamingConfig.gpById('missing_gp'), isNull);
      expect(defaultNamingConfig.minorById('missing_minor'), isNull);
      expect(defaultNamingConfig.tribeById('missing_tribe'), isNull);
    });

    test('prussia variants and helper methods resolve correctly', () {
      final prussia = defaultNamingConfig.gpById('prussia');
      expect(prussia, isNotNull);
      expect(prussia!.hasMultipleVariants, isTrue);
      expect(prussia.defaultLeaderVariantId, prussiaVariantFrederickTheGreat);
      expect(
        prussia.variantById(prussiaVariantFrederickWilliam).id,
        prussiaVariantFrederickWilliam,
      );
      expect(
        prussia.variantById('missing').id,
        prussiaVariantFrederickTheGreat,
      );

      expect(
        defaultNamingConfig.defaultLeaderVariantId('prussia'),
        prussiaVariantFrederickTheGreat,
      );
      expect(defaultNamingConfig.defaultLeaderVariantId('missing_gp'), isEmpty);
      expect(defaultNamingConfig.hasMultipleLeaderVariants('prussia'), isTrue);
      expect(defaultNamingConfig.hasMultipleLeaderVariants('england'), isFalse);
    });
  });
}
