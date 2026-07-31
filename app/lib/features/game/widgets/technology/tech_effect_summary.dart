// Shared tech effect-summary line builder for Tree and Choose-tech surfaces.
// SPEC/ui/technology-panel.md § Choose-tech dialog; SPEC/ui/tech-tree-widget.md.
// Refs #4222.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'tech_ui_helpers.dart';

/// Maximum effect lines on the Choose-tech default row before Details (Refs #4222).
const int kChooseTechDefaultEffectLineCap = 2;

/// Human-readable label for regiment/ship unlock ids (underscore tokens).
String humanizeTechUnlockId(String id) {
  if (id.isEmpty) return id;
  return id
      .split('_')
      .map(
        (s) => s.isEmpty
            ? s
            : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}',
      )
      .join(' ');
}

/// Plain-language effect lines for [tech], matching the Tree description dialog.
List<String> buildTechEffectSummaryLines(
  AppLocalizations l10n,
  TechDefinition tech,
) {
  final list = <String>[];
  for (final rid in tech.regimentUnlockIds) {
    list.add(l10n.techEffect_unlocksRegiment(humanizeTechUnlockId(rid)));
  }
  for (final sid in tech.shipUnlockIds) {
    list.add(l10n.techEffect_unlocksShip(humanizeTechUnlockId(sid)));
  }
  for (final lineId in techEffectSummaryLineIdsFor(tech.id)) {
    list.add(lookupTechEffectSummaryLine(l10n, lineId));
  }
  if (list.isEmpty) {
    list.add(
      l10n.techEffect_fallbackCategoryImprovement(
        techCategoryLabelL10n(l10n, tech.category),
      ),
    );
  }
  return list;
}
