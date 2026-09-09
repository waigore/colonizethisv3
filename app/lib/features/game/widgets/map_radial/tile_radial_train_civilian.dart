/// Relabel MAP30001 / MAP30002 catalog slots as Train {type} (Refs #4752).
library;

import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_offer.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'tile_radial_catalog.dart';
import 'tile_radial_host_catalog_context.dart';
import 'tile_radial_spoke_view.dart';

bool tileRadialOffersTrainCivilian({
  required TileRadialCatalogAction action,
  required TileRadialHostCatalogContext catalogContext,
  required ct_models.Game game,
  required String humanPlayerId,
  required String tileKey,
  required ct_models.Orders draftOrders,
}) {
  final states = catalogContext.states;
  final upgradeTown = catalogContext.upgradeTown;
  final ownerId = game.worldState
      .tryGetProvince(catalogContext.provinceId)
      ?.ownerId;
  final consulateGated = explorerConsulateGateBlocksMinorTribeProvince(
    game: game,
    playerId: humanPlayerId,
    provinceOwnerId: ownerId,
  );
  switch (action) {
    case TileRadialCatalogAction.explore:
      return offerMapTrainCivilianForState(
        state: states.explore,
        otherNonUnitGateApplies: consulateGated,
        trainTapAvailable: true,
      );
    case TileRadialCatalogAction.prospect:
      return offerMapTrainCivilianForState(
        state: states.prospect,
        otherNonUnitGateApplies: consulateGated,
        trainTapAvailable: true,
      );
    case TileRadialCatalogAction.buildImprovement:
      return offerMapTrainCivilianForState(
        state: states.buildImprovement,
        otherNonUnitGateApplies: mapTrainWorkAffordGateApplies(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: draftOrders,
          tileKey: tileKey,
          workTarget: kWorkTargetBuildImprovement,
        ),
        trainTapAvailable: true,
      );
    case TileRadialCatalogAction.buildRoad:
      return offerMapTrainCivilianForState(
        state: states.buildRoad,
        otherNonUnitGateApplies: mapTrainWorkAffordGateApplies(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: draftOrders,
          tileKey: tileKey,
          workTarget: kWorkTargetBuildRoad,
        ),
        trainTapAvailable: true,
      );
    case TileRadialCatalogAction.purchaseLand:
      return offerMapTrainCivilianForState(
        state: states.purchaseLand,
        otherNonUnitGateApplies:
            mapTrainPurchaseLandEmbassyGateApplies(
              game: game,
              humanPlayerId: humanPlayerId,
              provinceId: catalogContext.provinceId,
            ) ||
            mapTrainWorkAffordGateApplies(
              game: game,
              humanPlayerId: humanPlayerId,
              currentOrders: draftOrders,
              tileKey: tileKey,
              workTarget: kWorkTargetPurchaseLand,
            ),
        trainTapAvailable: true,
      );
    case TileRadialCatalogAction.upgradeTown:
      return offerMapTrainCivilian(
        showIcon: upgradeTown.showControl && upgradeTown.townTileKey == tileKey,
        hasMatchingUnits: upgradeTown.hasBuilderUnits,
        otherNonUnitGateApplies:
            mapTrainUpgradeTownTechGateApplies(
              game: game,
              humanPlayerId: humanPlayerId,
            ) ||
            mapTrainWorkAffordGateApplies(
              game: game,
              humanPlayerId: humanPlayerId,
              currentOrders: draftOrders,
              tileKey: tileKey,
              workTarget: kWorkTargetUpgradeTown,
            ),
        trainTapAvailable: true,
      );
    case TileRadialCatalogAction.buildPort:
      return offerMapTrainCivilianForState(
        state: states.buildPort,
        otherNonUnitGateApplies: mapTrainWorkAffordGateApplies(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: draftOrders,
          tileKey: tileKey,
          workTarget: kWorkTargetBuildPort,
        ),
        trainTapAvailable: true,
      );
    case TileRadialCatalogAction.buildRail:
      return offerMapTrainCivilianForState(
        state: states.buildRail,
        otherNonUnitGateApplies: mapTrainWorkAffordGateApplies(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: draftOrders,
          tileKey: tileKey,
          workTarget: kWorkTargetBuildRail,
        ),
        trainTapAvailable: true,
      );
    case TileRadialCatalogAction.buildFort:
      return offerMapTrainCivilianForState(
        state: states.buildFort,
        otherNonUnitGateApplies: mapTrainWorkAffordGateApplies(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: draftOrders,
          tileKey: tileKey,
          workTarget: kWorkTargetBuildFort,
        ),
        trainTapAvailable: true,
      );
  }
}

