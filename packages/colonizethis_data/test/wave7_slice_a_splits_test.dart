import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
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

void main() {
  group('wave 7 Slice A splits (Refs #4626 AC1–AC3)', () {
    test('advanced-start tables are topic-split without part directives', () {
      const files = <String>[
        'advanced_start_tech_tables.dart',
        'advanced_start_force_tables.dart',
        'advanced_start_nw_tables.dart',
        'advanced_start_developable_resources.dart',
      ];
      final names = _srcNames();
      for (final name in files) {
        expect(names.contains(name), isTrue, reason: name);
        expect(_hasPartDirective(_srcFile(name)), isFalse, reason: name);
      }
      expect(
        _srcFile('advanced_start_tech_tables.dart').readAsStringSync(),
        contains('validateAdvancedStartTechList'),
      );
      expect(
        _srcFile('advanced_start_force_tables.dart').readAsStringSync(),
        contains('kAdvancedStart50TurnCivilianCounts'),
      );
      expect(
        _srcFile('advanced_start_nw_tables.dart').readAsStringSync(),
        contains('kAdvancedStart100TurnNwColonizationCount'),
      );
    });

    test('developable ids use Resource.name not raw grain/timber keys', () {
      final source = _srcFile(
        'advanced_start_developable_resources.dart',
      ).readAsStringSync();
      expect(source.contains("Resource.grain.name"), isTrue);
      expect(source.contains("Resource.timber.name"), isTrue);
      expect(source.contains("'grain'"), isFalse);
      expect(source.contains("'timber'"), isFalse);
      expect(
        kAdvancedStartDevelopableResourceIds.contains(Resource.grain.name),
        isTrue,
      );
    });

    test('explicit unit-role map keys use kUnitType constants', () {
      final source = _srcFile('unit_roles.dart').readAsStringSync();
      expect(source.contains('kUnitTypeExplorer'), isTrue);
      expect(source.contains("'Explorer'"), isFalse);
      expect(unitRoleForType(kUnitTypeExplorer), UnitRole.explorer);
    });
  });
}
