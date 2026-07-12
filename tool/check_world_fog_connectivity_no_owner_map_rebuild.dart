import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Fog / connectivity lib files must not call [ownerByProvinceIdMap] once
/// [ProvinceOwnerCache] is the ownership SoT (Refs #3978).
const String _worldLibWorldPrefix =
    'packages/colonizethis_world/lib/src/world/';

final RegExp _ownerByProvinceIdMapCall = RegExp(r'\bownerByProvinceIdMap\s*\(');

/// True when [slashPath] is a fog/connectivity world lib file in scope.
bool worldFogConnectivityOwnershipScanPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_worldLibWorldPrefix)) {
    return false;
  }
  final base = p.basename(normalized);
  return base.startsWith('fog_') || base.startsWith('connectivity_');
}

/// Violation reason when [content] rebuilds ownership via the thin map helper.
String? worldFogConnectivityOwnershipScanViolationReason(
  String slashPath,
  String content,
) {
  if (!worldFogConnectivityOwnershipScanPathInScope(slashPath)) {
    return null;
  }
  final code = _stripLineComments(content);
  if (!_ownerByProvinceIdMapCall.hasMatch(code)) {
    return null;
  }
  return 'calls ownerByProvinceIdMap(...); use ProvinceOwnerCache.of instead '
      '(Refs #3978)';
}

String _stripLineComments(String content) {
  final out = StringBuffer();
  for (final line in content.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
      continue;
    }
    out.writeln(line);
  }
  return out.toString();
}

int runCheckWorldFogConnectivityNoOwnerMapRebuild(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final violations = <String>[];

  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = worldFogConnectivityOwnershipScanViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_world_fog_connectivity_no_owner_map_rebuild: no ownership-map '
      'rebuilds in fog/connectivity modules.',
    );
    return 0;
  }
  logE(
    'check_world_fog_connectivity_no_owner_map_rebuild: found '
    '${violations.length} violation(s):',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}

void main() {
  exit(runCheckWorldFogConnectivityNoOwnerMapRebuild(Directory.current.path));
}
