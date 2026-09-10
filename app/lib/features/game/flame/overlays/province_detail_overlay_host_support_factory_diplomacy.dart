import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../map_state/game_map_area_province_action_states_establish_consulate.dart';
import '../map_state/game_map_area_province_action_states_establish_embassy.dart';
import '../map_state/game_map_area_province_action_states_grant_subsidy.dart';
import '../map_state/game_map_area_province_action_states_offer_peace.dart';
import '../map_state/game_map_area_state_logic.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_support.dart'
    show isProvinceSeaZoneOverlaySeaZone;
import 'province_detail_overlay_host_support_display.dart';

typedef ProvinceDetailDiplomacyShortcutBundle = ({
  ProvinceEstablishConsulateActionState establishConsulateState,
  String establishConsulateTargetName,
  ProvinceEstablishEmbassyActionState establishEmbassyState,
  String establishEmbassyTargetName,
  bool isSeaZone,
  ProvinceOwnerStandingOfferPeaceState offerPeaceState,
  String offerPeaceTargetName,
  ProvinceGrantSubsidyActionState grantAidState,
  ProvinceGrantSubsidyActionState setSubsidyState,
});

/// Consulate / Embassy / Offer Peace / Grant / Subsidy overlay states.
/// Refs #4346, #4739, #4479, #4761.
ProvinceDetailDiplomacyShortcutBundle resolveProvinceDetailDiplomacyShortcuts({
  required ct_models.Game game,
  required String humanPlayerId,
  required String displayId,
  required RegionMapViewData region,
  required GameMapData? mapData,
  required ct_models.Orders draftOrders,
}) {
  final topology = mapData?.combinedTopology;
  final establishConsulateState =
      GameMapAreaStateLogicProvinceActions.provinceEstablishConsulateActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        topology: topology,
        currentOrders: draftOrders,
      );
  final establishEmbassyState =
      GameMapAreaStateLogicProvinceActions.provinceEstablishEmbassyActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        topology: topology,
        currentOrders: draftOrders,
      );
  final isSeaZone = isProvinceSeaZoneOverlaySeaZone(region, displayId);
  final offerPeaceState =
      GameMapAreaStateLogicProvinceActions.provinceOfferPeaceActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        topology: topology,
        currentOrders: draftOrders,
        isSeaZone: isSeaZone,
      );
  final grantAidState =
      GameMapAreaStateLogicProvinceActions.provinceGrantAidActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        topology: topology,
        currentOrders: draftOrders,
      );
  final setSubsidyState =
      GameMapAreaStateLogicProvinceActions.provinceSetSubsidyActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        topology: topology,
        currentOrders: draftOrders,
      );
  return (
    establishConsulateState: establishConsulateState,
    establishConsulateTargetName: resolveProvinceDetailFactionDisplayName(
      game,
      establishConsulateState.ownerId,
    ),
    establishEmbassyState: establishEmbassyState,
    establishEmbassyTargetName: resolveProvinceDetailFactionDisplayName(
      game,
      establishEmbassyState.ownerId,
    ),
    isSeaZone: isSeaZone,
    offerPeaceState: offerPeaceState,
    offerPeaceTargetName: resolveProvinceDetailFactionDisplayName(
      game,
      offerPeaceState.ownerId,
    ),
    grantAidState: grantAidState,
    setSubsidyState: setSubsidyState,
  );
}
