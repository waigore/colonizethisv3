import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_cost_check_shared_helper.dart';

const _helperRelative =
    'packages/colonizethis_economy/lib/src/economy/cost_check.dart';
const _workerRelative =
    'packages/colonizethis_economy/lib/src/economy/worker_action_cost.dart';
const _buildRelative =
    'packages/colonizethis_economy/lib/src/economy/build_cost.dart';

const _helperSource = r'''
String? checkPreconditionsInOrder(List<CostPrecondition> preconditions) {
  for (final precondition in preconditions) {
    if (!precondition.check()) {
      return precondition.failReason;
    }
  }
  return null;
}
''';

const _delegatingSource = r'''
import 'cost_check.dart';

({bool canAfford, String? reason}) canAffordRecruitWorker() {
  final reason = checkPreconditionsInOrder([
    (failReason: 'Required technology not unlocked', check: () => true),
  ]);
  return (canAfford: reason == null, reason: reason);
}
''';

const _reInlinedSource = r'''
({bool canAfford, String? reason}) canAffordRecruitWorker() {
  // Re-inlined the priority-ordered first-failure sweep instead of delegating.
  if (!techOk) return (canAfford: false, reason: 'Required technology not unlocked');
  if (!workersOk) return (canAfford: false, reason: 'Insufficient workers');
  return (canAfford: true, reason: null);
}
''';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyCostCheckSharedHelper', () {
    test('passes when both consumers delegate to checkPreconditionsInOrder', () {
      final root = Directory.systemTemp.createTempSync('cost_check_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _workerRelative, _delegatingSource);
      _writeFile(root, _buildRelative, _delegatingSource);

      final logs = <String>[];
      final code = runCheckEconomyCostCheckSharedHelper(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a consumer re-inlines the first-failure sweep', () {
      final root = Directory.systemTemp.createTempSync('cost_check_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _workerRelative, _delegatingSource);
      _writeFile(root, _buildRelative, _reInlinedSource);

      final logs = <String>[];
      final code = runCheckEconomyCostCheckSharedHelper(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('checkPreconditionsInOrder'));
      expect(logs.join('\n'), contains('build_cost.dart'));
    });

    test('fails when the shared helper definition disappears', () {
      final root = Directory.systemTemp.createTempSync('cost_check_no_helper');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, '// helper removed\n');
      _writeFile(root, _workerRelative, _delegatingSource);
      _writeFile(root, _buildRelative, _delegatingSource);

      final logs = <String>[];
      final code = runCheckEconomyCostCheckSharedHelper(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('no longer defines'));
    });

    test('fails when a consumer file is missing', () {
      final root = Directory.systemTemp.createTempSync('cost_check_missing');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _workerRelative, _delegatingSource);

      final logs = <String>[];
      final code = runCheckEconomyCostCheckSharedHelper(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('Missing cost-check consumer'));
    });
  });
}
