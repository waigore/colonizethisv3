/// Localized spy research-insight gist lines (Refs #4679).
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/civilian_intel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Returns a muted gist line for [kind], or null when intel-only / N/A.
String? spyResearchInsightGistText({
  required AppLocalizations l10n,
  required SpyResearchInsightGistKind kind,
}) {
  return switch (kind) {
    SpyResearchInsightGistKind.none => null,
    SpyResearchInsightGistKind.maySpeedResearch =>
      l10n.spyResearchInsight_maySpeedResearchGist,
    SpyResearchInsightGistKind.alreadyGrantsInsight =>
      l10n.spyResearchInsight_alreadyGrantsInsightGist,
  };
}

String? spyResearchInsightGistTextForTile({
  required AppLocalizations l10n,
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String tileKey,
}) {
  final kind = spyResearchInsightGistKindForTile(
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
    tileKey: tileKey,
  );
  return spyResearchInsightGistText(l10n: l10n, kind: kind);
}

String? spyResearchInsightGistTextForProvince({
  required AppLocalizations l10n,
  required Game game,
  required Orders orders,
  required String humanPlayerId,
  required String prefixedProvinceId,
}) {
  final kind = spyResearchInsightGistKindForProvince(
    game: game,
    orders: orders,
    humanPlayerId: humanPlayerId,
    prefixedProvinceId: prefixedProvinceId,
  );
  return spyResearchInsightGistText(l10n: l10n, kind: kind);
}
