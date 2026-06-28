import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_work_target_switch.dart';

/// Tests for the `repo.logic_work_target_switch` repo-lint rule
/// (SPEC/program/orders.md § Work-order handler registry, Refs #2560).
void main() {
  group('check_logic_work_target_switch', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckLogicWorkTargetSwitch(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(logs.join('\n'), contains('no violations found'));
    });

    test(
        'fails when a work-handlers file enumerates >= 3 `kWorkTarget*` '
        'constants in a switch statement', () {
      final temp = _seedFakeRepo();
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeOrderVisibility(temp, _emptyOrderVisibilityStub());
      _writeWorkHandler(
        temp,
        'standard_work_handler.dart',
        _switchStatementOverThreeWorkTargets(),
      );

      final logs = <String>[];
      final err = <String>[];
      final code = runCheckLogicWorkTargetSwitch(
        temp.path,
        info: logs.add,
        err: err.add,
      );

      expect(code, 1, reason: '${logs.join('\n')}\n${err.join('\n')}');
      final allErr = err.join('\n');
      expect(allErr, contains('standard_work_handler.dart'));
      expect(allErr, contains('switch enumerates 3 work-target constants'));
      expect(allErr, contains('workOrderHandlersByTarget'));
    });

    test(
        'fails when `order_visibility.dart` uses a switch expression over '
        '>= 3 `kWorkTarget*` constants', () {
      final temp = _seedFakeRepo();
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeOrderVisibility(temp, _switchExpressionOverFourWorkTargets());
      _writeWorkHandler(
        temp,
        'standard_work_handler.dart',
        _registryStyleWorkHandlerFile(),
      );

      final logs = <String>[];
      final err = <String>[];
      final code = runCheckLogicWorkTargetSwitch(
        temp.path,
        info: logs.add,
        err: err.add,
      );

      expect(code, 1, reason: '${logs.join('\n')}\n${err.join('\n')}');
      expect(err.join('\n'), contains('order_visibility.dart'));
      expect(err.join('\n'), contains('_workOrderVisibilityByTarget'));
    });

    test(
        'passes when a work-handlers file branches on only two work targets '
        '(below the enumeration threshold)', () {
      final temp = _seedFakeRepo();
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeOrderVisibility(temp, _emptyOrderVisibilityStub());
      _writeWorkHandler(
        temp,
        'standard_work_handler.dart',
        _switchStatementOverTwoWorkTargets(),
      );

      final logs = <String>[];
      final err = <String>[];
      final code = runCheckLogicWorkTargetSwitch(
        temp.path,
        info: logs.add,
        err: err.add,
      );

      expect(code, 0, reason: '${logs.join('\n')}\n${err.join('\n')}');
      expect(logs.join('\n'), contains('no violations found'));
    });

    test(
        'passes when work-target dispatch is expressed via the canonical '
        'registry map (no `switch` enumeration at all)', () {
      final temp = _seedFakeRepo();
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeOrderVisibility(temp, _emptyOrderVisibilityStub());
      _writeWorkHandler(
        temp,
        'work_order_handler_registry.dart',
        _registryStyleWorkHandlerFile(),
      );

      final logs = <String>[];
      final err = <String>[];
      final code = runCheckLogicWorkTargetSwitch(
        temp.path,
        info: logs.add,
        err: err.add,
      );

      expect(code, 0, reason: '${logs.join('\n')}\n${err.join('\n')}');
      expect(logs.join('\n'), contains('no violations found'));
    });

    test(
        'fails when the scoped paths are missing (so wiring regressions are '
        'caught early)', () {
      final temp = Directory.systemTemp.createTempSync(
        'logic_work_target_switch_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final err = <String>[];
      final code = runCheckLogicWorkTargetSwitch(
        temp.path,
        info: (_) {},
        err: err.add,
      );

      expect(code, 1);
      expect(err.join('\n'), contains('scoped paths not found'));
    });
  });
}

Directory _seedFakeRepo() {
  final temp = Directory.systemTemp.createTempSync(
    'logic_work_target_switch_',
  );
  _workHandlersDirIn(temp).createSync(recursive: true);
  return temp;
}

Directory _workHandlersDirIn(Directory repo) => Directory(
      p.join(
        repo.path,
        'packages',
        'colonizethis_orders',
        'lib',
        'src',
        'orders',
        'work_handlers',
      ),
    );

File _orderVisibilityFileIn(Directory repo) => File(
      p.join(
        repo.path,
        'packages',
        'colonizethis_orders',
        'lib',
        'src',
        'orders',
        'order_visibility.dart',
      ),
    );

void _writeOrderVisibility(Directory repo, String contents) {
  _orderVisibilityFileIn(repo).writeAsStringSync(contents);
}

void _writeWorkHandler(Directory repo, String fileName, String contents) {
  File(p.join(_workHandlersDirIn(repo).path, fileName))
      .writeAsStringSync(contents);
}

String _switchStatementOverThreeWorkTargets() => '''
const String kWorkTargetBuildRoad = 'build_road';
const String kWorkTargetBuildPort = 'build_port';
const String kWorkTargetBuildFort = 'build_fort';

bool isBuildTarget(String target) {
  switch (target) {
    case kWorkTargetBuildRoad:
      return true;
    case kWorkTargetBuildPort:
      return true;
    case kWorkTargetBuildFort:
      return true;
  }
  return false;
}
''';

String _switchExpressionOverFourWorkTargets() => '''
const String kWorkTargetBuildImprovement = 'build_improvement';
const String kWorkTargetBuildRoad = 'build_road';
const String kWorkTargetBuildPort = 'build_port';
const String kWorkTargetUpgradeTown = 'upgrade_town';

bool isVisibleForOwner(String target) => switch (target) {
      kWorkTargetBuildImprovement => true,
      kWorkTargetBuildRoad => true,
      kWorkTargetBuildPort => true,
      kWorkTargetUpgradeTown => true,
      _ => false,
    };
''';

String _switchStatementOverTwoWorkTargets() => '''
const String kWorkTargetBuildRoad = 'build_road';
const String kWorkTargetBuildPort = 'build_port';

bool isBuildLikeTarget(String target) {
  switch (target) {
    case kWorkTargetBuildRoad:
      return true;
    case kWorkTargetBuildPort:
      return true;
  }
  return false;
}
''';

String _registryStyleWorkHandlerFile() => '''
const String kWorkTargetBuildRoad = 'build_road';
const String kWorkTargetBuildPort = 'build_port';
const String kWorkTargetBuildFort = 'build_fort';

abstract interface class WorkOrderHandler {
  bool tryApply();
}

const WorkOrderHandler roadHandler = _Stub();
const WorkOrderHandler portHandler = _Stub();
const WorkOrderHandler fortHandler = _Stub();

final Map<String, WorkOrderHandler> workOrderHandlersByTarget =
    <String, WorkOrderHandler>{
  kWorkTargetBuildRoad: roadHandler,
  kWorkTargetBuildPort: portHandler,
  kWorkTargetBuildFort: fortHandler,
};

WorkOrderHandler? handlerFor(String target) =>
    workOrderHandlersByTarget[target];

class _Stub implements WorkOrderHandler {
  const _Stub();
  @override
  bool tryApply() => false;
}
''';

String _emptyOrderVisibilityStub() => '''
// Stub order_visibility.dart for fixture; the real file uses
// `_workOrderVisibilityByTarget` map dispatch (see SPEC/program/orders.md).
bool workOrderVisibilityOk(Object view, Object unit, String target) => false;
''';
