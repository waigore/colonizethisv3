// Physical line limit for split domain-package source (Refs #3290).
// Mirrors `repo.logic_source_file_size` (500 physical lines) across every
// `packages/colonizethis_<domain>/lib/src/**` tree for the eight extracted
// logic-domain packages. The Phase 0 decomposition pushed every former
// monolith offender below 500 lines before extraction; after the source moved
// into the domain packages the original `repo.logic_source_file_size` gate only
// observes the thin `colonizethis_logic` core, so this gate keeps the cap
// enforced on the extracted source so the decomposition cannot regress.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxPhysicalLines = 500;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

/// Domain packages whose migrated source trees must stay within the shared cap.
const List<String> domainPackageSourceFileSizeDomainsForTests = [
  'world',
  'combat',
  'economy',
  'diplomacy',
  'setup',
  'orders',
  'turn',
  'ai_contracts',
];

int runCheckDomainPackageSourceFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final violations = <String>[];

  for (final domain in domainPackageSourceFileSizeDomainsForTests) {
    final srcDir = Directory(
      p.join(repoRoot, 'packages', 'colonizethis_$domain', 'lib', 'src'),
    );
    if (!srcDir.existsSync()) {
      logE(
        'check_domain_package_source_file_size: '
        'packages/colonizethis_$domain/lib/src not found.',
      );
      return 1;
    }

    final filesToCheck = _collectFilesToCheck(
      repoRoot,
      domain,
      srcDir,
      targetFiles,
    );
    for (final filePath in filesToCheck) {
      final file = File(filePath);
      final relativePath = p.relative(file.path, from: repoRoot);
      final physicalLines = const LineSplitter()
          .convert(file.readAsStringSync())
          .length;
      if (physicalLines <= _maxPhysicalLines) {
        continue;
      }
      violations.add(
        '$relativePath ($physicalLines physical lines > $_maxPhysicalLines)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_domain_package_source_file_size: no violations found.');
    return 0;
  }

  logE(
    'check_domain_package_source_file_size: found ${violations.length} '
    'violation(s) under split domain-package source trees:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  String domain,
  Directory srcDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return srcDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .where((path) => !_generatedSuffix.hasMatch(path))
        .toList(growable: false);
  }

  final prefix = 'packages/colonizethis_$domain/lib/src/';
  final results = <String>[];
  for (final relativePath in targetFiles) {
    if (!relativePath.startsWith(prefix) || !relativePath.endsWith('.dart')) {
      continue;
    }
    if (_generatedSuffix.hasMatch(relativePath)) {
      continue;
    }
    final absolutePath = p.join(repoRoot, relativePath);
    final file = File(absolutePath);
    if (!file.existsSync()) {
      continue;
    }
    results.add(file.path);
  }
  return results;
}

void main(List<String> args) {
  exit(
    runCheckDomainPackageSourceFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}

int maxDomainPackageSourceFilePhysicalLinesForTests() => _maxPhysicalLines;
