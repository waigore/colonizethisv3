import 'dart:io';

import 'package:path/path.dart' as p;

const _scanRoots = [
  'packages/colonizethis_setup/lib/src/setup',
  'packages/colonizethis_setup/test',
];

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

int runCheckSetupPrefixedProvinceIdNormalizer(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final sourcesByPath = <String, String>{};

  for (final scanRoot in _scanRoots) {
    final dir = Directory(p.join(root, scanRoot));
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      final relativePath = p.relative(entity.path, from: root);
      sourcesByPath[relativePath] = entity.readAsStringSync();
    }
  }

  final violations = findSetupPrefixedProvinceIdNormalizerViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup prefixed province-id normalizer check passed.');
    return 0;
  }

  logE(
    'ERROR: Found manual ProvinceId.isPrefixed ternary normalization in '
    'colonizethis_setup. Use ProvinceId.prefixedFrom(regionId, id) for '
    'canonical keys or ProvinceId.localFromMaybePrefixed(id) for local ids.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupPrefixedProvinceIdNormalizer(Directory.current.path));
}

List<SetupPrefixedProvinceIdNormalizerViolation>
findSetupPrefixedProvinceIdNormalizerViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupPrefixedProvinceIdNormalizerViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line) || !line.contains('ProvinceId.isPrefixed(')) {
        continue;
      }
      final statement = StringBuffer(line);
      var end = i;
      while (end + 1 < lines.length &&
          !lines[end].contains(';') &&
          end - i < 8) {
        end++;
        statement.write('\n${lines[end]}');
      }
      if (statement.toString().contains('?')) {
        violations.add(
          SetupPrefixedProvinceIdNormalizerViolation(
            path: path,
            line: i + 1,
            message:
                'Manual prefixed-id normalization; use ProvinceId.prefixedFrom '
                'or ProvinceId.localFromMaybePrefixed.',
          ),
        );
      }
    }
  }
  return violations;
}

class SetupPrefixedProvinceIdNormalizerViolation {
  const SetupPrefixedProvinceIdNormalizerViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
