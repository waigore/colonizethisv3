/// Catalog layout + spoke views for [GameMapTileRadialHost].
///
/// SPEC: `SPEC/ui/tile-context-radial.md`, `SPEC/ui/components/tile-radial-catalog.md`
/// (Refs #4440, #4570, #4680 compute-once).
library;

import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_improvement_next_yield_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/explore_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/prospect_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/purchase_land_payoff_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/transport_step_yield_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/upgrade_town_payoff_copy.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:flutter/widgets.dart';

import 'tile_radial_host_catalog_context.dart';
import 'tile_radial_catalog.dart';
import 'tile_radial_keys.dart';
import 'tile_radial_spoke_view.dart';
import 'tile_radial_tooltips.dart';
import 'tile_radial_train_civilian.dart';

export 'tile_radial_host_catalog_context.dart'
    show
        TileRadialHostCatalogContext,
        TileRadialUpgradeTownState,
        computeTileRadialHostCatalogContext;

/// Ranked wedges / More remainder from overlay action visibility.
TileRadialCatalogLayout tileRadialHostCatalogLayout({
  required TileRadialHostCatalogContext catalogContext,
  required String tileKey,
  required ct_models.Game game,
  required String humanPlayerId,
  required ct_models.Orders draftOrders,
}) {
  return rankTileRadialCatalog(
    visibility: tileRadialTrainAwareVisibility(
      catalogContext: catalogContext,
      tileKey: tileKey,
      game: game,
      humanPlayerId: humanPlayerId,
      draftOrders: draftOrders,
    ),
  );
}

/// Label + tooltip views for ranked spokes.
List<TileRadialSpokeView> tileRadialHostSpokeViews({
  required BuildContext context,
  required AppLocalizations l10n,
  required ct_models.Game game,
  required String humanPlayerId,
  required String tileKey,
  required ct_models.Orders draftOrders,
  required TileRadialHostCatalogContext catalogContext,
  required List<TileRadialSpoke> spokes,
}) {
  final states = catalogContext.states;
  final upgradeTown = catalogContext.upgradeTown;
  final provinceId = catalogContext.provinceId;
  final mapData = catalogContext.mapData;
  bool hasMatchingUnits(TileRadialCatalogAction action) {
    switch (action) {
      case TileRadialCatalogAction.explore:
        return states.explore.hasMatchingUnits;
      case TileRadialCatalogAction.prospect:
        return states.prospect.hasMatchingUnits;
      case TileRadialCatalogAction.buildImprovement:
        return states.buildImprovement.hasMatchingUnits;
      case TileRadialCatalogAction.buildRoad:
        return states.buildRoad.hasMatchingUnits;
      case TileRadialCatalogAction.purchaseLand:
        return states.purchaseLand.hasMatchingUnits;
      case TileRadialCatalogAction.upgradeTown:
        return upgradeTown.hasBuilderUnits;
      case TileRadialCatalogAction.buildPort:
        return states.buildPort.hasMatchingUnits;
      case TileRadialCatalogAction.buildRail:
        return states.buildRail.hasMatchingUnits;
      case TileRadialCatalogAction.buildFort:
        return states.buildFort.hasMatchingUnits;
    }
  }

  return [
    for (final spoke in spokes)
      applyTileRadialTrainCivilianView(
        l10n: l10n,
        offerTrain: tileRadialOffersTrainCivilian(
          action: spoke.action,
          catalogContext: catalogContext,
          game: game,
          humanPlayerId: humanPlayerId,
          tileKey: tileKey,
          draftOrders: draftOrders,
        ),
        view: TileRadialSpokeView(
          action: spoke.action,
          enabled: spoke.enabled,
          label: tileRadialActionLabel(l10n, spoke.action),
          tooltip: tileRadialActionTooltip(
            context: context,
            l10n: l10n,
            action: spoke.action,
            game: game,
            humanPlayerId: humanPlayerId,
            tileKey: tileKey,
            provinceId: provinceId,
            currentOrders: draftOrders,
            enabled: spoke.enabled,
            hasMatchingUnits: hasMatchingUnits(spoke.action),
          ),
          caption: switch (spoke.action) {
            TileRadialCatalogAction.explore => explorePayoffGistForTile(
              l10n: l10n,
              game: game,
              tileKey: tileKey,
              enabled: spoke.enabled,
            ),
            TileRadialCatalogAction.prospect => prospectPayoffGistForTile(
              l10n: l10n,
              game: game,
              tileKey: tileKey,
              enabled: spoke.enabled,
            ),
            TileRadialCatalogAction.buildImprovement =>
              buildImprovementNextYieldGistForTile(
                l10n: l10n,
                game: game,
                humanPlayerId: humanPlayerId,
                tileKey: tileKey,
                enabled: spoke.enabled,
                mapData: mapData,
              ),
            TileRadialCatalogAction.purchaseLand =>
              purchaseLandPayoffCopyForTile(
                l10n: l10n,
                game: game,
                tileKey: tileKey,
                enabled: spoke.enabled,
              )?.gist,
            TileRadialCatalogAction.buildRoad => transportStepYieldGistForTile(
              l10n: l10n,
              game: game,
              humanPlayerId: humanPlayerId,
              tileKey: tileKey,
              workTarget: kWorkTargetBuildRoad,
              enabled: spoke.enabled,
              mapData: mapData,
            ),
            TileRadialCatalogAction.buildPort => transportStepYieldGistForTile(
              l10n: l10n,
              game: game,
              humanPlayerId: humanPlayerId,
              tileKey: tileKey,
              workTarget: kWorkTargetBuildPort,
              enabled: spoke.enabled,
              mapData: mapData,
            ),
            TileRadialCatalogAction.buildRail => transportStepYieldGistForTile(
              l10n: l10n,
              game: game,
              humanPlayerId: humanPlayerId,
              tileKey: tileKey,
              workTarget: kWorkTargetBuildRail,
              enabled: spoke.enabled,
              mapData: mapData,
            ),
            TileRadialCatalogAction.buildFort => buildFortPayoffGistForTile(
              l10n: l10n,
              game: game,
              humanPlayerId: humanPlayerId,
              tileKey: tileKey,
              enabled: spoke.enabled,
            ),
            TileRadialCatalogAction.upgradeTown => upgradeTownPayoffGistForTile(
              l10n: l10n,
              game: game,
              humanPlayerId: humanPlayerId,
              tileKey: tileKey,
              enabled: spoke.enabled,
              mapData: mapData,
            ),
          },
        ),
      ),
  ];
}
