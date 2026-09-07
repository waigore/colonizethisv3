/// Province vs sea-zone content resolution for [ProvinceSeaZoneDetailOverlay].
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_province_content.dart';
import 'province_sea_zone_detail_overlay_sea_zone_content.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_widget.dart';

extension ProvinceSeaZoneDetailOverlayContent
    on ProvinceSeaZoneDetailOverlay {
  OverlayContent resolveOverlayContent(
    BuildContext context, {
    required bool isNarrow,
  }) {
    final l10n = appL10n(context);
    if (isProvinceSeaZoneOverlaySeaZone(region, displayId)) {
      return seaZoneContent(
        l10n: l10n,
        game: game,
        region: region,
        seaZoneId: displayId,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        selectedTileKey: selectedTileKey,
        navalMission: navalMission,
        transferToHomeFleet: transferToHomeFleet,
        navalCombine: navalCombine,
        sailMove: sailMove,
      );
    }
    return provinceContent(
      context: context,
      l10n: l10n,
      game: game,
      region: region,
      provinceId: displayId,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      draftOrders: draftOrders,
      selectedTileKey: selectedTileKey,
      onHighlightTile: onHighlightTile,
      civilianInlineActions: civilianInlineActions,
      inlineActionCallbacks: inlineActionCallbacks,
      showUpgradeTownControl: showUpgradeTownControl,
      upgradeTownEnabled: upgradeTownEnabled,
      upgradeTownHasBuilderUnits: upgradeTownHasBuilderUnits,
      upgradeTownTargetTileKey: upgradeTownTargetTileKey,
      onUpgradeTownTap: onUpgradeTownTap,
      showMoveArmyControl: showMoveArmyControl,
      moveArmyEnabled: moveArmyEnabled,
      moveArmyTooltip: moveArmyTooltip,
      onMoveArmyTap: onMoveArmyTap,
      showInvadeArmyControl: showInvadeArmyControl,
      invadeArmyEnabled: invadeArmyEnabled,
      invadeArmyTooltip: invadeArmyTooltip,
      onInvadeArmyTap: onInvadeArmyTap,
      showCombineArmiesControl: showCombineArmiesControl,
      combineArmiesEnabled: combineArmiesEnabled,
      combineArmiesTooltip: combineArmiesTooltip,
      onCombineArmiesTap: onCombineArmiesTap,
      navalMission: navalMission,
      detachAndSail: detachAndSail,
      transferToHomeFleet: transferToHomeFleet,
      navalCombine: navalCombine,
      sailMove: sailMove,
      blockadeStatus: blockadeStatus,
      stationSpy: stationSpy,
      counterEspionage: counterEspionage,
      showEstablishConsulateControl: showEstablishConsulateControl,
      establishConsulateEnabled: establishConsulateEnabled,
      establishConsulatePending: establishConsulatePending,
      establishConsulateRejectionReason: establishConsulateRejectionReason,
      onEstablishConsulateTap: onEstablishConsulateTap,
      showEstablishEmbassyControl: showEstablishEmbassyControl,
      establishEmbassyEnabled: establishEmbassyEnabled,
      establishEmbassyPending: establishEmbassyPending,
      establishEmbassyRejectionReason: establishEmbassyRejectionReason,
      onEstablishEmbassyTap: onEstablishEmbassyTap,
      showOwnerStanding: showOwnerStanding,
      ownerStandingAtWar: ownerStandingAtWar,
      showOwnerAllianceBadge: showOwnerAllianceBadge,
      showOfferPeaceControl: showOfferPeaceControl,
      offerPeaceEnabled: offerPeaceEnabled,
      offerPeacePending: offerPeacePending,
      offerPeaceRejectionReason: offerPeaceRejectionReason,
      onOfferPeaceTap: onOfferPeaceTap,
      isNarrow: isNarrow,
      omniscientDetail: omniscientDetail,
      townProductionBonusByCommodity: townProductionBonusByCommodity,
      extractionSnapshot: extractionSnapshot,
      availableByCommodity: availableByCommodity,
      tileConnectivity: tileConnectivity,
      onHighlightTiles: onHighlightTiles,
    );
  }
}
