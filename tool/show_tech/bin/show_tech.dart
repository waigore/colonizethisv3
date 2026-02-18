import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';

void main(List<String> args) {
  final idArg = args.firstWhere(
    (a) => a.startsWith('--id='),
    orElse: () => '',
  );
  if (idArg.isNotEmpty) {
    final id = idArg.substring('--id='.length);
    _printTechDetails(id);
    return;
  }

  _printTechDiagram();
}

void _printTechDiagram() {
  stdout.writeln('# Technology Tree');
  stdout.writeln();

  final byEra = <int, List<TechDefinition>>{};
  for (final tech in techCatalog.values) {
    byEra.putIfAbsent(tech.era, () => <TechDefinition>[]).add(tech);
  }

  final eras = byEra.keys.toList()..sort();
  for (final era in eras) {
    stdout.writeln('## Era $era');
    stdout.writeln();
    final list = byEra[era]!..sort((a, b) => a.id.compareTo(b.id));
    for (final tech in list) {
      final prereqs = tech.prerequisiteIds.isEmpty
          ? '-'
          : tech.prerequisiteIds.join(', ');
      stdout.writeln('- `${tech.id}` *(category: ${tech.category}, cost: ${tech.cost}, prereqs: $prereqs)*');
    }
    stdout.writeln();
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
}

