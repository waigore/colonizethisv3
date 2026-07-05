import 'dart:io';

import 'package:path/path.dart' as p;

const _standardWorkHandlerRelative =
    'packages/colonizethis_orders/lib/src/orders/work_handlers/standard_work_handler.dart';

const _workHandlersDir =
    'packages/colonizethis_orders/lib/src/orders/work_handlers';

/// Ensures [standard_work_handler.dart] keeps the declarative target-kind table
/// and does not reintroduce the legacy builder-map pattern (Refs #3877).
int runCheckOrdersStandardWorkDeclarativeConfig(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final handlerFile = File(p.join(root, _standardWorkHandlerRelative));
  if (!handlerFile.existsSync()) {
    logE(
      'check_orders_standard_work_declarative_config: missing '
      '$_standardWorkHandlerRelative',
    );
    return 1;
  }

  final violations = <String>[];

  final handlerSource = handlerFile.readAsStringSync();
  if (!handlerSource.contains('_standardWorkTargetKinds')) {
    violations.add(
      '$_standardWorkHandlerRelative must declare _standardWorkTargetKinds',
    );
  }
  if (!handlerSource.contains('_buildStandardWorkTargetConfig')) {
    violations.add(
      '$_standardWorkHandlerRelative must declare '
      '_buildStandardWorkTargetConfig',
    );
  }

  final workHandlersDir = Directory(p.join(root, _workHandlersDir));
  for (final entity in workHandlersDir.listSync(recursive: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    final source = entity.readAsStringSync();
    if (source.contains('_standardWorkTargetConfigBuilders')) {
      violations.add(
        '$relativePath: legacy _standardWorkTargetConfigBuilders map is '
        'forbidden; use _standardWorkTargetKinds + '
        '_buildStandardWorkTargetConfig',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_orders_standard_work_declarative_config: passed.');
    return 0;
  }

  logE(
    'check_orders_standard_work_declarative_config: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersStandardWorkDeclarativeConfig(Directory.current.path));
}
