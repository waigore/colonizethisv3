// Enforces the SPEC/program/orders.md § Diplomatic sub-validators contract:
// every per-type module under `lib/src/orders/validators/diplomatic/` must be
// expressed as a factory function backed by `delegatedDiplomaticSubValidator` /
// `relationDiplomaticSubValidator` — *no* bespoke `implements
// DiplomaticSubValidator` class. The shared contract file
// `diplomatic_sub_validator.dart` is the only sanctioned location for an
// `implements DiplomaticSubValidator` declaration (the private
// `_DelegatedDiplomaticSubValidator` adapter); that file is exempt below.
//
// As a defense-in-depth safety net, any sanctioned class (today only the
// adapter in the contract file) is also bounded to [_maxClassBodyLines] of
// non-empty body so the helper itself cannot drift into bespoke type-specific
// logic (Refs #2560).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxClassBodyLines = 30;

/// Files in `lib/src/orders/validators/diplomatic/` allowed to declare a
/// class that implements `DiplomaticSubValidator`. Currently only the
/// shared contract file (which hosts the private `_DelegatedDiplomaticSubValidator`
/// adapter) is sanctioned; every per-type module must be a free factory
/// function (SPEC/program/orders.md § Diplomatic sub-validators).
const _sanctionedClassFiles = <String>{
  'diplomatic_sub_validator.dart',
};

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
    final fileName = p.basename(file.path);
    final relativePath = p.relative(file.path, from: repoRoot);
    final sanctioned = _sanctionedClassFiles.contains(fileName);
    for (final match in _classDeclPattern.allMatches(content)) {
      final className = match.group(1)!;
      if (!sanctioned) {
        violations.add(
          '$relativePath ($className): bespoke `implements DiplomaticSubValidator` '
          'classes are forbidden outside ${_sanctionedClassFiles.join(', ')}; '
          'use a factory function backed by delegatedDiplomaticSubValidator / '
          'relationDiplomaticSubValidator (SPEC/program/orders.md § Diplomatic '
          'sub-validators).',
        );
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
