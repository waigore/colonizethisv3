/// Structured tech effect-summary data for the tech tree dialog and show_tech.
/// Source: `lib/src/data/tech_effect_summary.yaml` (embedded in [kTechEffectSummaryYaml]).

import 'package:yaml/yaml.dart';

import 'tech_effect_summary_embed.gen.dart';

/// Tech ids that have at least one authored effect-summary line in YAML `by_tech`.
Iterable<String> get techEffectSummaryAuthoredTechIds =>
    _techEffectSummaryData.lineIdsByTechId.keys;

/// Line ids (ARB keys) for [techId], in display order. Empty if the catalog tech
/// has no authored summary lines (caller may show a category fallback).
List<String> techEffectSummaryLineIdsFor(String techId) =>
    _techEffectSummaryData.lineIdsByTechId[techId] ?? const [];

/// English text for [lineId] (same value as template `en` in the YAML / ARB).
String techEffectSummaryMessageEn(String lineId) =>
    _techEffectSummaryData.enByLineId[lineId] ?? lineId;

final TechEffectSummaryData _techEffectSummaryData = _loadTechEffectSummary();

TechEffectSummaryData _loadTechEffectSummary() {
  final root = loadYaml(kTechEffectSummaryYaml);
  if (root is! YamlMap) {
    throw FormatException('tech_effect_summary: expected YAML map at root');
  }
  final linesMap = root['lines'];
  if (linesMap is! YamlMap) {
    throw FormatException('tech_effect_summary: missing lines map');
  }
  final byTech = root['by_tech'];
  if (byTech is! YamlMap) {
    throw FormatException('tech_effect_summary: missing by_tech map');
  }

  final enByLineId = <String, String>{};
  for (final entry in linesMap.entries) {
    final id = entry.key;
    if (id is! String) {
      continue;
    }
    final v = entry.value;
    if (v is! YamlMap) {
      throw FormatException('tech_effect_summary: line $id must be a map');
    }
    final en = v['en'];
    if (en is! String) {
      throw FormatException('tech_effect_summary: line $id missing en string');
    }
    enByLineId[id] = en;
  }

  final lineIdsByTechId = <String, List<String>>{};
  for (final entry in byTech.entries) {
    final techId = entry.key;
    if (techId is! String) {
      continue;
    }
    final v = entry.value;
    if (v is! YamlList) {
      throw FormatException(
        'tech_effect_summary: by_tech.$techId must be a list',
      );
    }
    final ids = <String>[];
    for (final item in v) {
      if (item is String) {
        ids.add(item);
      }
    }
    lineIdsByTechId[techId] = ids;
  }

  for (final entry in lineIdsByTechId.entries) {
    for (final lineId in entry.value) {
      if (!enByLineId.containsKey(lineId)) {
        throw FormatException(
          'tech_effect_summary: unknown line id $lineId for tech ${entry.key}',
        );
      }
    }
  }

  return TechEffectSummaryData(
    enByLineId: enByLineId,
    lineIdsByTechId: lineIdsByTechId,
  );
}

/// Parsed tech effect summary tables (immutable).
class TechEffectSummaryData {
  const TechEffectSummaryData({
    required this.enByLineId,
    required this.lineIdsByTechId,
  });

  final Map<String, String> enByLineId;
  final Map<String, List<String>> lineIdsByTechId;
}
