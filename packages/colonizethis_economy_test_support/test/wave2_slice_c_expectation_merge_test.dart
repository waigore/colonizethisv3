import 'dart:io';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

const _sliceCDeletedExpectationFiles = {
  'deal_matcher_expectations.dart',
  'validator_expectations.dart',
  'treasury_expectations.dart',
  'treasury_player_context_expectations.dart',
  'trade_order_suggester_expectations.dart',
  'purchased_tile_expectations.dart',
  'frr_credits_expectations.dart',
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
  group('Wave 2 Slice C leftover merge (Refs #4410)', () {
    test('public pin types remain importable from the package barrel', () {
      const deal = DealMatchExpectation(filledDealsEmpty: true);
      const validator = ValidatorExpectation(resultsEmpty: true);
      const treasury = TreasuryAvailableExpectation();
      const suggester = SuggesterExpectation(isEmpty: true);
      const index = PurchasedTileIndexExpectation(isEmpty: true);
      const riches = PurchasedTileRichesExpectation(creditsEmpty: true);
      const frr = FrrCreditsExpectation(empty: true);
      const player = PlayerContextExpectation(
        target: PlayerContextScenarioTarget.snapshot,
      );
      expect(deal.filledDealsEmpty, isTrue);
      expect(validator.resultsEmpty, isTrue);
      expect(treasury.omitProjectedDeltaAlias, isFalse);
      expect(suggester.isEmpty, isTrue);
      expect(index.isEmpty, isTrue);
      expect(riches.creditsEmpty, isTrue);
      expect(frr.empty, isTrue);
      expect(player.target, PlayerContextScenarioTarget.snapshot);
    });

    test('Slice C leftover *_expectations.dart modules are gone', () {
      final leftover = _supportLibDir()
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => _basename(file.path))
          .where(_sliceCDeletedExpectationFiles.contains)
          .toList();
      expect(leftover, isEmpty);
    });

    test('support lib has no remaining *_expectations.dart modules', () {
      final leftover = _supportLibDir()
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => _basename(file.path))
          .where((name) => name.endsWith('_expectations.dart'))
          .toList();
      expect(leftover, isEmpty);
    });
  });
}
