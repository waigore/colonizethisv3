import 'package:colonizethis_app/features/game/flame/controls/map_tile_sight.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_overlay_tooltips.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_designation.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';

Widget buildRevealedProvincePoliticalSection({
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String regionId,
  required String humanPlayerId,
  required Orders draftOrders,
  required Province? province,
  String? selectedTileKey,
  required bool showUpgradeTownControl,
  required bool upgradeTownEnabled,
  required bool upgradeTownHasBuilderUnits,
  required String? upgradeTownTargetTileKey,
  VoidCallback? onUpgradeTownTap,
  required bool showEstablishConsulateControl,
  required bool establishConsulateEnabled,
  required bool establishConsulatePending,
  required String? establishConsulateRejectionReason,
  VoidCallback? onEstablishConsulateTap,
  required bool showOwnerStanding,
  required bool ownerStandingAtWar,
  required bool showOwnerAllianceBadge,
  required bool showOfferPeaceControl,
  required bool offerPeaceEnabled,
  required bool offerPeacePending,
  String? offerPeaceRejectionReason,
  VoidCallback? onOfferPeaceTap,
  required bool isNarrow,
}) {
  return buildPoliticalSection(
    l10n: l10n,
    name: province?.displayName ?? provinceId,
    ownerName: ownerNameForProvinceOverlay(l10n, game, province?.ownerId),
    sightPhrase: mapTileSightPhraseForSelectedTile(
      l10n: l10n,
      region: region,
      selectedTileKey: selectedTileKey,
    ),
    regionLabel: provinceOverlayRegionLabel(l10n, regionId),
    isCapital: provinceOverlayIsCapital(game, provinceId),
    townDevelopmentLevel:
        province?.townDevelopmentLevel ?? kTownDevelopmentLevelMin,
    showUpgradeTownControl: showUpgradeTownControl,
    upgradeTownEnabled: upgradeTownEnabled,
    upgradeTownTooltip: upgradeTownTargetTileKey == null
        ? ''
        : provinceOverlayPoliticalUpgradeTownTooltip(
            l10n: l10n,
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: draftOrders,
            townTileKey: upgradeTownTargetTileKey,
            enabled: upgradeTownEnabled,
            hasBuilderUnits: upgradeTownHasBuilderUnits,
          ),
    onUpgradeTownTap: onUpgradeTownTap,
    showEstablishConsulateControl: showEstablishConsulateControl,
    establishConsulateEnabled: establishConsulateEnabled,
    establishConsulatePending: establishConsulatePending,
    establishConsulateRejectionReason: establishConsulateRejectionReason,
    onEstablishConsulateTap: onEstablishConsulateTap,
    showOwnerStanding: showOwnerStanding,
    ownerStandingAtWar: ownerStandingAtWar,
    showOwnerAllianceBadge: showOwnerAllianceBadge,
    showOfferPeaceControl: showOfferPeaceControl,
    offerPeaceEnabled: offerPeaceEnabled,
    offerPeacePending: offerPeacePending,
    offerPeaceRejectionReason: offerPeaceRejectionReason,
    onOfferPeaceTap: onOfferPeaceTap,
    isNarrow: isNarrow,
  );
}
