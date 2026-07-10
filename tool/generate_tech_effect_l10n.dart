// Reads tech_effect_summary.yaml and merges tech effect ARB entries into
// packages/colonizethis_app_l10n/lib/l10n/arb/app_en.arb, and writes
// packages/colonizethis_app_l10n/lib/tech_effect/tech_effect_summary_lookup.dart
// plus chunked `part` entry maps (Refs #3878).
//
// Run from repo root: dart tool/generate_tech_effect_l10n.dart
// Then: cd packages/colonizethis_app_l10n && flutter gen-l10n

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const _lookupEntriesPerPart = 54;

void main() {
  final root = _findRepoRoot();
  final yamlFile = File(
    '$root/packages/colonizethis_data/lib/src/data/tech_effect_summary.yaml',
  );
  final appEnArb = File('$root/packages/colonizethis_app_l10n/lib/l10n/arb/app_en.arb');
  final lookupPath = File(
    '$root/packages/colonizethis_app_l10n/lib/tech_effect/tech_effect_summary_lookup.dart',
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

  _writeLookupLibrary(lookupPath, sortedKeys);
  stderr.writeln('Wrote ${lookupPath.path}');
}

void _writeLookupLibrary(File lookupPath, List<String> sortedKeys) {
  final lookupDir = lookupPath.parent;
  for (final entity in lookupDir.listSync()) {
    if (entity is! File) {
      continue;
    }
    final name = entity.uri.pathSegments.last;
    if (name.startsWith('tech_effect_summary_lookup_entries_') &&
        name.endsWith('.dart')) {
      entity.deleteSync();
    }
  }

  final chunks = <List<String>>[];
  for (var i = 0; i < sortedKeys.length; i += _lookupEntriesPerPart) {
    final end = i + _lookupEntriesPerPart;
    chunks.add(
      sortedKeys.sublist(i, end > sortedKeys.length ? sortedKeys.length : end),
    );
  }

  for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
    final partPath = File(
      '${lookupDir.path}/tech_effect_summary_lookup_entries_$chunkIndex.dart',
    );
    final partBuf = StringBuffer()
      ..writeln('// GENERATED FILE — do not edit by hand.')
      ..writeln('// Run: dart tool/generate_tech_effect_l10n.dart')
      ..writeln('// Then: cd packages/colonizethis_app_l10n && flutter gen-l10n')
      ..writeln()
      ..writeln("part of 'tech_effect_summary_lookup.dart';")
      ..writeln()
      ..writeln(
        'Map<String, String Function(AppLocalizations)> '
        '_techEffectSummaryL10nChunk$chunkIndex() => {',
      );
    for (final k in chunks[chunkIndex]) {
      partBuf.writeln("  '$k': (l10n) => l10n.$k,");
    }
    partBuf.writeln('};');
    partBuf.writeln();
    partPath.writeAsStringSync(partBuf.toString());
    stderr.writeln('Wrote ${partPath.path}');
  }

  final mainBuf = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand.')
    ..writeln('// Run: dart tool/generate_tech_effect_l10n.dart')
    ..writeln('// Then: cd packages/colonizethis_app_l10n && flutter gen-l10n')
    ..writeln()
    ..writeln("import 'package:colonizethis_app_l10n/l10n/l10n.dart';")
    ..writeln();
  for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
    mainBuf.writeln(
      "part 'tech_effect_summary_lookup_entries_$chunkIndex.dart';",
    );
  }
  mainBuf
    ..writeln()
    ..writeln(
      '/// Resolves a tech effect line id from [tech_effect_summary.yaml] via [AppLocalizations].',
    )
    ..writeln(
      'String lookupTechEffectSummaryLine(AppLocalizations l10n, String lineId) {',
    )
    ..writeln('  final fn = _techEffectSummaryL10n[lineId];')
    ..writeln('  return fn != null ? fn(l10n) : lineId;')
    ..writeln('}')
    ..writeln()
    ..writeln(
      'final Map<String, String Function(AppLocalizations)> '
      '_techEffectSummaryL10n = {',
    );
  for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
    mainBuf.writeln('  ..._techEffectSummaryL10nChunk$chunkIndex(),');
  }
  mainBuf
    ..writeln('};')
    ..writeln();

  lookupPath.writeAsStringSync(mainBuf.toString());
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
