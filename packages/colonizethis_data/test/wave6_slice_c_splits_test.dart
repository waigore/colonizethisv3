import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

final _src = Directory('lib/src');

Set<String> _srcNames() {
  return _src
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .toSet();
}

File _srcFile(String name) => File('lib/src/$name');

bool _hasPartDirective(File file) {
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('part ') || trimmed.startsWith('part of ')) {
      return true;
    }
  }
  return false;
}

final _paramName = RegExp(r"victoryConfig(?:Int|Double)Param\(\s*'(\w+)'");

Set<String> _paramNamesIn(File file) {
  return _paramName
      .allMatches(file.readAsStringSync())
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  group('wave 6 Slice C splits (Refs #4412 AC5–AC6)', () {
    test(
      'military params no longer register leftover stall or declare-war',
      () {
        final names = _paramNamesIn(
          _srcFile('ai_parameter_victory_config_params_military.dart'),
        );
        expect(names, isNotEmpty);
        for (final name in names) {
          expect(name.startsWith('kStalled'), isFalse, reason: name);
          expect(name.startsWith('kDeclareWar'), isFalse, reason: name);
        }
      },
    );

    test('leftover stall and declare-war families live in sibling lists', () {
      final names = _srcNames();
      expect(
        names.contains('ai_parameter_victory_config_params_declare_war.dart'),
        isTrue,
      );
      final stall = _paramNamesIn(
        _srcFile('ai_parameter_victory_config_params_military_stall.dart'),
      );
      expect(stall.contains('kStalledOldWorldProvinceThreshold'), isTrue);
      expect(stall.contains('kStalledConquestFieldArmySplitCap'), isTrue);
      final declareWarGp = _paramNamesIn(
        _srcFile('ai_parameter_victory_config_params_declare_war_gp.dart'),
      );
      expect(declareWarGp.contains('kDeclareWarAdjacentOwnerBonus'), isTrue);
      final declareWarMinor = _paramNamesIn(
        _srcFile('ai_parameter_victory_config_params_declare_war_minor.dart'),
      );
      expect(
        declareWarMinor.contains('kDeclareWarStalledAnyOwMinorBonus'),
        isTrue,
      );
    });

    test('victoryConfigParams still covers every registered name once', () {
      final names = AiParameterRegistry.byCategory(
        AiParameterCategory.victoryConfig,
      ).map((p) => p.name).toList();
      expect(names.toSet().length, names.length);
      expect(
        names.contains('kMilitaryVictoryOldWorldProvinceThreshold'),
        isTrue,
      );
      expect(names.contains('kStalledOldWorldProvinceThreshold'), isTrue);
      expect(names.contains('kDeclareWarAdjacentOwnerBonus'), isTrue);
    });

    test('personality types, tables, lookup, and dossier cap are separate', () {
      final names = _srcNames();
      expect(names.contains('ai_personality_types.dart'), isTrue);
      expect(names.contains('ai_personality_tables.dart'), isTrue);
      expect(names.contains('ai_personality_lookup.dart'), isTrue);
      expect(names.contains('ai_dossier_config.dart'), isTrue);

      final types = _srcFile('ai_personality_types.dart').readAsStringSync();
      expect(types.contains('class PersonalityDomainWeights'), isTrue);
      expect(types.contains('personalityDomainWeights'), isFalse);

      final tables = _srcFile('ai_personality_tables.dart').readAsStringSync();
      expect(tables.contains('personalityDomainWeights'), isTrue);
      expect(tables.contains('kMaxDossierEvidenceEntries'), isFalse);

      final lookup = _srcFile('ai_personality_lookup.dart').readAsStringSync();
      expect(lookup.contains('canonicalLeaderIdForPersonality'), isTrue);
      expect(lookup.contains('kMaxDossierEvidenceEntries'), isFalse);

      final dossier = _srcFile('ai_dossier_config.dart').readAsStringSync();
      expect(dossier.contains('kMaxDossierEvidenceEntries'), isTrue);
      expect(dossier.contains('personalityDomainWeights'), isFalse);
    });

    test('naming pools are split by faction family', () {
      final names = _srcNames();
      expect(names.contains('naming_default_great_powers.dart'), isTrue);
      expect(names.contains('naming_default_minors.dart'), isTrue);
      expect(names.contains('naming_default_tribes.dart'), isTrue);
      expect(
        _srcFile('naming_default_great_powers.dart').readAsStringSync(),
        contains('defaultNamingGreatPowers'),
      );
      expect(
        _srcFile('naming_default_minors.dart').readAsStringSync(),
        contains('defaultNamingMinors'),
      );
      expect(
        _srcFile('naming_default_tribes.dart').readAsStringSync(),
        contains('defaultNamingTribes'),
      );
      expect(defaultNamingConfig.greatPowers, hasLength(7));
      expect(defaultNamingConfig.minorNations, hasLength(6));
      expect(defaultNamingConfig.tribes, hasLength(10));
    });

    test('regiment catalog rows are split by era', () {
      expect(_srcNames().contains('combat_regiment_catalog_era1.dart'), isTrue);
      expect(_srcNames().contains('combat_regiment_catalog_era2.dart'), isTrue);
      expect(_srcNames().contains('combat_regiment_catalog_era3.dart'), isTrue);
      expect(_srcNames().contains('combat_regiment_catalog_era4.dart'), isTrue);
      expect(regimentCatalog, hasLength(29));
      expect(regimentCatalog.where((r) => r.era == 1), hasLength(7));
      expect(regimentCatalog.where((r) => r.era == 2), hasLength(8));
      expect(regimentCatalog.where((r) => r.era == 3), hasLength(7));
      expect(regimentCatalog.where((r) => r.era == 4), hasLength(7));
    });

    test('public lookup helpers and catalog names stay importable', () {
      expect(canonicalLeaderIdForPersonality('england_leader'), 'victoria');
      expect(getDomainWeightsForLeader('victoria').economy, 70);
      expect(kMaxDossierEvidenceEntries, 50);
      expect(regimentCatalog.first.id, 'peasant_levies');
      expect(defaultNamingConfig.gpById('england')?.countryName, 'England');
    });

    test('new split libraries do not use part or part of', () {
      const files = <String>[
        'ai_parameter_victory_config_params_declare_war.dart',
        'ai_personality_types.dart',
        'ai_personality_tables.dart',
        'ai_personality_lookup.dart',
        'ai_dossier_config.dart',
        'naming_default_great_powers.dart',
        'naming_default_minors.dart',
        'naming_default_tribes.dart',
        'combat_regiment_catalog_era1.dart',
        'combat_regiment_catalog_era2.dart',
        'combat_regiment_catalog_era3.dart',
        'combat_regiment_catalog_era4.dart',
      ];
      for (final name in files) {
        expect(_hasPartDirective(_srcFile(name)), isFalse, reason: name);
      }
    });
  });
}
