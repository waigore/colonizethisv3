/// Display-only Explore payoff gist. Refs #4733.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Localized one-line gist for province-wide reveal and Explore duration.
String explorePayoffGistLine({
  required AppLocalizations l10n,
  required int turns,
}) {
  return l10n.provinceOverlay_tileExplorePayoffGist(turns);
}

/// Resolves gist when Explore is enabled for a legal target tile.
///
/// Duration **N** comes from [previewTotalTurnsForPendingWorkOrder] for a
/// synthetic `explore` order on [tileKey] — do not re-implement explore turns.
String? explorePayoffGistForTile({
  required AppLocalizations l10n,
  required Game game,
  required String tileKey,
  required bool enabled,
  bool canMutateViaUi = true,
}) {
  if (!enabled || !canMutateViaUi) return null;
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null || provinceId.isEmpty) return null;
  const previewUnitId = '_explore_payoff_preview';
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
      target: kWorkTargetExplore,
      targetTileKey: tileKey,
    ),
  );
  return explorePayoffGistLine(l10n: l10n, turns: turns);
}
