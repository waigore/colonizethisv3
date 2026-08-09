// Reads packages/colonizethis_data/lib/src/data/tech_effect_summary.yaml and writes
// packages/colonizethis_data/lib/src/tech_effect_summary_embed.gen.dart (const string).
//
// Run from repo root: dart tool/embed_tech_effect_summary.dart

import 'dart:io';

void main() {
  final root = _findRepoRoot();
  final yamlFile = File(
    '$root/packages/colonizethis_data/lib/src/data/tech_effect_summary.yaml',
  );
  final outFile = File(
    '$root/packages/colonizethis_data/lib/src/tech_effect_summary_embed.gen.dart',
  );
  final yaml = yamlFile.readAsStringSync();
  if (yaml.contains("'''")) {
    throw StateError(
      'YAML contains triple-single-quote; escape embed generator',
    );
  }
  final buf = StringBuffer();
  buf.writeln('// GENERATED FILE — do not edit by hand.');
  buf.writeln("// Run: dart tool/embed_tech_effect_summary.dart");
  buf.writeln();
  buf.writeln("/// Raw YAML for tech effect summary (colonizethis_data).");
  buf.writeln("const String kTechEffectSummaryYaml = r'''");
  buf.write(yaml);
  if (!yaml.endsWith('\n')) {
    buf.writeln();
  }
  buf.writeln("''';");
  outFile.writeAsStringSync(buf.toString());
  stderr.writeln('Wrote ${outFile.path}');
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
      throw StateError('Could not find repo root');
    }
    dir = parent;
  }
}
