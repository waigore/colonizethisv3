import 'dart:io';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

const _sliceBDeletedExpectationFiles = {
  'town_manufacturing_bonus_expectations.dart',
  'resource_extractor_expectations.dart',
  'non_gp_auto_offers_expectations.dart',
  'province_extraction_snapshot_expectations.dart',
};

String _basename(String path) => path.replaceAll(r'\', '/').split('/').last;

Directory _supportLibDir() {
  final fromPackage = Directory('lib');
  if (fromPackage.existsSync()) {
    return fromPackage;
  }
  final fromRepo = Directory('packages/colonizethis_economy_test_support/lib');
  if (fromRepo.existsSync()) {
    return fromRepo;
  }
  throw StateError('could not find colonizethis_economy_test_support/lib');
}

List<String> _libFilesContaining(String needle) {
  return _supportLibDir()
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => file.readAsStringSync().contains(needle))
      .map((file) => _basename(file.path))
      .toList();
}

void main() {
  group('Wave 2 Slice B leftover merge (Refs #4410)', () {
    test('public pin types remain importable from the package barrel', () {
      const town = TownManufacturingBonusProvinceExpectation(isEmpty: true);
      const extractor = ResourceExtractorExpectation(landEmpty: true);
      const autoOffers = NonGpAutoOffersExpectation(empty: true);
      expect(town.isEmpty, isTrue);
      expect(extractor.landEmpty, isTrue);
      expect(autoOffers.empty, isTrue);
      expect(ProvinceImprovableCountsPin.emptyWhenFullyImproved, isNotNull);
    });

    test('Slice B leftover *_expectations.dart modules are gone', () {
      final leftover = _supportLibDir()
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => _basename(file.path))
          .where(_sliceBDeletedExpectationFiles.contains)
          .toList();
      expect(leftover, isEmpty);
    });

    test('support lib no longer owns runTownManufacturingBonusGamePin', () {
      expect(_libFilesContaining('runTownManufacturingBonusGamePin'), isEmpty);
    });

    test('support lib no longer owns runResourceExtractorScenario', () {
      expect(_libFilesContaining('runResourceExtractorScenario'), isEmpty);
    });
  });
}
