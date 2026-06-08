import 'dart:io';

import 'package:path/path.dart' as p;

const _guardedRelativePaths = <String>{
  'packages/colonizethis_orders/lib/src/orders/orders_application.dart',
  'packages/colonizethis_world/lib/src/world/fog_resolution.dart',
  'packages/colonizethis_world/lib/src/world/fog_resolution_explorer_spy_decay.dart',
  'packages/colonizethis_world/lib/src/world/fog_resolution_province_ownership.dart',
  'packages/colonizethis_world/lib/src/world/fog_resolution_coastal_sea_zone.dart',
  'packages/colonizethis_world/lib/src/world/fog_resolution_distant_sea_zone.dart',
  'packages/colonizethis_logic/lib/src/turn/turn_news_digest.dart',
};

final RegExp _localProvinceLookupPattern = RegExp(
  r'tileKeysByRegionAndProvince\s*\[[^\]]+\]\?\s*\[\s*(?:ProvinceId\.localIdFrom\(|local[A-Za-z0-9_]*)',
);

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckLandProvinceBucketKeys(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final violations = <LandProvinceBucketKeyViolation>[];

  for (final relativePath in _guardedRelativePaths) {
    final file = File(p.join(root, relativePath));
    if (!file.existsSync()) {
      continue;
    }
    final source = file.readAsStringSync();
    violations.addAll(
      findLandProvinceBucketKeyViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Land-province bucket key check passed.');
    return 0;
  }

  logE(
    'ERROR: Found local-only land-province bucket lookups in guarded paths. '
    'Use canonical full province id (regionId|localId) lookups only.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckLandProvinceBucketKeys(Directory.current.path));
}

List<LandProvinceBucketKeyViolation> findLandProvinceBucketKeyViolations({
  required String relativePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <LandProvinceBucketKeyViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_localProvinceLookupPattern.hasMatch(line)) {
      violations.add(
        LandProvinceBucketKeyViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Local-only land-province bucket key lookup detected; use full province id bucket.',
        ),
      );
    }
  }
  return violations;
}

class LandProvinceBucketKeyViolation {
  const LandProvinceBucketKeyViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
