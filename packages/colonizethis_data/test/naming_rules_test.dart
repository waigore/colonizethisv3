import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  final config = defaultNamingConfig;

  group('allGreatPowerIds', () {
    test('contains expected GPs (GDD 09)', () {
      expect(allGreatPowerIds, contains('england'));
      expect(allGreatPowerIds, contains('france'));
      expect(allGreatPowerIds, contains('prussia'));
      expect(allGreatPowerIds, contains('sweden'));
      expect(allGreatPowerIds.length, 7);
    });
  });

  group('Prussia variant ids', () {
    test('prussia has two leader variants', () {
      final gp = config.gpById('prussia');
      expect(gp, isNotNull);
      expect(gp!.hasMultipleVariants, isTrue);
      expect(gp.leaderVariants.length, 2);
    });

    test('variantById returns correct variant', () {
      final gp = config.gpById('prussia')!;
      final frederick = gp.variantById(prussiaVariantFrederickTheGreat);
      expect(frederick.name, contains('Frederick the Great'));
      final frederickWilliam = gp.variantById(prussiaVariantFrederickWilliam);
      expect(frederickWilliam.name, contains('Frederick William'));
    });

    test('variantById unknown falls back to first', () {
      final gp = config.gpById('england')!;
      final v = gp.variantById('unknown');
      expect(v, equals(gp.leaderVariants.first));
    });
  });

  group('ResolvedNamingConfig.gpById', () {
    test('returns GreatPowerNaming for known id', () {
      final gp = config.gpById('england');
      expect(gp, isNotNull);
      expect(gp!.id, 'england');
      expect(gp.countryName, 'England');
      expect(gp.capitalCityName, 'London');
    });

    test('returns null for unknown id', () {
      expect(config.gpById('unknown_gp'), isNull);
    });
  });

  group('ResolvedNamingConfig.defaultLeaderVariantId', () {
    test('returns first variant id for known GP', () {
      expect(config.defaultLeaderVariantId('england'), 'queen_victoria');
      expect(config.defaultLeaderVariantId('prussia'), prussiaVariantFrederickTheGreat);
    });

    test('returns empty string for unknown GP', () {
      expect(config.defaultLeaderVariantId('unknown'), '');
    });
  });

  group('ResolvedNamingConfig.hasMultipleLeaderVariants', () {
    test('true for prussia', () {
      expect(config.hasMultipleLeaderVariants('prussia'), isTrue);
    });

    test('false for england', () {
      expect(config.hasMultipleLeaderVariants('england'), isFalse);
    });

    test('false for unknown GP', () {
      expect(config.hasMultipleLeaderVariants('unknown'), isFalse);
    });
  });

  group('ResolvedNamingConfig.minorById', () {
    test('returns MinorNationNaming for known id', () {
      final m = config.minorById('minor1');
      expect(m, isNotNull);
      expect(m!.id, 'minor1');
      expect(m.displayName, 'Italy');
      expect(m.provinceNamePool, isNotEmpty);
    });

    test('returns null for unknown id', () {
      expect(config.minorById('unknown_minor'), isNull);
    });
  });

  group('ResolvedNamingConfig.tribeById', () {
    test('returns TribeNaming for known id', () {
      final t = config.tribeById('tribe1');
      expect(t, isNotNull);
      expect(t!.id, 'tribe1');
      expect(t.displayName, 'Aztec');
      expect(t.provinceNamePool, isNotEmpty);
    });

    test('returns null for unknown id', () {
      expect(config.tribeById('unknown_tribe'), isNull);
    });
  });

  group('defaultNamingConfig structure', () {
    test('greatPowers count matches allGreatPowerIds', () {
      expect(config.greatPowers.length, allGreatPowerIds.length);
    });

    test('minorNations and tribes are non-empty (GDD 09b/09c)', () {
      expect(config.minorNations.length, greaterThanOrEqualTo(6));
      expect(config.tribes.length, greaterThanOrEqualTo(6));
    });

    test('LeaderVariant has required fields', () {
      final gp = config.gpById('england')!;
      final v = gp.leaderVariants.first;
      expect(v.id, isNotEmpty);
      expect(v.name, isNotEmpty);
      expect(v.leaderKey, isNotEmpty);
      expect(v.provinceNamePool, isNotEmpty);
    });
  });
}
