/// Display-only Prospect payoff gist. Refs #4741.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:flutter/widgets.dart';

import 'prospect_payoff_gist_line.dart';

export 'prospect_payoff_gist_line.dart';

/// Localized one-line gist for tile mineral-known clause and Prospect duration.
String prospectPayoffGistLine({
  required AppLocalizations l10n,
  required int turns,
}) {
  return l10n.provinceOverlay_tileProspectPayoffGist(turns);
}

/// Resolves gist when Prospect is enabled for a legal target tile.
///
/// Duration **N** comes from [previewTotalTurnsForPendingWorkOrder] for a
/// synthetic `prospect` order on [tileKey] — do not hardcode `1`.
String? prospectPayoffGistForTile({
  required AppLocalizations l10n,
  required Game game,
  required String tileKey,
  required bool enabled,
  bool canMutateViaUi = true,
}) {
  if (!enabled || !canMutateViaUi) return null;
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null || provinceId.isEmpty) return null;
  const previewUnitId = '_prospect_payoff_preview';
  final turns = previewTotalTurnsForPendingWorkOrder(
    game: game,
    unit: Unit(
      id: previewUnitId,
      type: kUnitTypeExplorer,
      ownerId: previewUnitId,
      locationProvinceId: provinceId,
      tileKey: tileKey,
    ),
    order: WorkOrder(
      unitId: previewUnitId,
      target: kWorkTargetProspect,
      targetTileKey: tileKey,
    ),
  );
  return prospectPayoffGistLine(l10n: l10n, turns: turns);
}

/// Pending `prospect` gist widgets, or empty when hidden / not Prospect.
List<Widget> prospectPayoffPendingGistChildren(
  AppLocalizations l10n,
  Game game,
  WorkOrder pendingWork,
  bool readOnly,
) {
  if (pendingWork.target != kWorkTargetProspect) return const [];
  final gist = prospectPayoffGistForTile(
    l10n: l10n,
    game: game,
    tileKey: pendingWork.targetTileKey,
    enabled: true,
    canMutateViaUi: !readOnly,
  );
  if (gist == null) return const [];
  return [ProspectPayoffGistLine(text: gist)];
}

/// Explorer-shortcut Prospect gist, or null when the tile key is unset.
String? prospectShortcutGist(
  AppLocalizations l10n,
  Game game,
  String? tileKey,
  bool readOnly,
) {
  if (tileKey == null || tileKey.isEmpty) return null;
  return prospectPayoffGistForTile(
    l10n: l10n,
    game: game,
    tileKey: tileKey,
    enabled: true,
    canMutateViaUi: !readOnly,
  );
}
