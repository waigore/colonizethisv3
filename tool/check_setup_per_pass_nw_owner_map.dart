import 'dart:io';

import 'package:path/path.dart' as p;

/// Advanced-start world-knowledge / colonization owner lookup must use the
/// per-pass maps in `advanced_start_nw_owner_lookup.dart` (Refs #4054).
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _canonicalRelativePath =
    'packages/colonizethis_setup/lib/src/setup/advanced_start_nw_owner_lookup.dart';

const _worldRelativePath =
    'packages/colonizethis_setup/lib/src/setup/advanced_start_bootstrap_world.dart';

const _colonizationRelativePath =
    'packages/colonizethis_setup/lib/src/setup/advanced_start_bootstrap_colonization.dart';

final RegExp _bannedPrivateOwnerLookup = RegExp(
  r'\b_(ownerIdForLocalProvince|tribeOwnerForLocalProvince)\b',
);

/// Linear per-probe body: match a constructed full id then return/skip on
/// `ownerId` — the deleted helper shape.
final RegExp _bannedLinearOwnerBody = RegExp(
  r'ProvinceId\.prefixedFrom\([\s\S]{0,120}?ownerId',
  multiLine: true,
);

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

int runCheckSetupPerPassNwOwnerMap(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI('Setup per-pass NW owner-map check skipped (setup lib dir absent).');
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final violations = findSetupPerPassNwOwnerMapViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup per-pass NW owner-map check passed.');
    return 0;
  }

  logE(
    'ERROR: Found linear NW owner lookup in advanced-start world/colonization. '
    'Build nwOwnerByLocalProvinceId / nwTribeOwnerByLocalProvinceId once per '
    'pass from advanced_start_nw_owner_lookup.dart (Refs #4054).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupPerPassNwOwnerMap(Directory.current.path));
}

List<SetupPerPassNwOwnerMapViolation> findSetupPerPassNwOwnerMapViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupPerPassNwOwnerMapViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_canonicalRelativePath)) continue;
    final isWorld = normalized == p.normalize(_worldRelativePath);
    final isColonization = normalized == p.normalize(_colonizationRelativePath);
    if (!isWorld && !isColonization) continue;

    final content = sourcesByPath[path]!;
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_bannedPrivateOwnerLookup.hasMatch(line)) {
        violations.add(
          SetupPerPassNwOwnerMapViolation(
            path: path,
            line: i + 1,
            message:
                'Private linear owner lookup; use nwOwnerByLocalProvinceId / '
                'nwTribeOwnerByLocalProvinceId.',
          ),
        );
      }
    }

    // Strip full-line comments before searching for the linear-body shape.
    final codeOnly = lines
        .where((l) => !_isCommentLine(l))
        .join('\n');
    if (_bannedLinearOwnerBody.hasMatch(codeOnly) &&
        codeOnly.contains('newWorld.provinces')) {
      violations.add(
        SetupPerPassNwOwnerMapViolation(
          path: path,
          line: 1,
          message:
              'Linear NW province scan returning ownerId via prefixedFrom; '
              'build a per-pass owner map instead.',
        ),
      );
    }

    if (isWorld && !content.contains('nwOwnerByLocalProvinceId(')) {
      violations.add(
        SetupPerPassNwOwnerMapViolation(
          path: path,
          line: 1,
          message: 'World knowledge must call nwOwnerByLocalProvinceId once.',
        ),
      );
    }
    if (isColonization && !content.contains('nwTribeOwnerByLocalProvinceId(')) {
      violations.add(
        SetupPerPassNwOwnerMapViolation(
          path: path,
          line: 1,
          message: 'Colonization must call nwTribeOwnerByLocalProvinceId once.',
        ),
      );
    }
  }
  return violations;
}

class SetupPerPassNwOwnerMapViolation {
  const SetupPerPassNwOwnerMapViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
