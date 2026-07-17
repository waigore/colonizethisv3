import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_bid_treasury_spend_shared.dart';

const _helperRelative =
    'packages/colonizethis_economy/lib/src/economy/world_market/treasury_bid_spend.dart';
const _consumerRelative =
    'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_validator.dart';

const _helperSource = r'''
int bidTreasurySpendForOrder({required int quantity, required int? unitPrice}) {
  return quantity * (unitPrice ?? 0);
}
''';

const _delegatingConsumerSource = r'''
import 'treasury_bid_budget.dart';

int validate() {
  return bidTreasurySpendForOrder(quantity: 2, unitPrice: 3);
}
''';

const _reInlinedConsumerSource = r'''
int validate() {
  return quantity * unitPrice;
}
''';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyBidTreasurySpendShared', () {
    test('passes when validator delegates to bidTreasurySpendForOrder', () {
      final root = Directory.systemTemp.createTempSync('bid_spend_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _consumerRelative, _delegatingConsumerSource);

      final logs = <String>[];
      final code = runCheckEconomyBidTreasurySpendShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when helper module no longer defines the shared symbol', () {
      final root = Directory.systemTemp.createTempSync('bid_spend_no_sym');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, 'int unrelated() => 0;\n');
      _writeFile(root, _consumerRelative, _delegatingConsumerSource);

      final logs = <String>[];
      final code = runCheckEconomyBidTreasurySpendShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('no longer defines'));
    });

    test('fails when validator re-inlines bid spend math', () {
      final root = Directory.systemTemp.createTempSync('bid_spend_inline');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _consumerRelative, _reInlinedConsumerSource);

      final logs = <String>[];
      final code = runCheckEconomyBidTreasurySpendShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('must import treasury_bid_budget.dart'));
    });

    test('passes on the current repo tree', () {
      final logs = <String>[];
      final code = runCheckEconomyBidTreasurySpendShared(
        '.',
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
