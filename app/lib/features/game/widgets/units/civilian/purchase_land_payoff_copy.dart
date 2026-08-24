/// Display-only Purchase land payoff gist. SPEC/ui/province-sea-zone-detail-overlay.md
/// (Refs #4630). Does not change purchase, extraction, or market rules.
library;

import 'package:colonizethis_app/core/utils/faction_display_name.dart';
import 'package:colonizethis_app/widgets/commodity_display_name.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Player-facing gist plus whether the tile is riches (no Trade / first-bid claim).
class PurchaseLandPayoffCopy {
  const PurchaseLandPayoffCopy({required this.gist, required this.isRiches});

  final String gist;
  final bool isRiches;
}

/// Qualitative payoff line. Privileges start when the one-turn work finishes.
String purchaseLandPayoffGistLine({
  required AppLocalizations l10n,
  required String resourceName,
  required String courtName,
  required bool isRiches,
}) {
  if (isRiches) {
    return l10n.provinceOverlay_tilePurchaseLandPayoffRiches(
      resourceName,
      courtName,
    );
  }
  return l10n.provinceOverlay_tilePurchaseLandPayoffTradeable(
    resourceName,
    courtName,
  );
}

/// Resolves gist for a legal human Purchase land target, or null to hide.
PurchaseLandPayoffCopy? purchaseLandPayoffCopyForTile({
  required AppLocalizations l10n,
  required Game game,
  required String tileKey,
  required bool enabled,
  bool canMutateViaUi = true,
}) {
  if (!enabled || !canMutateViaUi) return null;
  final resourceId = game.worldState.resourceByTileKey[tileKey];
  if (resourceId == null || resourceId.isEmpty) return null;
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return null;
  final province = game.worldState.tryGetProvince(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId == null || ownerId.isEmpty || !isMinorOrTribe(game, ownerId)) {
    return null;
  }
  final isRiches = richesCommodityIds.contains(resourceId);
  final gist = purchaseLandPayoffGistLine(
    l10n: l10n,
    resourceName: commodityDisplayName(l10n, resourceId),
    courtName: displayNameForFaction(game, ownerId),
    isRiches: isRiches,
  );
  return PurchaseLandPayoffCopy(gist: gist, isRiches: isRiches);
}

/// Tooltip teaching sentence for tradeable tiles (Trade First right gist).
String? purchaseLandPayoffTeachingTooltip({
  required AppLocalizations l10n,
  required PurchaseLandPayoffCopy copy,
}) {
  if (copy.isRiches) return null;
  return l10n.tradeMarket_firstRightTooltip;
}
