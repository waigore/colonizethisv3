// Patches `app/lib/l10n/app_localizations.dart` after `flutter gen-l10n`:
// - Breaks the circular import with `app_localizations_en.dart` by moving
//   `lookupAppLocalizations` to tracked `app_localizations_lookup.dart`.
// - Idempotent: safe to run multiple times.
//
// Run from repo root: dart run tool/patch_app_localizations_after_gen_l10n.dart

import 'dart:io';

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
  const lookupImport = "import 'app_localizations_lookup.dart';";
  const lookupExport =
      "export 'app_localizations_lookup.dart' show lookupAppLocalizations;";

  if (!text.contains(importLine)) {
    stderr.writeln('patch_app_localizations: unexpected $path (no intl import)');
    exit(1);
  }

  if (!text.contains(lookupImport)) {
    text = text.replaceFirst(
      importLine,
      '$importLine\n\n$lookupImport\n$lookupExport',
    );
  }

  text = _removeTopLevelLookupFunction(text);

  file.writeAsStringSync(text);
}

String _removeTopLevelLookupFunction(String text) {
  const needle = 'AppLocalizations lookupAppLocalizations';
  final start = text.indexOf(needle);
  if (start < 0) {
    return text;
  }
  // Top-level function starts at beginning of line (gen-l10n has no indent).
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
        // Drop trailing newline(s) after function.
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