Map<TileRadialCatalogAction, TileRadialActionVisibility>
tileRadialTrainAwareVisibility({
  required TileRadialHostCatalogContext catalogContext,
  required String tileKey,
  required ct_models.Game game,
  required String humanPlayerId,
  required ct_models.Orders draftOrders,
}) {
  final states = catalogContext.states;
  final upgradeTown = catalogContext.upgradeTown;
  final upgradeTownOnSelectedTile =
      upgradeTown.showControl && upgradeTown.townTileKey == tileKey;
  bool enabledOrTrain(TileRadialCatalogAction action, bool enabled) {
    return enabled ||
        tileRadialOffersTrainCivilian(
          action: action,
          catalogContext: catalogContext,
          game: game,
          humanPlayerId: humanPlayerId,
          tileKey: tileKey,
          draftOrders: draftOrders,
        );
  }

  return {
    TileRadialCatalogAction.explore: (
      showIcon: states.explore.showIcon,
      enabled: enabledOrTrain(
        TileRadialCatalogAction.explore,
        states.explore.enabled,
      ),
    ),
    TileRadialCatalogAction.prospect: (
      showIcon: states.prospect.showIcon,
      enabled: enabledOrTrain(
        TileRadialCatalogAction.prospect,
        states.prospect.enabled,
      ),
    ),
    TileRadialCatalogAction.buildImprovement: (
      showIcon: states.buildImprovement.showIcon,
      enabled: enabledOrTrain(
        TileRadialCatalogAction.buildImprovement,
        states.buildImprovement.enabled,
      ),
    ),
    TileRadialCatalogAction.buildRoad: (
      showIcon: states.buildRoad.showIcon,
      enabled: enabledOrTrain(
        TileRadialCatalogAction.buildRoad,
        states.buildRoad.enabled,
      ),
    ),
    TileRadialCatalogAction.purchaseLand: (
      showIcon: states.purchaseLand.showIcon,
      enabled: enabledOrTrain(
        TileRadialCatalogAction.purchaseLand,
        states.purchaseLand.enabled,
      ),
    ),
    TileRadialCatalogAction.upgradeTown: (
      showIcon: upgradeTownOnSelectedTile,
      enabled: enabledOrTrain(
        TileRadialCatalogAction.upgradeTown,
        upgradeTownOnSelectedTile && upgradeTown.enabled,
      ),
    ),
    TileRadialCatalogAction.buildPort: (
      showIcon: states.buildPort.showIcon,
      enabled: enabledOrTrain(
        TileRadialCatalogAction.buildPort,
        states.buildPort.enabled,
      ),
    ),
    TileRadialCatalogAction.buildRail: (
      showIcon: states.buildRail.showIcon,
      enabled: enabledOrTrain(
        TileRadialCatalogAction.buildRail,
        states.buildRail.enabled,
      ),
    ),
    TileRadialCatalogAction.buildFort: (
      showIcon: states.buildFort.showIcon,
      enabled: enabledOrTrain(
        TileRadialCatalogAction.buildFort,
        states.buildFort.enabled,
      ),
    ),
  };
}

TileRadialSpokeView applyTileRadialTrainCivilianView({
  required TileRadialSpokeView view,
  required AppLocalizations l10n,
  required bool offerTrain,
}) {
  if (!offerTrain) return view;
  final kind = mapTrainCivilianKindForRadialAction(view.action);
  return TileRadialSpokeView(
    action: view.action,
    enabled: true,
    label: mapTrainCivilianLabel(l10n, kind),
    tooltip: mapTrainCivilianLabel(l10n, kind),
    caption: mapTrainCivilianGist(l10n, kind),
  );
}
