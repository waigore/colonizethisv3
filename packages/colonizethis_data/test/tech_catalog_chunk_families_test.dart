import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

/// GDD category-family chunk files (Refs #4412 AC4).
const _expectedChunkFiles = <String>{
  'tech_catalog_chunks_gathering.dart',
  'tech_catalog_chunks_new_world.dart',
  'tech_catalog_chunks_new_world_plantations.dart',
  'tech_catalog_chunks_new_world_harvest_ore.dart',
  'tech_catalog_chunks_transport.dart',
  'tech_catalog_chunks_labour.dart',
  'tech_catalog_chunks_diplomacy_civilian.dart',
  'tech_catalog_chunks_naval.dart',
  'tech_catalog_chunks_military_infantry.dart',
  'tech_catalog_chunks_military_cavalry.dart',
  'tech_catalog_chunks_military_artillery.dart',
};

const _retiredMixedChunkFiles = <String>{
  'tech_catalog_chunks.dart',
  'tech_catalog_chunks_economy.dart',
};

const _singleCategoryByFile = <String, String>{
  'tech_catalog_chunks_gathering.dart': 'gathering',
  'tech_catalog_chunks_new_world_plantations.dart': 'new-world',
  'tech_catalog_chunks_new_world_harvest_ore.dart': 'new-world',
  'tech_catalog_chunks_transport.dart': 'transport',
  'tech_catalog_chunks_labour.dart': 'labour',
  'tech_catalog_chunks_naval.dart': 'naval',
  'tech_catalog_chunks_military_infantry.dart': 'military',
  'tech_catalog_chunks_military_cavalry.dart': 'military',
  'tech_catalog_chunks_military_artillery.dart': 'military',
};

final _categoryLiteral = RegExp(r"category: '([^']+)'");

List<File> _chunkFiles() {
  final dir = Directory('lib/src');
  return dir.listSync().whereType<File>().where((f) {
    final name = f.uri.pathSegments.last;
    return name.startsWith('tech_catalog_chunks') && name.endsWith('.dart');
  }).toList()..sort((a, b) => a.path.compareTo(b.path));
}

Set<String> _categoriesIn(File file) {
  return _categoryLiteral
      .allMatches(file.readAsStringSync())
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  group('tech catalog GDD category families (Refs #4412 AC4)', () {
    test('chunk files match the GDD family map and drop mixed leftovers', () {
      final names = _chunkFiles().map((f) => f.uri.pathSegments.last).toSet();
      expect(names, equals(_expectedChunkFiles));
      for (final retired in _retiredMixedChunkFiles) {
        expect(names.contains(retired), isFalse, reason: retired);
      }
    });

    test('each family file has one category except diplomacy+civilian', () {
      for (final file in _chunkFiles()) {
        final name = file.uri.pathSegments.last;
        final categories = _categoriesIn(file);
        if (name == 'tech_catalog_chunks_diplomacy_civilian.dart') {
          expect(categories, equals({'diplomacy', 'civilian'}));
          continue;
        }
        if (name == 'tech_catalog_chunks_new_world.dart') {
          expect(categories, isEmpty, reason: name);
          continue;
        }
        expect(categories, equals({_singleCategoryByFile[name]}), reason: name);
      }
    });

    test('all 28 new-world rows live in plantation and harvest/ore files', () {
      final plantations = File(
        'lib/src/tech_catalog_chunks_new_world_plantations.dart',
      );
      final harvestOre = File(
        'lib/src/tech_catalog_chunks_new_world_harvest_ore.dart',
      );
      expect(plantations.existsSync(), isTrue);
      expect(harvestOre.existsSync(), isTrue);
      int countIn(File file) => _categoryLiteral
          .allMatches(file.readAsStringSync())
          .where((m) => m.group(1) == 'new-world')
          .length;
      expect(countIn(plantations), equals(15));
      expect(countIn(harvestOre), equals(13));
      const family = {
        'tech_catalog_chunks_new_world_plantations.dart',
        'tech_catalog_chunks_new_world_harvest_ore.dart',
      };
      for (final file in _chunkFiles()) {
        final name = file.uri.pathSegments.last;
        if (family.contains(name)) {
          continue;
        }
        expect(
          _categoriesIn(file).contains('new-world'),
          isFalse,
          reason: name,
        );
      }
    });

    test('buildTechCatalog still returns 113 techs', () {
      expect(techCatalog.length, equals(113));
    });

    test('chunk files do not use part or part of', () {
      for (final file in _chunkFiles()) {
        for (final line in file.readAsLinesSync()) {
          final trimmed = line.trimLeft();
          expect(trimmed.startsWith('part '), isFalse, reason: file.path);
          expect(trimmed.startsWith('part of '), isFalse, reason: file.path);
        }
      }
    });
  });
}
