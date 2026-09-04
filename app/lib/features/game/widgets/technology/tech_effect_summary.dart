// Shared tech effect-summary line builder for Tree, Choose-tech, and
// OVL70001 research-complete feed rows.
// SPEC/ui/technology-panel.md § Choose-tech dialog; SPEC/ui/tech-tree-widget.md;
// SPEC/ui/player-turn-event-feed.md. Refs #4222, #4724.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'tech_ui_helpers.dart';

/// Maximum effect lines on the Choose-tech default row before Details (Refs #4222).
/// Same cap for OVL70001 research-complete feed gist (Refs #4724).
const int kChooseTechDefaultEffectLineCap = 2;

/// Safe fallback when [techId] is absent from the catalog (Refs #4724).
const String kResearchCompleteUnknownFallback =
    'Research complete — technology unlocked!';

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

/// OVL70001 research-complete row text: display name plus up to [effectLineCap]
/// effect clauses from [buildTechEffectSummaryLines], joined with ` · `.
/// Catalog-unknown [techId] returns [kResearchCompleteUnknownFallback] with no
/// raw id and no invented effect gist (Refs #4724).
String formatResearchCompleteFeedLine(
  AppLocalizations l10n,
  String techId, {
  int effectLineCap = kChooseTechDefaultEffectLineCap,
}) {
  final tech = techById(techId);
  if (tech == null) {
    return kResearchCompleteUnknownFallback;
  }
  final title = 'Research complete: ${techDisplayName(techId)} unlocked';
  final effects = buildTechEffectSummaryLines(l10n, tech)
      .take(effectLineCap < 0 ? 0 : effectLineCap)
      .toList(growable: false);
  if (effects.isEmpty) {
    return title;
  }
  return '$title · ${effects.join(' · ')}';
}
