// Forbids `colonizethis_orders/lib` from deep-importing another colonizethis
// package's private `lib/src/**` tree (Refs #3543). Cross-package symbols must
// be consumed through the owning package's public barrel
// (`package:colonizethis_<pkg>/colonizethis_<pkg>.dart`); reaching into a
// sibling package's `src/` directory breaks its encapsulation boundary.
//
// Self-imports of `package:colonizethis_orders/src/...` are out of scope (a
// package may reference its own internals), as are relative imports.
import 'dart:io';

import 'package:path/path.dart' as p;

const _ordersLibRelative = 'packages/colonizethis_orders/lib';

/// Matches `import 'package:colonizethis_<pkg>/<path>'`, capturing the package
/// short name (`<pkg>`) and the in-package path (`<path>`).
final _packageImport = RegExp(
  r"import\s+'package:colonizethis_([a-z_]+)/([^']+)'",
);

void main() {
  exit(runCheckOrdersNoCrossPackageSrcImports(Directory.current.path));
}

/// Returns 0 when no `colonizethis_orders/lib` file deep-imports another
/// colonizethis package's `src/` tree; 1 otherwise (or when the lib tree is
/// missing).
int runCheckOrdersNoCrossPackageSrcImports(
  String repoRoot, {
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _ordersLibRelative));
  if (!libDir.existsSync()) {
    logE('check_orders_no_cross_package_src_imports: missing $_ordersLibRelative');
    return 1;
  }

  final violations = <String>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (_isGenerated(entity.path)) continue;
    final relative = p.relative(entity.path, from: repoRoot);
    for (final match in _packageImport.allMatches(entity.readAsStringSync())) {
      final pkg = match.group(1)!;
      final inPackagePath = match.group(2)!;
      if (pkg == 'orders') continue;
      if (inPackagePath == 'src' || inPackagePath.startsWith('src/')) {
        violations.add('$relative -> package:colonizethis_$pkg/$inPackagePath');
      }
    }
  }

  if (violations.isEmpty) {
    return 0;
  }

  logE(
    'check_orders_no_cross_package_src_imports: '
    'colonizethis_orders/lib must not import another package\'s src/ tree '
    '(use the owning package barrel):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');
