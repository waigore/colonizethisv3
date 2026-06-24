import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_world_market_admission_shared.dart';

const _helperRelative =
    'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_admission.dart';
const _validatorRelative =
    'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_validator.dart';
const _suggesterRelative =
    'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_suggester.dart';

const _helperSource = r'''
bool isWorldMarketTradeableCommodity(CommodityId id) => true;
Set<CommodityId> commoditiesWithBidAndOffer(List<TradeOrder> orders) => {};
Set<CommodityId> admittedBidCommodityIdsInSubmissionOrder({
  required List<TradeOrder> proposedOrders,
  required int bidTypeCap,
  required Set<CommodityId> mutuallyExcludedCommodityIds,
}) => {};
''';

const _delegatingConsumer = r'''
import 'trade_order_admission.dart';

void use() {
  isWorldMarketTradeableCommodity('timber');
}
''';

const _nonDelegatingConsumer = r'''
import 'package:colonizethis_data/colonizethis_data.dart' as data;

bool tradeable(String id) => !data.richesCommodityIds.contains(id);
''';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyWorldMarketAdmissionShared', () {
    test('passes when both consumers import the shared module', () {
      final root = Directory.systemTemp.createTempSync('wm_admission_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _validatorRelative, _delegatingConsumer);
      _writeFile(root, _suggesterRelative, _delegatingConsumer);

      final logs = <String>[];
      final code = runCheckEconomyWorldMarketAdmissionShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a consumer drops the shared module import', () {
      final root = Directory.systemTemp.createTempSync('wm_admission_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _validatorRelative, _delegatingConsumer);
      _writeFile(root, _suggesterRelative, _nonDelegatingConsumer);

      final logs = <String>[];
      final code = runCheckEconomyWorldMarketAdmissionShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('trade_order_suggester.dart'));
    });

    test('fails when the shared module loses a canonical helper', () {
      final root = Directory.systemTemp.createTempSync('wm_admission_nohelper');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        _helperRelative,
        'bool isWorldMarketTradeableCommodity(CommodityId id) => true;\n',
      );
      _writeFile(root, _validatorRelative, _delegatingConsumer);
      _writeFile(root, _suggesterRelative, _delegatingConsumer);

      final logs = <String>[];
      final code = runCheckEconomyWorldMarketAdmissionShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('no longer defines'));
    });

    test('fails when a consumer file is missing', () {
      final root = Directory.systemTemp.createTempSync('wm_admission_missing');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _validatorRelative, _delegatingConsumer);

      final logs = <String>[];
      final code = runCheckEconomyWorldMarketAdmissionShared(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('Missing world-market admission'));
    });

    test('passes on the live economy source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckEconomyWorldMarketAdmissionShared(
        repoRoot,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final manifest = File(
      p.join(dir.path, 'tool', 'ct_repo_lint_manifest.yaml'),
    );
    if (manifest.existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
