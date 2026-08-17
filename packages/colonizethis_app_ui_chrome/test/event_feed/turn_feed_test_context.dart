import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/foundation.dart';

/// Shared turn-feed context for package tests (Refs #4480).
class TurnFeedTestContext {
  TurnFeedTestContext({
    this.mapPlayerId = 'gp1',
    this.factionLabel = _identityLabel,
    this.provinceLabel = _defaultProvinceLabel,
    this.seaZoneLabel = _identityLabel,
    this.diplomacyOutcomeLine = _defaultDiplomacyOutcomeLine,
    this.isCatalogTech = _alwaysFalse,
    this.researchCompleteLine = _identityLabel,
    this.workTargetLabel = _identityLabel,
    this.overtureStageLabel = _identityLabel,
    this.commodityDisplayName = _identityLabel,
    this.navigateToTechnologyScreen = _noop,
    this.locateProvinceById = _noopString,
    this.locateSeaZoneTile = _noopString,
    this.counterpartFactionId = _defaultCounterpartFactionId,
    this.overtureCounterpartFactionId = _defaultOvertureCounterpartFactionId,
    this.spyCounterpartFactionId = _defaultSpyCounterpartFactionId,
    this.diplomacyDetailTapForFaction = _alwaysNullTap,
    this.provinceOverlayTapForProvince = _alwaysNullTap,
    this.navalCombatTapForSeaZone = _alwaysNullTap,
    this.workOrderCompletedTap = _alwaysNullWorkTap,
    this.overseasProfitCreditedTap,
    this.economyTurnSummaryTap,
    this.orderRejectedTapForKind = _alwaysNullOrderTap,
  });

  final String mapPlayerId;
  final String Function(String id) factionLabel;
  final String Function(String fullProvinceId) provinceLabel;
  final String Function(String seaZoneId) seaZoneLabel;
  final String Function({
    required String actorId,
    required String targetId,
    required String changeType,
  }) diplomacyOutcomeLine;
  final bool Function(String techId) isCatalogTech;
  final String Function(String techId) researchCompleteLine;
  final String Function(String workTarget) workTargetLabel;
  final String Function(String stage) overtureStageLabel;
  final String Function(String commodityId) commodityDisplayName;
  final VoidCallback navigateToTechnologyScreen;
  final void Function(String provinceId) locateProvinceById;
  final void Function(String seaZoneId) locateSeaZoneTile;
  final String? Function({
    required String actorId,
    required String targetId,
  }) counterpartFactionId;
  final String? Function({
    required String offererGpId,
    required String targetFactionId,
  }) overtureCounterpartFactionId;
  final String? Function({
    required String spyOwnerId,
    required String territoryOwnerId,
  }) spyCounterpartFactionId;
  final VoidCallback? Function(String factionId) diplomacyDetailTapForFaction;
  final VoidCallback? Function(String provinceId) provinceOverlayTapForProvince;
  final VoidCallback? Function(String seaZoneId) navalCombatTapForSeaZone;
  final VoidCallback? Function({
    required String unitId,
    required String targetTileKey,
  }) workOrderCompletedTap;
  final VoidCallback? overseasProfitCreditedTap;
  final VoidCallback? economyTurnSummaryTap;
  final VoidCallback? Function(ct_models.OrderKind orderKind)
      orderRejectedTapForKind;

  CtTurnFeedEntryContext build() {
    return CtTurnFeedEntryContext(
      labels: CtTurnFeedEntryLabels(
        mapPlayerId: mapPlayerId,
        factionLabel: factionLabel,
        provinceLabel: provinceLabel,
        seaZoneLabel: seaZoneLabel,
        diplomacyOutcomeLine: diplomacyOutcomeLine,
        isCatalogTech: isCatalogTech,
        researchCompleteLine: researchCompleteLine,
        workTargetLabel: workTargetLabel,
        overtureStageLabel: overtureStageLabel,
        commodityDisplayName: commodityDisplayName,
      ),
      navigation: CtTurnFeedEntryNavigation(
        navigateToTechnologyScreen: navigateToTechnologyScreen,
        locateProvinceById: locateProvinceById,
        locateSeaZoneTile: locateSeaZoneTile,
      ),
      taps: CtTurnFeedEntryTaps(
        counterpartFactionId: counterpartFactionId,
        overtureCounterpartFactionId: overtureCounterpartFactionId,
        spyCounterpartFactionId: spyCounterpartFactionId,
        diplomacyDetailTapForFaction: diplomacyDetailTapForFaction,
        provinceOverlayTapForProvince: provinceOverlayTapForProvince,
        navalCombatTapForSeaZone: navalCombatTapForSeaZone,
        workOrderCompletedTap: workOrderCompletedTap,
        overseasProfitCreditedTap: overseasProfitCreditedTap,
        economyTurnSummaryTap: economyTurnSummaryTap,
        orderRejectedTapForKind: orderRejectedTapForKind,
      ),
    );
  }

  static String _identityLabel(String value) => value;

  static String _defaultProvinceLabel(String id) =>
      id == 'oldWorld|cap' ? 'Capital' : id;

  static String _defaultDiplomacyOutcomeLine({
    required String actorId,
    required String targetId,
    required String changeType,
  }) =>
      '$actorId $changeType $targetId';

  static bool _alwaysFalse(String _) => false;

  static void _noop() {}

  static void _noopString(String _) {}

  static String? _defaultCounterpartFactionId({
    required String actorId,
    required String targetId,
  }) =>
      targetId;

  static String? _defaultOvertureCounterpartFactionId({
    required String offererGpId,
    required String targetFactionId,
  }) =>
      targetFactionId;

  static String? _defaultSpyCounterpartFactionId({
    required String spyOwnerId,
    required String territoryOwnerId,
  }) =>
      spyOwnerId;

  static VoidCallback? _alwaysNullTap(String _) => null;

  static VoidCallback? _alwaysNullWorkTap({
    required String unitId,
    required String targetTileKey,
  }) =>
      null;

  static VoidCallback? _alwaysNullOrderTap(ct_models.OrderKind _) => null;
}

List<CtEventFeedEntry> mapTurnFeedEvents(
  List<ct_models.GameToUIEvent> events,
  TurnFeedTestContext fixture,
) {
  return buildCtTurnFeedEntries(events: events, context: fixture.build());
}

CtEventFeedEntry singleTurnFeedEntry(
  ct_models.GameToUIEvent event,
  TurnFeedTestContext fixture,
) {
  return mapTurnFeedEvents([event], fixture).single;
}
