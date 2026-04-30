// After `flutter gen-l10n`, restores tracked split layout (Refs #2021):
// - `app_localizations.dart` → barrel (contract + delegate exports).
// - `app_localizations_en.dart` → thin library shell with `part` fragments.
//
// `gen-l10n` overwrites both paths; without restoring `app_localizations_en.dart`,
// part files lose their library imports and analyze fails (undefined
// `AppLocalizations`, `intl`, `kWorkTarget*`).
//
// Run from repo root: dart run tool/patch_app_localizations_after_gen_l10n.dart

import 'dart:io';

const _barrel = r'''// Tracked barrel: `flutter gen-l10n` overwrites this path; CI restores via
// `tool/patch_app_localizations_after_gen_l10n.dart` (Refs #2021).

export 'app_localizations_contract.dart';
export 'app_localizations_delegate.dart';
''';

/// English implementation library: implementations live in `app_localizations_en_part*.dart`.
const _enLibraryShell = r'''// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore, kWorkTargetProspect;
import 'app_localizations_contract.dart';

// ignore_for_file: type=lint

part 'app_localizations_en_part1.dart';
part 'app_localizations_en_part2.dart';
part 'app_localizations_en_part3.dart';
part 'app_localizations_en_part4.dart';
part 'app_localizations_en_part5.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations
    with _AppLocalizationsEnStrings1,
        _AppLocalizationsEnStrings2,
        _AppLocalizationsEnStrings3,
        _AppLocalizationsEnStrings4,
        _AppLocalizationsEnStrings5 {
  AppLocalizationsEn([String locale = 'en']) : super(locale);
}
''';

void main() {
  final toolDir = File(Platform.script.toFilePath()).parent;
  final root = toolDir.parent.path;
  final l10nDir = '$root/app/lib/l10n';
  final barrelPath = '$l10nDir/app_localizations.dart';
  final enPath = '$l10nDir/app_localizations_en.dart';

  final barrelFile = File(barrelPath);
  if (!barrelFile.existsSync()) {
    stderr.writeln('patch_app_localizations: missing $barrelPath (skip)');
    exit(0);
  }
  barrelFile.writeAsStringSync(_barrel);

  final enFile = File(enPath);
  if (!enFile.existsSync()) {
    stderr.writeln('patch_app_localizations: missing $enPath (skip en shell)');
    exit(0);
  }
  enFile.writeAsStringSync(_enLibraryShell);
}
