// Parses tech_tree_widget.dart switch in _effectSummary and writes
// packages/colonizethis_data/lib/src/data/tech_effect_summary.yaml
//
// Run from repo root: dart tool/generate_tech_effect_yaml.dart

import 'dart:io';

void main(List<String> args) {
  final root = _findRepoRoot();
  final widgetPath = File(
    '$root/app/lib/features/game/widgets/technology/tech_tree_widget.dart',
  );
  final outPath = File(
    '$root/packages/colonizethis_data/lib/src/data/tech_effect_summary.yaml',
  );

  final src = widgetPath.readAsStringSync();
  final cases = _parseSwitchCases(src);
  final yaml = _emitYaml(cases);
  outPath.parent.createSync(recursive: true);
  outPath.writeAsStringSync(yaml);
  stderr.writeln('Wrote ${cases.length} tech entries to ${outPath.path}');
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
      throw StateError(
        'Could not find repo root from ${Directory.current.path}',
      );
    }
    dir = parent;
  }
}

/// tech id -> list of literal strings passed to list.add('...')
List<MapEntry<String, List<String>>> _parseSwitchCases(String src) {
  final start = src.indexOf('switch (tech.id) {');
  if (start < 0) {
    throw StateError('switch (tech.id) not found');
  }
  final sub = src.substring(start);
  final defaultIdx = sub.indexOf('\n      default:');
  if (defaultIdx < 0) {
    throw StateError('default: not found');
  }
  final switchBody = sub.substring(0, defaultIdx);

  final caseRe = RegExp(r"case '([^']+)':");
  final matches = caseRe.allMatches(switchBody).toList();

  final result = <MapEntry<String, List<String>>>[];
  for (var i = 0; i < matches.length; i++) {
    final techId = matches[i].group(1)!;
    final blockStart = matches[i].end;
    final blockEnd = i + 1 < matches.length
        ? matches[i + 1].start
        : switchBody.length;
    final block = switchBody.substring(blockStart, blockEnd);
    final strings = _extractListAddStrings(block);
    result.add(MapEntry(techId, strings));
  }
  return result;
}

List<String> _extractListAddStrings(String block) {
  final out = <String>[];
  var searchFrom = 0;
  while (true) {
    final idx = block.indexOf('list.add(', searchFrom);
    if (idx < 0) {
      break;
    }
    var pos = idx + 'list.add('.length;
    while (pos < block.length && _isWhitespace(block.codeUnitAt(pos))) {
      pos++;
    }
    final parsed = _readSingleQuotedStringContent(block, pos);
    if (parsed == null) {
      searchFrom = idx + 1;
      continue;
    }
    out.add(parsed.$1);
    pos = parsed.$2;
    while (pos < block.length && _isWhitespace(block.codeUnitAt(pos))) {
      pos++;
    }
    if (pos < block.length && block[pos] == ',') {
      pos++;
    }
    while (pos < block.length && _isWhitespace(block.codeUnitAt(pos))) {
      pos++;
    }
    if (pos >= block.length || block[pos] != ')') {
      searchFrom = idx + 1;
      continue;
    }
    searchFrom = pos + 1;
  }
  return out;
}

bool _isWhitespace(int c) => c == 0x20 || c == 0x09 || c == 0x0a || c == 0x0d;

/// Reads `'...'` starting at [start] (must point at opening `'`).
/// Returns (content, indexAfterClosingQuote).
(String, int)? _readSingleQuotedStringContent(String s, int start) {
  if (start >= s.length || s.codeUnitAt(start) != 0x27) {
    return null;
  }
  final buf = StringBuffer();
  var j = start + 1;
  while (j < s.length) {
    final c = s.codeUnitAt(j);
    if (c == 0x5C) {
      if (j + 1 >= s.length) {
        return null;
      }
      buf.writeCharCode(s.codeUnitAt(j + 1));
      j += 2;
      continue;
    }
    if (c == 0x27) {
      return (buf.toString(), j + 1);
    }
    buf.writeCharCode(c);
    j++;
  }
  return null;
}

String _emitYaml(List<MapEntry<String, List<String>>> cases) {
  final buf = StringBuffer();
  buf.writeln(
    '# Tech effect summary lines for the tech tree dialog and show_tech CLI.',
  );
  buf.writeln(
    '# Source: generated from tech_tree_widget _effectSummary switch (issue #1748).',
  );
  buf.writeln(
    '# Edit this file for copy changes; run: dart tool/generate_tech_effect_l10n.dart',
  );
  buf.writeln('version: 1');
  buf.writeln('lines:');

  final byTech = <String, List<String>>{};

  for (final e in cases) {
    final techId = e.key;
    final keys = <String>[];
    for (var i = 0; i < e.value.length; i++) {
      final text = e.value[i];
      final safeId = _lineId(techId, i);
      keys.add(safeId);
      buf.writeln('  $safeId:');
      buf.writeln('    en: ${_yamlString(text)}');
    }
    byTech[techId] = keys;
  }

  buf.writeln('by_tech:');
  for (final e in cases) {
    final keys = byTech[e.key]!;
    if (keys.isEmpty) {
      continue;
    }
    buf.writeln('  ${e.key}:');
    for (final k in keys) {
      buf.writeln('    - $k');
    }
  }

  return buf.toString();
}

String _lineId(String techId, int indexInTech) =>
    'techEffectSummary_${techId}_$indexInTech';

String _yamlString(String s) {
  if (s.contains('\n')) {
    final indented = s.split('\n').join('\n      ');
    return '|\n      $indented';
  }
  final escaped = s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}
