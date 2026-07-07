// GENERATED FILE — do not edit by hand.
// Run: dart tool/generate_tech_effect_l10n.dart
// Then: cd app && flutter gen-l10n

import 'package:colonizethis_app/l10n/l10n.dart';

part 'tech_effect_summary_lookup_entries_0.dart';
part 'tech_effect_summary_lookup_entries_1.dart';
part 'tech_effect_summary_lookup_entries_2.dart';
part 'tech_effect_summary_lookup_entries_3.dart';

/// Resolves a tech effect line id from [tech_effect_summary.yaml] via [AppLocalizations].
String lookupTechEffectSummaryLine(AppLocalizations l10n, String lineId) {
  final fn = _techEffectSummaryL10n[lineId];
  return fn != null ? fn(l10n) : lineId;
}

final Map<String, String Function(AppLocalizations)> _techEffectSummaryL10n = {
  ..._techEffectSummaryL10nChunk0(),
  ..._techEffectSummaryL10nChunk1(),
  ..._techEffectSummaryL10nChunk2(),
  ..._techEffectSummaryL10nChunk3(),
};

