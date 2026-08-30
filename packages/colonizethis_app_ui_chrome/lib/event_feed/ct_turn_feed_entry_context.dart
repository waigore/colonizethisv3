import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/foundation.dart';

/// Label and copy hooks for turn-feed row text.
class CtTurnFeedEntryLabels {
  const CtTurnFeedEntryLabels({
    required this.mapPlayerId,
    required this.factionLabel,
    required this.provinceLabel,
    required this.seaZoneLabel,
    required this.diplomacyOutcomeLine,
    required this.isCatalogTech,
    required this.researchCompleteLine,
    required this.workTargetLabel,
    required this.overtureStageLabel,
    required this.commodityDisplayName,
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
}

/// Map-focus and screen-navigation hooks for turn-feed rows.
class CtTurnFeedEntryNavigation {
  const CtTurnFeedEntryNavigation({
    required this.navigateToTechnologyScreen,
    required this.locateProvinceById,
    required this.locateSeaZoneTile,
  });

  final VoidCallback navigateToTechnologyScreen;
  final void Function(String provinceId) locateProvinceById;
  final void Function(String seaZoneId) locateSeaZoneTile;
}

/// Tap and counterpart-resolution hooks for turn-feed rows.
class CtTurnFeedEntryTaps {
  const CtTurnFeedEntryTaps({
    required this.counterpartFactionId,
    required this.overtureCounterpartFactionId,
    required this.spyCounterpartFactionId,
    required this.diplomacyDetailTapForFaction,
    required this.provinceOverlayTapForProvince,
    required this.navalCombatTapForSeaZone,
    required this.workOrderCompletedTap,
    required this.overseasProfitCreditedTap,
    required this.economyTurnSummaryTap,
    required this.orderRejectedTapForKind,
  });

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
}

/// App-supplied label, navigation, and tap hooks for [buildCtTurnFeedEntries].
class CtTurnFeedEntryContext {
  const CtTurnFeedEntryContext({
    required this.labels,
    required this.navigation,
    required this.taps,
  });

  final CtTurnFeedEntryLabels labels;
  final CtTurnFeedEntryNavigation navigation;
  final CtTurnFeedEntryTaps taps;

  String get mapPlayerId => labels.mapPlayerId;
  String Function(String id) get factionLabel => labels.factionLabel;
  String Function(String fullProvinceId) get provinceLabel =>
      labels.provinceLabel;
  String Function(String seaZoneId) get seaZoneLabel => labels.seaZoneLabel;
  String Function({
    required String actorId,
    required String targetId,
    required String changeType,
  }) get diplomacyOutcomeLine => labels.diplomacyOutcomeLine;
  bool Function(String techId) get isCatalogTech => labels.isCatalogTech;
  String Function(String techId) get researchCompleteLine =>
      labels.researchCompleteLine;
  String Function(String workTarget) get workTargetLabel =>
      labels.workTargetLabel;
  String Function(String stage) get overtureStageLabel =>
      labels.overtureStageLabel;
  String Function(String commodityId) get commodityDisplayName =>
      labels.commodityDisplayName;
  VoidCallback get navigateToTechnologyScreen =>
      navigation.navigateToTechnologyScreen;
  void Function(String provinceId) get locateProvinceById =>
      navigation.locateProvinceById;
  void Function(String seaZoneId) get locateSeaZoneTile =>
      navigation.locateSeaZoneTile;
  String? Function({
    required String actorId,
    required String targetId,
  }) get counterpartFactionId => taps.counterpartFactionId;
  String? Function({
    required String offererGpId,
    required String targetFactionId,
  }) get overtureCounterpartFactionId => taps.overtureCounterpartFactionId;
  String? Function({
    required String spyOwnerId,
    required String territoryOwnerId,
  }) get spyCounterpartFactionId => taps.spyCounterpartFactionId;
  VoidCallback? Function(String factionId) get diplomacyDetailTapForFaction =>
      taps.diplomacyDetailTapForFaction;
  VoidCallback? Function(String provinceId) get provinceOverlayTapForProvince =>
      taps.provinceOverlayTapForProvince;
  VoidCallback? Function(String seaZoneId) get navalCombatTapForSeaZone =>
      taps.navalCombatTapForSeaZone;
  VoidCallback? Function({
    required String unitId,
    required String targetTileKey,
  }) get workOrderCompletedTap => taps.workOrderCompletedTap;
  VoidCallback? get overseasProfitCreditedTap => taps.overseasProfitCreditedTap;
  VoidCallback? get economyTurnSummaryTap => taps.economyTurnSummaryTap;
  VoidCallback? Function(ct_models.OrderKind orderKind)
      get orderRejectedTapForKind => taps.orderRejectedTapForKind;
}
