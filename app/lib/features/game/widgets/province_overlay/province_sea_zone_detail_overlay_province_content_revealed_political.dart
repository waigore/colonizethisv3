import 'package:colonizethis_app/features/game/flame/controls/map_tile_sight.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_control.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_offer.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/upgrade_town_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_overlay_tooltips.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_designation.dart';
import 'province_sea_zone_detail_overlay_grant_subsidy_props.dart';
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
  Map<String, int> townProductionBonusByCommodity = const {},
  Map<String, int> nextTownProductionBonusByCommodity = const {},
  VoidCallback? onUpgradeTownTap,
  VoidCallback? onTrainCivilianTap,
  required bool showEstablishConsulateControl,
  required bool establishConsulateEnabled,
  required bool establishConsulatePending,
  required String? establishConsulateRejectionReason,
  VoidCallback? onEstablishConsulateTap,
  bool showEstablishEmbassyControl = false,
  bool establishEmbassyEnabled = false,
  bool establishEmbassyPending = false,
  String? establishEmbassyRejectionReason,
  VoidCallback? onEstablishEmbassyTap,
  required bool showOwnerStanding,
  required bool ownerStandingAtWar,
  required bool showOwnerAllianceBadge,
  required bool showOfferPeaceControl,
  required bool offerPeaceEnabled,
  required bool offerPeacePending,
  String? offerPeaceRejectionReason,
  VoidCallback? onOfferPeaceTap,
  ProvinceOverlayGrantSubsidyProps grantSubsidy =
      kProvinceOverlayGrantSubsidyHidden,
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
    upgradeTownPayoffGist: upgradeTownTargetTileKey == null
        ? null
        : upgradeTownPayoffGistForTile(
            l10n: l10n,
            game: game,
            humanPlayerId: humanPlayerId,
            tileKey: upgradeTownTargetTileKey,
            enabled: upgradeTownEnabled,
            currentBonus: townProductionBonusByCommodity,
            nextBonus: nextTownProductionBonusByCommodity,
          ),
    onUpgradeTownTap: onUpgradeTownTap,
    upgradeTownTrainControl: upgradeTownTargetTileKey == null
        ? null
        : buildMapTrainCivilianControl(
            l10n: l10n,
            kind: MapTrainCivilianKind.builder,
            show: offerMapTrainCivilian(
              showIcon: showUpgradeTownControl,
              hasMatchingUnits: upgradeTownHasBuilderUnits,
              otherNonUnitGateApplies:
                  mapTrainUpgradeTownTechGateApplies(
                    game: game,
                    humanPlayerId: humanPlayerId,
                  ) ||
                  mapTrainWorkAffordGateApplies(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    currentOrders: draftOrders,
                    tileKey: upgradeTownTargetTileKey,
                    workTarget: kWorkTargetUpgradeTown,
                  ),
              trainTapAvailable: onTrainCivilianTap != null,
            ),
            onTap: onTrainCivilianTap,
          ),
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
    grantSubsidy: grantSubsidy,
    isNarrow: isNarrow,
  );
}
