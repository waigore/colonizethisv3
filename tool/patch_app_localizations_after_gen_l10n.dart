// After `flutter gen-l10n`, replaces `app/lib/l10n/app_localizations.dart` with the
// tracked split layout (Refs #2021): contract + delegate + barrel; English parts
// import contract only (no import cycle with generated main).
//
// Run from repo root: dart run tool/patch_app_localizations_after_gen_l10n.dart

import 'dart:io';

const _barrel = r'''// Tracked barrel: `flutter gen-l10n` overwrites this path; CI restores via
// `tool/patch_app_localizations_after_gen_l10n.dart` (Refs #2021).

export 'app_localizations_contract.dart';
export 'app_localizations_delegate.dart';
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
