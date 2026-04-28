import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxNonCommentLines = 1000;
const _generatedSuffixes = <String>[
  '.g.dart',
  '.freezed.dart',
  '.mocks.dart',
  '.gen.dart',
];
const _excludedDirectoryNames = <String>{
  '.git',
  '.dart_tool',
  '.idea',
  '.vscode',
  '.cursor',
  '.pub-cache',
  'build',
};

int runCheckDartFileNonCommentLineSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final repoDir = Directory(repoRoot);
  if (!repoDir.existsSync()) {
    logE(
      'check_dart_file_non_comment_line_size: repo root not found: $repoRoot',
    );
    return 1;
  }

  final violations = collectNonCommentLineSizeViolations(repoRoot);
  if (violations.isEmpty) {
    logI('check_dart_file_non_comment_line_size: no violations found.');
    return 0;
  }

  logE(
    'check_dart_file_non_comment_line_size: found ${violations.length} violation(s) '
    '(non-comment lines > $_maxNonCommentLines):',
  );
  for (final violation in violations) {
    logE(
      ' - ${violation.relativePath} '
      '(${violation.nonCommentLines} non-comment lines > $_maxNonCommentLines)',
    );
  }
  return 1;
}

List<({String relativePath, int nonCommentLines})>
collectNonCommentLineSizeViolations(String repoRoot) {
  final violations = <({String relativePath, int nonCommentLines})>[];
  for (final file in _collectRepoDartFiles(repoRoot)) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final source = file.readAsStringSync();
    final nonCommentLines = countNonCommentLinesFromSource(source);
    if (nonCommentLines > _maxNonCommentLines) {
      violations.add((
        relativePath: relativePath.replaceAll('\\', '/'),
        nonCommentLines: nonCommentLines,
      ));
    }
  }
  violations.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  return violations;
}

List<File> _collectRepoDartFiles(String repoRoot) {
  final files = <File>[];
  final pending = <Directory>[Directory(repoRoot)];

  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    for (final entity in current.listSync(followLinks: false)) {
      if (entity is Directory) {
        final base = p.basename(entity.path);
        if (_excludedDirectoryNames.contains(base)) {
          continue;
        }
        pending.add(entity);
        continue;
      }
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
      if (_isGeneratedDartPath(rel)) {
        continue;
      }
      files.add(entity);
    }
  }

  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

bool _isGeneratedDartPath(String relativePath) {
  for (final suffix in _generatedSuffixes) {
    if (relativePath.endsWith(suffix)) {
      return true;
    }
  }
  return false;
}

int countNonCommentLinesFromSource(String source) {
  final state = _SourceScanState();
  var count = 0;
  for (final line in const LineSplitter().convert(source)) {
    if (_lineHasCountableCode(line, state)) {
      count++;
    }
  }
  return count;
}

bool _lineHasCountableCode(String line, _SourceScanState state) {
  if (line.trim().isEmpty) {
    if (state.inTripleSingleString || state.inTripleDoubleString) {
      return false;
    }
    return false;
  }

  var i = 0;
  var hasCode = false;
  while (i < line.length) {
    if (state.inBlockComment) {
      final end = line.indexOf('*/', i);
      if (end == -1) {
        return hasCode;
      }
      i = end + 2;
      state.inBlockComment = false;
      continue;
    }

    if (state.inTripleSingleString) {
      hasCode = hasCode || !_isWhitespace(line.codeUnitAt(i));
      if (_startsWithAt(line, i, "'''")) {
        state.inTripleSingleString = false;
        i += 3;
        continue;
      }
      i++;
      continue;
    }

    if (state.inTripleDoubleString) {
      hasCode = hasCode || !_isWhitespace(line.codeUnitAt(i));
      if (_startsWithAt(line, i, '"""')) {
        state.inTripleDoubleString = false;
        i += 3;
        continue;
      }
      i++;
      continue;
    }

    final ch = line.codeUnitAt(i);
    if (_isWhitespace(ch)) {
      i++;
      continue;
    }
    if (_startsWithAt(line, i, '//')) {
      break;
    }
    if (_startsWithAt(line, i, '/*')) {
      state.inBlockComment = true;
      i += 2;
      continue;
    }
    if (_startsWithAt(line, i, "'''")) {
      state.inTripleSingleString = true;
      hasCode = true;
      i += 3;
      continue;
    }
    if (_startsWithAt(line, i, '"""')) {
      state.inTripleDoubleString = true;
      hasCode = true;
      i += 3;
      continue;
    }
    if (ch == 39 || ch == 34) {
      hasCode = true;
      i = _consumeSingleLineStringLiteral(line, i, ch);
      continue;
    }

    hasCode = true;
    i++;
  }

  return hasCode;
}

int _consumeSingleLineStringLiteral(String line, int start, int quoteCodeUnit) {
  var i = start + 1;
  var escaped = false;
  while (i < line.length) {
    final ch = line.codeUnitAt(i);
    if (escaped) {
      escaped = false;
      i++;
      continue;
    }
    if (ch == 92) {
      escaped = true;
      i++;
      continue;
    }
    if (ch == quoteCodeUnit) {
      return i + 1;
    }
    i++;
  }
  return line.length;
}

bool _startsWithAt(String source, int index, String token) {
  final end = index + token.length;
  if (end > source.length) {
    return false;
  }
  return source.substring(index, end) == token;
}

bool _isWhitespace(int codeUnit) {
  return codeUnit == 32 || codeUnit == 9;
}

final class _SourceScanState {
  bool inBlockComment = false;
  bool inTripleSingleString = false;
  bool inTripleDoubleString = false;
}

void main() {
  exit(runCheckDartFileNonCommentLineSize(Directory.current.path));
}
