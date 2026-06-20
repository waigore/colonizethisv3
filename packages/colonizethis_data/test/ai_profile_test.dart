import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

Map<String, dynamic> _baseJson({Map<String, dynamic>? parameters}) =>
    <String, dynamic>{
      'schema_version': 1,
      'profile_id': 'test_profile',
      'display_name': 'Test Profile',
      'parameters': parameters ?? <String, dynamic>{},
    };

void main() {
  group('AiProfile.fromJson defaults-fill', () {
    test('omitted parameters take registry defaults', () {
      final profile = AiProfile.fromJson(_baseJson());
      expect(profile.parameters.length, AiParameterRegistry.allParams.length);
      for (final p in AiParameterRegistry.allParams) {
        expect(profile.parameters[p.name], p.defaultValue, reason: p.name);
      }
    });

    test('parameters map contains exactly the registry key set', () {
      final profile = AiProfile.fromJson(
        _baseJson(parameters: {'personalityDomainWeights.economy': 80}),
      );
      expect(
        profile.parameters.keys.toSet(),
        AiParameterRegistry.allParams.map((p) => p.name).toSet(),
      );
      expect(profile.valueOf('personalityDomainWeights.economy'), 80);
    });
  });

  group('AiProfile.fromJson clamping and rounding', () {
    test('values above maxValue are clamped down', () {
      final profile = AiProfile.fromJson(
        _baseJson(parameters: {'personalityDomainWeights.economy': 9999}),
      );
      expect(profile.valueOf('personalityDomainWeights.economy'), 100);
    });

    test('values below minValue are clamped up', () {
      final profile = AiProfile.fromJson(
        _baseJson(parameters: {'personalityThresholds.warLikelihood': -50}),
      );
      expect(profile.valueOf('personalityThresholds.warLikelihood'), 0);
    });

    test('integer parameters round to nearest int', () {
      final profile = AiProfile.fromJson(
        _baseJson(parameters: {'personalityGoalWeights.conquer': 70.6}),
      );
      expect(profile.valueOf('personalityGoalWeights.conquer'), 71);
    });

    test('double parameters preserve fractional values', () {
      final profile = AiProfile.fromJson(
        _baseJson(
          parameters: {'kBuildRegimentBonusWhenBehindVictoryPace': 2.25},
        ),
      );
      expect(profile.valueOf('kBuildRegimentBonusWhenBehindVictoryPace'), 2.25);
    });
  });

  group('AiProfile.fromJson unknown keys', () {
    test('unknown parameter keys are ignored', () {
      final profile = AiProfile.fromJson(
        _baseJson(
          parameters: {
            'totallyUnknownParameter': 123,
            'personalityDomainWeights.economy': 60,
          },
        ),
      );
      expect(
        profile.parameters.containsKey('totallyUnknownParameter'),
        isFalse,
      );
      expect(profile.valueOf('personalityDomainWeights.economy'), 60);
    });
  });

  group('AiProfile.fromJson schema_version', () {
    test('rejects unsupported schema_version', () {
      final json = _baseJson()..['schema_version'] = 2;
      expect(() => AiProfile.fromJson(json), throwsFormatException);
    });

    test('rejects missing schema_version', () {
      final json = _baseJson()..remove('schema_version');
      expect(() => AiProfile.fromJson(json), throwsFormatException);
    });

    test('rejects missing profile_id', () {
      final json = _baseJson()..remove('profile_id');
      expect(() => AiProfile.fromJson(json), throwsFormatException);
    });
  });

  group('AiProfile round-trip', () {
    test('fromJson(toJson()) preserves parameters', () {
      final original = AiProfile.fromJson(
        _baseJson(
          parameters: {
            'personalityDomainWeights.economy': 70,
            'kDeclareWarAdjacentOwnerBonus': 40,
          },
        ),
      );
      final round = AiProfile.fromJson(original.toJson());
      expect(round.profileId, original.profileId);
      expect(round.displayName, original.displayName);
      expect(round.schemaVersion, original.schemaVersion);
      expect(round.parameters, original.parameters);
    });
  });

  group('AiProfile typed accessors', () {
    test('valueOf throws for unregistered keys', () {
      final profile = AiProfile.fromJson(_baseJson());
      expect(() => profile.valueOf('nope'), throwsArgumentError);
    });

    test('toDomainWeights / toGoalWeights / toThresholds read overrides', () {
      final profile = AiProfile.fromJson(
        _baseJson(
          parameters: {
            'personalityDomainWeights.military': 90,
            'personalityGoalWeights.conquer': 88,
            'personalityThresholds.warLikelihood': 77,
          },
        ),
      );
      expect(profile.toDomainWeights().military, 90);
      expect(profile.toGoalWeights().conquer, 88);
      expect(profile.toThresholds().warLikelihood, 77);
    });

    test('victoryConfigOverride reads a flat constant key', () {
      final profile = AiProfile.fromJson(
        _baseJson(parameters: {'kDeclareWarAdjacentOwnerBonus': 33}),
      );
      expect(
        profile.victoryConfigOverride('kDeclareWarAdjacentOwnerBonus'),
        33,
      );
    });
  });
}
