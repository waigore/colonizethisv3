// Refs #3731 — guards `repo.economy_dedup_credit_aggregation` enforcement.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_dedup_credit_aggregation.dart';

void main() {
  group('findEconomyDedupCreditAggregationViolations', () {
    const frrPath =
        'packages/colonizethis_economy/lib/src/economy/world_market/first_right_credits.dart';
    const richesPath =
        'packages/colonizethis_economy/lib/src/economy/world_market/purchased_tile_riches.dart';

    String compliant(String body) =>
        'final acc = GpTreasuryCreditAccumulator<int>(0);\n$body\n';

    test('accepts files that delegate to the shared accumulator', () {
      final violations = findEconomyDedupCreditAggregationViolations(
        sourcesByPath: {
          frrPath: compliant('acc.add(gpId, delta);'),
          richesPath: compliant('acc.ensure(gpId);'),
        },
      );
      expect(violations, isEmpty);
    });

    test('flags a re-inlined single-line per-GP accumulation (int zero)', () {
      const src = '''
final byGp = <String, int>{};
byGp[gpId] = (byGp[gpId] ?? 0) + delta;
''';
      final violations = findEconomyDedupCreditAggregationViolations(
        sourcesByPath: {frrPath: src},
      );
      // Inline loop + missing accumulator reference => two violations.
      expect(violations, hasLength(2));
      expect(
        violations.map((v) => v.message).join('\n'),
        contains('GpTreasuryCreditAccumulator'),
      );
    });

    test('flags the two-line split accumulation (double zero) form', () {
      final src = compliant('''
treasuryByGp[owningGpId] =
    (treasuryByGp[owningGpId] ?? 0.0) + profit.profitTreasury;''');
      final violations = findEconomyDedupCreditAggregationViolations(
        sourcesByPath: {richesPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('Re-inlined'));
    });

    test('flags a file that abandons the shared accumulator reference', () {
      const src = 'final byGp = <String, int>{};\n';
      final violations = findEconomyDedupCreditAggregationViolations(
        sourcesByPath: {frrPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('Missing reference'));
    });

    test('only checks the two target files', () {
      const otherPath =
          'packages/colonizethis_economy/lib/src/economy/sea_transport.dart';
      const src = 'delivered[id] = (delivered[id] ?? 0) + take;\n';
      final violations = findEconomyDedupCreditAggregationViolations(
        sourcesByPath: const {otherPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live economy source tree', () {
      final code = runCheckEconomyDedupCreditAggregation(
        _repoRoot(),
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('runCheck returns 1 on a temp tree with a reintroduced loop', () {
      final temp = Directory.systemTemp.createTempSync('econ_credit_dedup_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final wm = Directory(
        p.join(
          temp.path,
          'packages/colonizethis_economy/lib/src/economy/world_market',
        ),
      )..createSync(recursive: true);
      File(p.join(wm.path, 'first_right_credits.dart')).writeAsStringSync(
        'final byGp = <String, double>{};\n'
        'byGp[gpId] = (byGp[gpId] ?? 0.0) + profit;\n',
      );
      File(p.join(wm.path, 'purchased_tile_riches.dart')).writeAsStringSync(
        'final acc = GpTreasuryCreditAccumulator<int>(0);\n'
        'acc.add(gpId, delta);\n',
      );
      final errLogs = <String>[];
      final code = runCheckEconomyDedupCreditAggregation(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );
      expect(code, 1);
      expect(errLogs.join('\n'), contains('first_right_credits.dart'));
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
