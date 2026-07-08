// Fails when any generated `*.dart` exists under `app/lib/l10n/` — l10n gen
// belongs only in `colonizethis_app_l10n` (Refs #3942 / AC2–AC4).
//
// SPEC: SPEC/program/repo-and-packages.md § App shell submodule layout
import 'dart:io';

import 'package:path/path.dart' as p;

const String appLibL10nDirPath = 'app/lib/l10n';

int runCheckAppNoStrayL10nGen(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final l10nDir = Directory(p.join(repoRoot, appLibL10nDirPath));
  if (!l10nDir.existsSync()) {
    logI(
      'check_app_no_stray_l10n_gen: $appLibL10nDirPath absent; OK '
      '(gen lives in colonizethis_app_l10n).',
    );
    return 0;
  }

  final dartFiles = l10nDir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => p.relative(f.path, from: repoRoot).replaceAll('\\', '/'))
      .toList()
    ..sort();

  if (dartFiles.isEmpty) {
    logI(
      'check_app_no_stray_l10n_gen: $appLibL10nDirPath has no *.dart; OK.',
    );
    return 0;
  }

  logE(
    'check_app_no_stray_l10n_gen: ${dartFiles.length} stray generated '
    'Dart file(s) under $appLibL10nDirPath (Refs #3942); move gen to '
    'packages/colonizethis_app_l10n:',
  );
  for (final file in dartFiles) {
    logE(' - $file');
  }
  return 1;
}

void main() {
  exit(runCheckAppNoStrayL10nGen(Directory.current.path));
}
