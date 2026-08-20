/// Purchase-land overlay tooltip. SPEC/ui/civilian-units-panel.md.
///
/// Split from `work_order_afford_overlay_tooltips.dart` for file-size headroom
/// (Refs #4534). Public signature is unchanged.
library;

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

String provinceOverlayPurchaseLandTooltip({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required Orders currentOrders,
  required String selectedTileKey,
  required String provinceId,
  required bool enabled,
  required bool hasMatchingUnits,
}) {
  if (!hasMatchingUnits) {
    return l10n.provinceOverlay_tilePurchaseLandDisabledNoMerchantTooltip;
  }
  final province = game.worldState.tryGetProvince(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId != null && ownerId.isNotEmpty && ownerId != humanPlayerId) {
    final rel = getRelation(game, humanPlayerId, ownerId);
    final overture = getOverture(game, humanPlayerId, ownerId);
    if (!enabled &&
        (rel?.atWar == true || overture == null || !overture.hasEmbassy)) {
      return l10n.provinceOverlay_tilePurchaseLandDisabledEmbassyTooltip;
    }
  }
  final preview = previewWorkOrderAffordAtTile(
    game: game,
    playerId: humanPlayerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetPurchaseLand,
    targetTileKey: selectedTileKey,
  );
  if (!enabled &&
      preview.hasCostPreview &&
      !preview.canAfford &&
      preview.treasuryShortfall != null) {
    return l10n.provinceOverlay_tilePurchaseLandDisabledTreasuryTooltip(
      preview.treasuryShortfall!,
    );
  }
  if (enabled && preview.treasuryAmount != null) {
    return l10n.provinceOverlay_tilePurchaseLandTooltipWithCost(
      preview.treasuryAmount!,
    );
  }
  return l10n.provinceOverlay_tilePurchaseLandTooltip;
}
