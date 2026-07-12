import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_deal_matcher_treasury_shared.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyDealMatcherTreasuryShared', () {
    test('passes when matcher delegates to shared treasury helpers', () {
      final root = Directory.systemTemp.createTempSync('economy_matcher_treasury_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/world_market/treasury_bid_budget.dart',
        'int maxAffordableBidQuantity({required int bidRemaining}) => 0;\n'
        'void decrementTreasuryForFill({required String buyerFactionId}) {}\n',
      );
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/world_market/deal_matcher_session.dart',
        'void main() { maxAffordableBidQuantity(bidRemaining: 1); decrementTreasuryForFill(buyerFactionId: "gp1"); }\n',
      );
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/world_market/deal_matcher_indexing.dart',
        '// delegates to treasury_bid_budget.dart\n',
      );

      final logs = <String>[];
      final code = runCheckEconomyDealMatcherTreasuryShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when indexing redefines private treasury helpers', () {
      final root = Directory.systemTemp.createTempSync('economy_matcher_treasury_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/world_market/treasury_bid_budget.dart',
        'int maxAffordableBidQuantity({required int bidRemaining}) => 0;\n'
        'void decrementTreasuryForFill({required String buyerFactionId}) {}\n',
      );
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/world_market/deal_matcher_session.dart',
        'void main() { maxAffordableBidQuantity(bidRemaining: 1); decrementTreasuryForFill(buyerFactionId: "gp1"); }\n',
      );
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/world_market/deal_matcher_indexing.dart',
        'int _maxAffordableQuantity({required int bid}) => 0;\n',
      );

      final logs = <String>[];
      final code = runCheckEconomyDealMatcherTreasuryShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('deal_matcher_indexing.dart'));
    });
  });
}
