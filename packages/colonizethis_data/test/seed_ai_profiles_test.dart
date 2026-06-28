import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('seedAiProfiles accessors', () {
    test('expose exactly the 7 canonical leader ids', () {
      expect(seedAiProfilesById.keys.toSet(), {
        'victoria',
        'napoleon',
        'isabella',
        'henry',
        'deruyter',
        'frederick',
        'gustavus',
      });
      expect(seedAiProfiles.length, 7);
    });

    test('each seed profile is complete against the registry', () {
      for (final profile in seedAiProfiles) {
        expect(
          profile.parameters.keys.toSet(),
          AiParameterRegistry.allParams.map((p) => p.name).toSet(),
          reason: profile.profileId,
        );
      }
    });

    test('personality params equal the hardcoded leader configs', () {
      for (final id in seedAiProfilesById.keys) {
        final profile = seedAiProfilesById[id]!;
        final dw = personalityDomainWeights[id]!;
        final gw = personalityGoalWeights[id]!;
        final th = personalityThresholds[id]!;

        expect(profile.valueOf('personalityDomainWeights.economy'), dw.economy);
        expect(
          profile.valueOf('personalityDomainWeights.military'),
          dw.military,
        );
        expect(
          profile.valueOf('personalityDomainWeights.diplomacy'),
          dw.diplomacy,
        );
        expect(
          profile.valueOf('personalityDomainWeights.research'),
          dw.research,
        );

        expect(profile.valueOf('personalityGoalWeights.defend'), gw.defend);
        expect(profile.valueOf('personalityGoalWeights.expand'), gw.expand);
        expect(profile.valueOf('personalityGoalWeights.conquer'), gw.conquer);
        expect(profile.valueOf('personalityGoalWeights.trade'), gw.trade);
        expect(profile.valueOf('personalityGoalWeights.tech'), gw.tech);
        expect(
          profile.valueOf('personalityGoalWeights.diplomacy'),
          gw.diplomacy,
        );

        expect(
          profile.valueOf('personalityThresholds.warLikelihood'),
          th.warLikelihood,
        );
        expect(
          profile.valueOf('personalityThresholds.peaceTendency'),
          th.peaceTendency,
        );
        expect(
          profile.valueOf('personalityThresholds.allianceTendency'),
          th.allianceTendency,
        );
        expect(
          profile.valueOf('personalityThresholds.researchNaval'),
          th.researchNaval,
        );
        expect(
          profile.valueOf('personalityThresholds.researchMilitary'),
          th.researchMilitary,
        );
        expect(
          profile.valueOf('personalityThresholds.researchEconomic'),
          th.researchEconomic,
        );
        expect(
          profile.valueOf('personalityThresholds.researchExploration'),
          th.researchExploration,
        );
      }
    });

    test('victory-config params equal the registry defaults', () {
      for (final profile in seedAiProfiles) {
        for (final p in AiParameterRegistry.byCategory(
          AiParameterCategory.victoryConfig,
        )) {
          expect(profile.valueOf(p.name), p.defaultValue, reason: p.name);
        }
      }
    });

    test('toThresholds reconstructs the leader thresholds', () {
      final napoleon = seedAiProfilesById['napoleon']!;
      final th = napoleon.toThresholds();
      expect(
        th.warLikelihood,
        personalityThresholds['napoleon']!.warLikelihood,
      );
      expect(
        th.researchMilitary,
        personalityThresholds['napoleon']!.researchMilitary,
      );
    });
  });

  group('on-disk seed JSON parity', () {
    test('each committed profile JSON parses to the seed profile', () {
      for (final id in seedAiProfilesById.keys) {
        final file = File('lib/src/profiles/$id.json');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'missing lib/src/profiles/$id.json',
        );
        final decoded =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final fromDisk = AiProfile.fromJson(decoded);
        final embedded = seedAiProfilesById[id]!;

        expect(fromDisk.profileId, embedded.profileId, reason: id);
        expect(fromDisk.displayName, embedded.displayName, reason: id);
        expect(fromDisk.schemaVersion, embedded.schemaVersion, reason: id);
        expect(fromDisk.parameters, embedded.parameters, reason: id);
      }
    });

    test('profile_id and display_name follow the seed convention', () {
      for (final id in seedAiProfilesById.keys) {
        final profile = seedAiProfilesById[id]!;
        expect(profile.profileId, '${id}_seed');
        expect(profile.displayName, endsWith('(seed)'));
      }
    });
  });
}
