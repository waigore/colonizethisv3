import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_bid_quantity_cap_shared.dart';

const _helperRelative =
    'packages/colonizethis_economy/lib/src/economy/world_market/treasury_bid_budget.dart';
const _consumerRelative =
    'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_suggester.dart';

const _helperSource = r'''
int capBidQuantityForBudgets({
  required int bidQuantity,
  required int remainingCargoBudget,
  required int remainingTreasuryBudget,
  required int? unitPrice,
}) {
  return bidQuantity;
}
''';

const _delegatingSource = r'''
import 'treasury_bid_budget.dart';

void suggest() {
  capBidQuantityForBudgets(
    bidQuantity: 1,
    remainingCargoBudget: 1,
    remainingTreasuryBudget: 1,
    unitPrice: 1,
  );
}
''';

const _reInlinedSource = r'''
void suggest() {
  final maxAffordable = remainingTreasuryBudget ~/ unitPrice;
}
''';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyBidQuantityCapShared', () {
    test('passes when suggester delegates to capBidQuantityForBudgets', () {
      final root = Directory.systemTemp.createTempSync('bid_cap_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _consumerRelative, _delegatingSource);

      final logs = <String>[];
      final code = runCheckEconomyBidQuantityCapShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when lib re-inlines treasury affordability math', () {
      final root = Directory.systemTemp.createTempSync('bid_cap_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _consumerRelative, _delegatingSource);
      _writeFile(
        root,
        'packages/colonizethis_economy/lib/src/economy/world_market/deal_matcher_indexing.dart',
        _reInlinedSource,
      );

      final logs = <String>[];
      final code = runCheckEconomyBidQuantityCapShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('remainingTreasuryBudget ~/ unitPrice'));
    });
  });
}
