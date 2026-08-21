/// Player-facing labels for MAP30001 / MAP30002.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

import 'tile_radial_catalog.dart';

String tileRadialActionLabel(
  AppLocalizations l10n,
  TileRadialCatalogAction action,
) {
  switch (action) {
    case TileRadialCatalogAction.explore:
      return l10n.tileRadial_explore;
    case TileRadialCatalogAction.prospect:
      return l10n.tileRadial_prospect;
    case TileRadialCatalogAction.buildImprovement:
      return l10n.tileRadial_buildImprovement;
    case TileRadialCatalogAction.buildRoad:
      return l10n.tileRadial_buildRoad;
    case TileRadialCatalogAction.purchaseLand:
      return l10n.tileRadial_purchaseLand;
    case TileRadialCatalogAction.upgradeTown:
      return l10n.tileRadial_upgradeTown;
    case TileRadialCatalogAction.buildPort:
      return l10n.tileRadial_buildPort;
    case TileRadialCatalogAction.buildRail:
      return l10n.tileRadial_buildRailroad;
    case TileRadialCatalogAction.buildFort:
      return l10n.tileRadial_buildFort;
  }
}

Key tileRadialSpokeKey(TileRadialCatalogAction action) {
  switch (action) {
    case TileRadialCatalogAction.explore:
      return kTileRadialExploreKey;
    case TileRadialCatalogAction.prospect:
      return kTileRadialProspectKey;
    case TileRadialCatalogAction.buildImprovement:
      return kTileRadialBuildImprovementKey;
    case TileRadialCatalogAction.buildRoad:
      return kTileRadialBuildRoadKey;
    case TileRadialCatalogAction.purchaseLand:
      return kTileRadialPurchaseLandKey;
    case TileRadialCatalogAction.upgradeTown:
      return kTileRadialUpgradeTownKey;
    case TileRadialCatalogAction.buildPort:
      return kTileRadialBuildPortKey;
    case TileRadialCatalogAction.buildRail:
      return kTileRadialBuildRailroadKey;
    case TileRadialCatalogAction.buildFort:
      return kTileRadialBuildFortKey;
  }
}

const Key kTileContextRadialKey = Key('tile_context_radial');
const Key kTileRadialMoreKey = Key('tile_radial_spoke_more');
const Key kTileRadialExploreKey = Key('tile_radial_spoke_explore');
const Key kTileRadialProspectKey = Key('tile_radial_spoke_prospect');
const Key kTileRadialBuildImprovementKey = Key(
  'tile_radial_spoke_build_improvement',
);
const Key kTileRadialBuildRoadKey = Key('tile_radial_spoke_build_road');
const Key kTileRadialPurchaseLandKey = Key('tile_radial_spoke_purchase_land');
const Key kTileRadialUpgradeTownKey = Key('tile_radial_spoke_upgrade_town');
const Key kTileRadialBuildPortKey = Key('tile_radial_spoke_build_port');
const Key kTileRadialBuildRailroadKey = Key('tile_radial_spoke_build_railroad');
const Key kTileRadialBuildFortKey = Key('tile_radial_spoke_build_fort');
const Key kTileMoreActionsDialogKey = Key('tile_more_actions_dialog');
const Key kTileMoreProvinceDetailsKey = Key('tile_more_province_details');
