// After `flutter gen-l10n`, restores the tracked `app_localizations_en.dart` library shell
// (Refs #2021). Gen writes `app_l10n_flutter_gen*.dart` only (`l10n.yaml`), but older
// toolchains or manual `gen-l10n` runs can still overwrite `app_localizations_en.dart`;
// without this shell, `part` files lose their library imports and analyze fails.
//
// Run from repo root: dart run tool/patch_app_localizations_after_gen_l10n.dart

import 'dart:io';

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
  final enPath = '$l10nDir/app_localizations_en.dart';

  File(enPath).writeAsStringSync(_enLibraryShell);
}
