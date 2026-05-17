// Reads tech_effect_summary.yaml and merges tech effect ARB entries into
// app/lib/l10n/arb/app_en.arb, and writes
// app/lib/features/game/widgets/tech_effect_summary_lookup.dart
//
// Run from repo root: dart tool/generate_tech_effect_l10n.dart
// Then: cd app && flutter gen-l10n

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

void main() {
  final root = _findRepoRoot();
  final yamlFile = File(
    '$root/packages/colonizethis_data/lib/src/data/tech_effect_summary.yaml',
  );
  final appEnArb = File('$root/app/lib/l10n/arb/app_en.arb');
  final lookupPath = File(
    '$root/app/lib/features/game/widgets/tech_effect_summary_lookup.dart',
  );

  final doc = loadYaml(yamlFile.readAsStringSync());
  if (doc is! YamlMap) {
    throw StateError('expected map');
  }
  final lines = doc['lines'];
  if (lines is! YamlMap) {
    throw StateError('expected lines');
  }

  final entries = <String, String>{};
  for (final e in lines.entries) {
    final k = e.key;
    if (k is! String) {
      continue;
    }
    final v = e.value;
    if (v is! YamlMap) {
      throw StateError('line $k');
    }
    final en = v['en'];
    if (en is! String) {
      throw StateError('line $k en');
    }
    entries[k] = en;
  }

  final sortedKeys = entries.keys.toList()..sort();

  _mergeIntoAppEnArb(appEnArb, sortedKeys, entries);
  stderr.writeln(
    'Merged ${sortedKeys.length} techEffectSummary_* keys into ${appEnArb.path}',
  );

  final buf = StringBuffer();
  buf.writeln('// GENERATED FILE — do not edit by hand.');
  buf.writeln('// Run: dart tool/generate_tech_effect_l10n.dart');
  buf.writeln('// Then: cd app && flutter gen-l10n');
  buf.writeln();
  buf.writeln("import 'package:colonizethis_app/l10n/l10n.dart';");
  buf.writeln();
  buf.writeln(
    '/// Resolves a tech effect line id from [tech_effect_summary.yaml] via [AppLocalizations].',
  );
  buf.writeln(
    'String lookupTechEffectSummaryLine(AppLocalizations l10n, String lineId) {',
  );
  buf.writeln('  final fn = _techEffectSummaryL10n[lineId];');
  buf.writeln('  return fn != null ? fn(l10n) : lineId;');
  buf.writeln('}');
  buf.writeln();
  buf.writeln(
    'final Map<String, String Function(AppLocalizations)> _techEffectSummaryL10n = {',
  );
  for (final k in sortedKeys) {
    buf.writeln("  '$k': (l10n) => l10n.$k,");
  }
  buf.writeln('};');
  buf.writeln();

  lookupPath.writeAsStringSync(buf.toString());
  stderr.writeln('Wrote ${lookupPath.path}');
}

void _mergeIntoAppEnArb(
  File appEnArb,
  List<String> sortedKeys,
  Map<String, String> entries,
) {
  final decoded =
      json.decode(appEnArb.readAsStringSync()) as Map<String, dynamic>;
  final out = <String, dynamic>{};
  for (final e in decoded.entries) {
    final k = e.key;
    if (k.startsWith('techEffectSummary_') ||
        k.startsWith('@techEffectSummary_')) {
      continue;
    }
    out[k] = e.value;
  }
  for (final k in sortedKeys) {
    out[k] = entries[k]!;
    out['@$k'] = {'description': 'Tech tree dialog effect line ($k).'};
  }
  appEnArb.writeAsStringSync('${JsonEncoder.withIndent('  ').convert(out)}\n');
}

String _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      final p = File('${dir.path}/pubspec.yaml').readAsStringSync();
      if (p.contains('name: colonizethis')) {
        return dir.path;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('repo root');
    }
    dir = parent;
  }
}
