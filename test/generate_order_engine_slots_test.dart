import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('OrderEngine slot generator is idempotent', () {
    final root = _repoRoot();
    final gPath = p.join(
      root,
      'packages',
      'colonizethis_orders',
      'lib',
      'src',
      'orders',
      'order_engine.g.dart',
    );
    final before = File(gPath).readAsStringSync();
    final result = Process.runSync('dart', [
      'run',
      'tool/generate_order_engine_slots.dart',
    ], workingDirectory: root);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    final after = File(gPath).readAsStringSync();
    expect(after, before);
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final text = pubspec.readAsStringSync();
      if (text.contains('name: colonizethis') && text.contains('workspace:')) {
        return dir.path;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  throw StateError('Could not find repo root from ${Directory.current.path}');
}
