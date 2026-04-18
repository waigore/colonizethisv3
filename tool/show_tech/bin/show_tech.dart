import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';

String _categoryLabelEn(String category) {
  return switch (category) {
    'gathering' => 'Gathering',
    'transport' => 'Transport',
    'labour' => 'Labour',
    'civilian' => 'Civilian',
    'diplomacy' => 'Diplomacy',
    'naval' => 'Naval',
    'military' => 'Military',
    'new-world' => 'New World',
    _ => category,
  };
}

void main(List<String> args) {
  String? outputPath;
  bool interactive = false;
  String? queryId;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--output' && i + 1 < args.length) {
      outputPath = args[++i];
    } else if (a == '--interactive') {
      interactive = true;
    } else if (a == '--query' && i + 1 < args.length) {
      queryId = args[++i];
    } else if (a.startsWith('--id=')) {
      queryId = a.substring('--id='.length);
    }
  }

  if (queryId != null && queryId.isNotEmpty) {
    _printTechDetails(queryId);
    return;
  }

  if (interactive) {
    _runInteractive();
    return;
  }

  _printTechDiagram(outputPath: outputPath);
}

void _printTechDiagram({String? outputPath}) {
  final buffer = StringBuffer();
  buffer.writeln('# Technology Tree');
  buffer.writeln();

  final byEra = <int, List<TechDefinition>>{};
  for (final tech in techCatalog.values) {
    byEra.putIfAbsent(tech.era, () => <TechDefinition>[]).add(tech);
  }

  final eras = byEra.keys.toList()..sort();
  for (final era in eras) {
    buffer.writeln('## Era $era');
    buffer.writeln();
    final list = byEra[era]!..sort((a, b) => a.id.compareTo(b.id));
    for (final tech in list) {
      final prereqs = tech.prerequisiteIds.isEmpty
          ? '-'
          : tech.prerequisiteIds.join(', ');
      buffer.writeln(
        '- `${tech.id}` *(category: ${tech.category}, cost: ${tech.cost}, prereqs: $prereqs)*',
      );
    }
    buffer.writeln();
  }

  final out = buffer.toString();
  if (outputPath != null) {
    File(outputPath).writeAsStringSync(out);
  } else {
    stdout.write(out);
  }
}

void _printTechDetails(String id) {
  final tech = techById(id);
  if (tech == null) {
    stderr.writeln('Unknown tech id: $id');
    exitCode = 1;
    return;
  }

  stdout.writeln('# Tech: ${tech.id}');
  stdout.writeln();
  stdout.writeln('- Era: ${tech.era}');
  stdout.writeln('- Category: ${tech.category}');
  stdout.writeln('- Cost: ${tech.cost}');
  stdout.writeln(
    '- Prerequisites: ${tech.prerequisiteIds.isEmpty ? '-' : tech.prerequisiteIds.join(', ')}',
  );
  if (tech.regimentUnlockIds.isNotEmpty) {
    stdout.writeln(
      '- Effects — Unlocks regiments: ${tech.regimentUnlockIds.join(', ')}',
    );
  }
  if (tech.shipUnlockIds.isNotEmpty) {
    stdout.writeln(
      '- Effects — Unlocks ships: ${tech.shipUnlockIds.join(', ')}',
    );
  }
  final lineIds = techEffectSummaryLineIdsFor(tech.id);
  if (lineIds.isNotEmpty) {
    stdout.writeln('- Effect summary:');
    for (final id in lineIds) {
      stdout.writeln('  - ${techEffectSummaryMessageEn(id)}');
    }
  } else if (tech.regimentUnlockIds.isEmpty && tech.shipUnlockIds.isEmpty) {
    stdout.writeln(
      '- Effect summary: Improves ${_categoryLabelEn(tech.category)} capabilities',
    );
  }
  stdout.writeln();
}

void _runInteractive() {
  stdout.writeln('Enter tech id (or empty to exit):');
  while (true) {
    stdout.write('> ');
    final line = stdin.readLineSync();
    final id = line?.trim() ?? '';
    if (id.isEmpty) break;
    final tech = techById(id);
    if (tech == null) {
      stderr.writeln('Unknown tech id: $id');
    } else {
      _printTechDetails(id);
    }
  }
}
