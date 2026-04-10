// Unified repo convention checks (manifest-driven). SPEC: SPEC/program/repo-lint.md
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_lib.dart';

void main(List<String> args) {
  final opts = parseRepoLintArgs(args);
  final repoRoot = p.normalize(Directory.current.path);
  final rules = loadRepoLintManifest(repoRoot, opts.manifestPath);
  final code = runRepoLint(repoRoot: repoRoot, allRules: rules, options: opts);
  exit(code);
}
