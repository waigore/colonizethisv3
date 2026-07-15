import 'dart:io';

import 'package:path/path.dart' as p;

/// Towns / naming / bootstrap helpers must stay first-class libraries (Refs #4029).
/// `game_setup_helpers.dart` re-exports them and must not `part` them.
const _helpersRelativePath =
    'packages/colonizethis_setup/lib/src/setup/game_setup_helpers.dart';

const _libraryRelativePaths = <String>[
  'packages/colonizethis_setup/lib/src/setup/game_setup_helpers_towns.dart',
  'packages/colonizethis_setup/lib/src/setup/game_setup_helpers_naming.dart',
  'packages/colonizethis_setup/lib/src/setup/game_setup_helpers_bootstrap.dart',
];

final RegExp _partDirective = RegExp(r"^\s*part\s+'([^']+)'\s*;");
final RegExp _partOfDirective = RegExp(r"^\s*part\s+of\s+");
final RegExp _exportDirective = RegExp(r"^\s*export\s+'([^']+)'\s*;");

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupHelpersFirstClassLibraries(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final sourcesByPath = <String, String>{};
  for (final relative in [_helpersRelativePath, ..._libraryRelativePaths]) {
    final file = File(p.join(root, relative));
    if (!file.existsSync()) {
      logE('ERROR: Missing required setup helpers file: $relative');
      return 1;
    }
    sourcesByPath[relative] = file.readAsStringSync();
  }

  final violations = findSetupHelpersFirstClassLibraryViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup helpers first-class libraries check passed.');
    return 0;
  }

  logE(
    'ERROR: game_setup_helpers naming/bootstrap/towns must remain first-class '
    'libraries with barrel re-exports (Refs #4029).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupHelpersFirstClassLibraries(Directory.current.path));
}

List<SetupHelpersFirstClassLibraryViolation>
findSetupHelpersFirstClassLibraryViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupHelpersFirstClassLibraryViolation>[];

  for (final relative in _libraryRelativePaths) {
    final source = sourcesByPath[relative];
    if (source == null) {
      violations.add(
        SetupHelpersFirstClassLibraryViolation(
          path: relative,
          line: 1,
          message: 'Missing library source.',
        ),
      );
      continue;
    }
    final lines = source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_partOfDirective.hasMatch(line)) {
        violations.add(
          SetupHelpersFirstClassLibraryViolation(
            path: relative,
            line: i + 1,
            message:
                'Must be a first-class library (not a part of '
                'game_setup_helpers.dart).',
          ),
        );
      }
    }
  }

  final helpers = sourcesByPath[_helpersRelativePath];
  if (helpers == null) {
    violations.add(
      const SetupHelpersFirstClassLibraryViolation(
        path: _helpersRelativePath,
        line: 1,
        message: 'Missing game_setup_helpers.dart barrel.',
      ),
    );
    return violations;
  }

  final exportedBasenames = <String>{};
  final lines = helpers.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;

    final partMatch = _partDirective.firstMatch(line);
    if (partMatch != null) {
      final partUri = partMatch.group(1)!;
      if (_libraryRelativePaths.any((p) => p.endsWith('/$partUri'))) {
        violations.add(
          SetupHelpersFirstClassLibraryViolation(
            path: _helpersRelativePath,
            line: i + 1,
            message:
                'Must re-export $partUri as a library; do not part it '
                '(towns pattern).',
          ),
        );
      }
    }

    final exportMatch = _exportDirective.firstMatch(line);
    if (exportMatch != null) {
      exportedBasenames.add(p.basename(exportMatch.group(1)!));
    }
  }

  for (final relative in _libraryRelativePaths) {
    final basename = p.basename(relative);
    if (!exportedBasenames.contains(basename)) {
      violations.add(
        SetupHelpersFirstClassLibraryViolation(
          path: _helpersRelativePath,
          line: 1,
          message: 'Missing export of $basename.',
        ),
      );
    }
  }

  return violations;
}

class SetupHelpersFirstClassLibraryViolation {
  const SetupHelpersFirstClassLibraryViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
