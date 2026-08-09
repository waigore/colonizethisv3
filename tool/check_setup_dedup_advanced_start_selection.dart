import 'dart:io';

import 'package:path/path.dart' as p;

/// Advanced-start fraction selection and minor-buyer round-robin must live in
/// `advanced_start_selection.dart` (Refs #4054).
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _canonicalRelativePath =
    'packages/colonizethis_setup/lib/src/setup/advanced_start_selection.dart';

final RegExp _bannedBuyerRoundRobin = RegExp(
  r'%\s*game\.players\.length',
);

/// Re-inlined fraction take: `(…length * …).ceil()` followed by `.take(` on a
/// nearby line (prospecting / development selection shape).
final RegExp _fractionCeil = RegExp(
  r'\.length\s*\*\s*\w+\)\.ceil\(\)',
);

final RegExp _takeCall = RegExp(r'\.take\(');

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

int runCheckSetupDedupAdvancedStartSelection(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI(
      'Setup dedup advanced-start selection check skipped '
      '(setup lib dir absent).',
    );
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

  final violations = findSetupDedupAdvancedStartSelectionViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup advanced-start selection check passed.');
    return 0;
  }

  logE(
    'ERROR: Found re-inlined advanced-start fraction selection or minor-buyer '
    'round-robin. Use selectByFractionCeil / minorBuyerIdRoundRobin from '
    'advanced_start_selection.dart (Refs #4054).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupAdvancedStartSelection(Directory.current.path));
}

List<SetupDedupAdvancedStartSelectionViolation>
findSetupDedupAdvancedStartSelectionViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupAdvancedStartSelectionViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_canonicalRelativePath)) continue;
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_bannedBuyerRoundRobin.hasMatch(line)) {
        violations.add(
          SetupDedupAdvancedStartSelectionViolation(
            path: path,
            line: i + 1,
            message:
                'Minor-buyer round-robin; call minorBuyerIdRoundRobin(game, i).',
          ),
        );
      }
      if (_fractionCeil.hasMatch(line)) {
        final window = lines
            .sublist(i, i + 4 > lines.length ? lines.length : i + 4)
            .join('\n');
        if (_takeCall.hasMatch(window)) {
          violations.add(
            SetupDedupAdvancedStartSelectionViolation(
              path: path,
              line: i + 1,
              message:
                  'Fraction ceil+take selection; call selectByFractionCeil.',
            ),
          );
        }
      }
    }
  }
  return violations;
}

class SetupDedupAdvancedStartSelectionViolation {
  const SetupDedupAdvancedStartSelectionViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
