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
  }
}

const Key kTileContextRadialKey = Key('tile_context_radial');
const Key kTileRadialMoreKey = Key('tile_radial_spoke_more');
const Key kTileRadialExploreKey = Key('tile_radial_spoke_explore');
const Key kTileRadialProspectKey = Key('tile_radial_spoke_prospect');
const Key kTileRadialBuildImprovementKey = Key(
  'tile_radial_spoke_build_improvement',
);
const Key kTileMoreActionsDialogKey = Key('tile_more_actions_dialog');
const Key kTileMoreProvinceDetailsKey = Key('tile_more_province_details');
