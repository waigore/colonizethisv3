import 'dart:io';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

const _sliceADeletedExpectationFiles = {
  'boycott_blocked_commodities_expectations.dart',
  'lock_recovery_minor_bids_expectations.dart',
  'world_market_context_base_expectations.dart',
  'price_discovery_expectations.dart',
  'game_lookup_helpers_expectations.dart',
  'frr_profit_expectations.dart',
  'non_gp_extraction_expectations.dart',
  'development_panel_read_model_expectations.dart',
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

void main() {
  group('Wave 2 Slice A leftover merge (Refs #4410)', () {
    test('public pin types remain importable from the package barrel', () {
      const boycott = BoycottBlockedCommoditiesExpectation(isEmpty: true);
      const lock = LockRecoveryMinorBidsExpectation(isEmpty: true);
      const context = WorldMarketContextBaseExpectation(stockpileEmpty: true);
      const activity = PriceDiscoveryMarketActivityExpectation(
        equalsEmpty: true,
      );
      const index = BuildProvinceIndexExpectation(isEmpty: true);
      const frr = FrrProfitExpectation(expectZero: true);
      const nonGp = NonGpExtractionExpectation(empty: true);
      expect(boycott.isEmpty, isTrue);
      expect(lock.isEmpty, isTrue);
      expect(context.stockpileEmpty, isTrue);
      expect(activity.equalsEmpty, isTrue);
      expect(index.isEmpty, isTrue);
      expect(frr.expectZero, isTrue);
      expect(nonGp.empty, isTrue);
    });

    test('Slice A leftover *_expectations.dart modules are gone', () {
      final leftover = _supportLibDir()
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => _basename(file.path))
          .where(_sliceADeletedExpectationFiles.contains)
          .toList();
      expect(leftover, isEmpty);
    });

    test(
      'support lib no longer owns runDevelopmentPanelReadModelExpectation',
      () {
        final hits = _supportLibDir()
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where(
              (file) => file.readAsStringSync().contains(
                'runDevelopmentPanelReadModelExpectation',
              ),
            )
            .map((file) => _basename(file.path))
            .toList();
        expect(hits, isEmpty);
      },
    );
  });
}
