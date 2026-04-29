// After `flutter gen-l10n`, overwrites `app/lib/l10n/app_localizations.dart` with the
// tracked barrel re-export. The generator overwrites that path; we restore the
// split layout (Refs #2021, English parts + contract + lookup).
//
// Run from repo root: dart run tool/patch_app_localizations_after_gen_l10n.dart

import 'dart:io';

const _barrel = r'''// Barrel re-export for `package:colonizethis_app/l10n/app_localizations.dart`.
// Abstract API, delegate, and English implementation are split to satisfy
// analyzer (no import cycle) and line limits; see app_localizations_contract.dart.
//
// After `flutter gen-l10n`, `tool/patch_app_localizations_after_gen_l10n.dart` resets
// this file to this content (generated output is not committed).

export 'app_localizations_contract.dart';
export 'app_localizations_lookup.dart' show lookupAppLocalizations;
''';

void main() {
  final toolDir = File(Platform.script.toFilePath()).parent;
  final root = toolDir.parent.path;
  final path = '$root/app/lib/l10n/app_localizations.dart';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('patch_app_localizations: missing $path (skip)');
    exit(0);
  }
  file.writeAsStringSync(_barrel);
}
