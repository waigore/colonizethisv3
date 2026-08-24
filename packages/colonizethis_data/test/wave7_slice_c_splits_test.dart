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
  group('wave 7 Slice C splits (Refs #4626 AC6–AC7)', () {
    test('near-cap victory-config files are family-split without part', () {
      const files = <String>[
        'ai_parameter_victory_config_params_military_stall.dart',
        'ai_parameter_victory_config_params_quota_offer_peace.dart',
        'ai_parameter_victory_config_params_observer_colonial_lite.dart',
        'ai_parameter_victory_config_params_offer_peace_exhausted.dart',
        'ai_parameter_victory_config_params_defend_few_ow.dart',
        'ai_parameter_victory_config_params_colonial_overture.dart',
        'ai_parameter_victory_config_params_colonial_naval.dart',
        'ai_parameter_victory_config_params_colonial_pressure.dart',
        'ai_parameter_victory_config_params_colonial_conquest.dart',
        'ai_parameter_victory_config_params_declare_war_gp.dart',
        'ai_parameter_victory_config_params_declare_war_minor.dart',
        'tech_catalog_chunks_new_world_plantations.dart',
        'tech_catalog_chunks_new_world_harvest_ore.dart',
      ];
      final names = _srcNames();
      for (final name in files) {
        expect(names.contains(name), isTrue, reason: name);
        expect(_hasPartDirective(_srcFile(name)), isFalse, reason: name);
      }
    });

    test('leftover colonial and overture rows left the stall grab-bag', () {
      final stallBag = _srcFile(
        'ai_parameter_victory_config_params_military_stall_colonial.dart',
      ).readAsStringSync();
      expect(stallBag.contains('kColonialExpandBonusWhenInvadableNw'), isFalse);
      expect(
        stallBag.contains('kEstablishOvertureColonialTribeBonus'),
        isFalse,
      );
      expect(stallBag.contains('kObserverColonialLiteMinTurn'), isFalse);
      expect(
        _paramNamesIn(
          _srcFile(
            'ai_parameter_victory_config_params_observer_colonial_lite.dart',
          ),
        ).contains('kObserverColonialLiteMinTurn'),
        isTrue,
      );
      expect(
        _paramNamesIn(
          _srcFile('ai_parameter_victory_config_params_colonial_overture.dart'),
        ).contains('kEstablishOvertureColonialTribeBonus'),
        isTrue,
      );
    });

    test(
      'new-world catalog assembler delegates to plantation and harvest files',
      () {
        final assembler = _srcFile(
          'tech_catalog_chunks_new_world.dart',
        ).readAsStringSync();
        expect(assembler.contains('addTechCatalogNewWorldPlantations'), isTrue);
        expect(
          assembler.contains('addTechCatalogNewWorldHarvestAndOre'),
          isTrue,
        );
        expect(assembler.contains("category: 'new-world'"), isFalse);
        expect(
          _srcFile(
            'tech_catalog_chunks_new_world_plantations.dart',
          ).readAsStringSync(),
          contains('kTechIdDiscoveryOfSugar'),
        );
        expect(
          _srcFile(
            'tech_catalog_chunks_new_world_harvest_ore.dart',
          ).readAsStringSync(),
          contains('kTechIdDiscoveryOfFurs'),
        );
      },
    );

    test('victoryConfigParams order and public catalog API stay stable', () {
      final names = AiParameterRegistry.byCategory(
        AiParameterCategory.victoryConfig,
      ).map((p) => p.name).toList();
      expect(names.toSet().length, names.length);
      expect(
        names.indexOf('kStalledOldWorldProvinceThreshold'),
        lessThan(names.indexOf('kObserverColonialLiteMinTurn')),
      );
      expect(
        names.indexOf('kObserverColonialLiteMinTurn'),
        lessThan(names.indexOf('kColonialExpandBonusWhenInvadableNw')),
      );
      expect(
        names.indexOf('kColonialExpandBonusWhenInvadableNw'),
        lessThan(names.indexOf('kConquestArmyMoveNwInvadableBonus')),
      );
      expect(techCatalog.length, 113);
      expect(
        techCatalog.values.where((t) => t.category == 'new-world').length,
        28,
      );
    });
  });
}
