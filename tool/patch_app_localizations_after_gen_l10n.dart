// Patches `app/lib/l10n/app_localizations.dart` after `flutter gen-l10n`:
// - Does **not** import or export `app_localizations_lookup.dart` from the
//   generated main library (exporting lookup merges lookup + main into one
//   compilation unit and recreates the cycle: lookup → en → app_localizations).
//   Call sites import `package:colonizethis_app/l10n/app_localizations_lookup.dart`
//   for `lookupAppLocalizations`.
// - Replaces synchronous `import 'app_localizations_en.dart'` with **deferred**
//   import so `AppLocalizations` is defined before English part mixins resolve.
// - Idempotent: safe to run multiple times.
//
// Run from repo root: dart run tool/patch_app_localizations_after_gen_l10n.dart

import 'dart:io';

const _deferredEnPrefix = "import 'app_localizations_en.dart' deferred as ";
const _syncEnImport = "import 'app_localizations_en.dart';";

void main() {
  final toolDir = File(Platform.script.toFilePath()).parent;
  final root = toolDir.parent.path;
  final path = '$root/app/lib/l10n/app_localizations.dart';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('patch_app_localizations: missing $path (skip)');
    exit(0);
  }

  var text = file.readAsStringSync();
  const importLine = "import 'package:intl/intl.dart' as intl;";
  const lookupExport =
      "export 'app_localizations_lookup.dart' show lookupAppLocalizations;";

  if (!text.contains(importLine)) {
    stderr.writeln('patch_app_localizations: unexpected $path (no intl import)');
    exit(1);
  }

  text = _removeImportLine(text, "import 'app_localizations_lookup.dart';");
  text = _removeImportLine(text, lookupExport);

  text = _ensureDeferredEnglishImport(text);
  text = _patchDelegateLoad(text);
  text = _removeTopLevelLookupFunction(text);

  file.writeAsStringSync(text);
}

String _ensureDeferredEnglishImport(String text) {
  if (text.contains(_deferredEnPrefix)) {
    return text;
  }
  if (!text.contains(_syncEnImport)) {
    stderr.writeln(
      'patch_app_localizations: unexpected file (no app_localizations_en import)',
    );
    exit(1);
  }
  return text.replaceFirst(
    _syncEnImport,
    "${_deferredEnPrefix}_ct_l10n_en;\n",
  );
}

String _patchDelegateLoad(String text) {
  const syncBody =
      'return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));';
  const asyncBody = '''
return _ctLoadLocalizedApp(locale);''';

  if (text.contains('_ctLoadLocalizedApp')) {
    return text;
  }
  if (!text.contains(syncBody)) {
    stderr.writeln(
      'patch_app_localizations: unexpected delegate load() body; '
      'expected SynchronousFuture + lookupAppLocalizations',
    );
    exit(1);
  }

  const helper = '''

Future<AppLocalizations> _ctLoadLocalizedApp(Locale locale) async {
  await _ct_l10n_en.loadLibrary();
  switch (locale.languageCode) {
    case 'en':
      return _ct_l10n_en.AppLocalizationsEn();
  }
  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "\$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
''';

  const anchor = 'class _AppLocalizationsDelegate';
  final anchorIdx = text.indexOf(anchor);
  if (anchorIdx < 0) {
    stderr.writeln('patch_app_localizations: missing _AppLocalizationsDelegate');
    exit(1);
  }
  text = text.replaceRange(anchorIdx, anchorIdx, helper);

  text = text.replaceFirst(syncBody, asyncBody);

  text = text.replaceFirst(
    'Future<AppLocalizations> load(Locale locale) {',
    'Future<AppLocalizations> load(Locale locale) async {',
  );

  return text;
}

String _removeTopLevelLookupFunction(String text) {
  const needle = 'AppLocalizations lookupAppLocalizations';
  final start = text.indexOf(needle);
  if (start < 0) {
    return text;
  }
  var i = start;
  while (i > 0 && text[i - 1] != '\n') {
    i--;
  }
  final lineStart = i;
  final openBrace = text.indexOf('{', start);
  if (openBrace < 0) {
    return text;
  }
  var depth = 0;
  var j = openBrace;
  for (; j < text.length; j++) {
    final ch = text[j];
    if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) {
        final end = j + 1;
        var k = end;
        while (k < text.length &&
            (text[k] == '\n' || text[k] == '\r' || text[k] == ' ')) {
          if (text[k] == '\n') {
            k++;
            break;
          }
          k++;
        }
        return text.replaceRange(lineStart, k, '');
      }
    }
  }
  return text;
}

String _removeImportLine(String text, String importLine) {
  if (!text.contains(importLine)) {
    return text;
  }
  return text.split('\n').where((l) => l.trim() != importLine.trim()).join('\n');
}
