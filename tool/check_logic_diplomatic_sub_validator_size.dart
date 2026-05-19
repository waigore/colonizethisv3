// Enforces thin DiplomaticSubValidator class bodies (Refs #2560).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxClassBodyLines = 30;

/// Classes allowed to exceed [_maxClassBodyLines] (multi-stage overture logic).
const _allowedLargeClasses = {'EstablishOvertureSubValidator'};

int runCheckLogicDiplomaticSubValidatorSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final dir = Directory(
    p.join(
      repoRoot,
      'packages',
      'colonizethis_logic',
      'lib',
      'src',
      'orders',
      'validators',
      'diplomatic',
    ),
  );
  if (!dir.existsSync()) {
    logE('check_logic_diplomatic_sub_validator_size: directory not found.');
    return 1;
  }

  final violations = <String>[];
  for (final file in dir
      .listSync(recursive: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))) {
    final content = file.readAsStringSync();
    if (!content.contains('implements DiplomaticSubValidator')) {
      continue;
    }
    final relativePath = p.relative(file.path, from: repoRoot);
    for (final match in _classDeclPattern.allMatches(content)) {
      final className = match.group(1)!;
      if (_allowedLargeClasses.contains(className)) {
        continue;
      }
      final bodyStart = match.end;
      final bodyEnd = _findMatchingBrace(content, bodyStart - 1);
      if (bodyEnd == null) {
        violations.add('$relativePath ($className: unbalanced braces)');
        continue;
      }
      final body = content.substring(bodyStart, bodyEnd);
      final bodyLines = const LineSplitter()
          .convert(body)
          .where((line) => line.trim().isNotEmpty)
          .length;
      if (bodyLines > _maxClassBodyLines) {
        violations.add(
          '$relativePath ($className class body: $bodyLines lines > $_maxClassBodyLines)',
        );
      }
    }
  }

  if (violations.isEmpty) {
    logI('check_logic_diplomatic_sub_validator_size: no violations found.');
    return 0;
  }

  logE(
    'check_logic_diplomatic_sub_validator_size: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

final _classDeclPattern = RegExp(
  r'class\s+(\w+)\s+[^{]*implements\s+DiplomaticSubValidator\s*\{',
);

int? _findMatchingBrace(String source, int openIndex) {
  if (openIndex < 0 || openIndex >= source.length || source[openIndex] != '{') {
    return null;
  }
  var depth = 0;
  for (var i = openIndex; i < source.length; i++) {
    final ch = source[i];
    if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return null;
}

void main() {
  exit(runCheckLogicDiplomaticSubValidatorSize(Directory.current.path));
}
