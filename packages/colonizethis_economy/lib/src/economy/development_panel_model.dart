/// Development panel DTOs. Refs #4175.
///
/// SPEC: SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_world/colonizethis_world.dart' show kRegionNewWorld;

/// One improvable commodity row within a province or purchased-land scope.
class DevelopmentImprovableCommodityRow {
  const DevelopmentImprovableCommodityRow({
    required this.commodityId,
    required this.tileKeys,
  });

  final String commodityId;
  final List<String> tileKeys;

  int get count => tileKeys.length;
}

/// Owned province or purchased-land grouping under a source province.
class DevelopmentPanelScopeRow {
  const DevelopmentPanelScopeRow({
    required this.scopeKey,
    required this.provinceId,
    required this.displayName,
    this.provinceOwnerId,
    this.provinceOwnerDisplayName,
    this.isPurchasedLand = false,
    this.improvableCommodities = const [],
  });

  /// Stable list key (province id for owned rows; `purchased:<provinceId>`).
  final String scopeKey;
  final String provinceId;
  final String displayName;
  final String? provinceOwnerId;
  final String? provinceOwnerDisplayName;
  final bool isPurchasedLand;
  final List<DevelopmentImprovableCommodityRow> improvableCommodities;

  bool get hasImprovableResources => improvableCommodities.isNotEmpty;
}

/// Builder/Engineer with pending or in-progress work in the active region.
class DevelopmentAssignedCivilianRow {
  const DevelopmentAssignedCivilianRow({
    required this.unitId,
    required this.unitType,
    required this.workTarget,
    required this.targetTileKey,
    required this.isPending,
    this.remainingTurns,
    this.totalTurns,
  });

  final String unitId;
  final String unitType;
  final String workTarget;
  final String targetTileKey;
  final bool isPending;
  final int? remainingTurns;
  final int? totalTurns;
}

/// Order-independent region slice: scopes and land extraction (Slice E).
class DevelopmentPanelRegionScopes {
  const DevelopmentPanelRegionScopes({
    required this.regionId,
    required this.ownedScopes,
    required this.purchasedScopes,
    required this.landExtractionByCommodity,
  });

  final String regionId;
  final List<DevelopmentPanelScopeRow> ownedScopes;
  final List<DevelopmentPanelScopeRow> purchasedScopes;
  final Map<String, int> landExtractionByCommodity;
}

/// Per-region Development panel projection.
class DevelopmentPanelRegionModel {
  const DevelopmentPanelRegionModel({
    required this.regionId,
    required this.ownedScopes,
    required this.purchasedScopes,
    required this.landExtractionByCommodity,
    required this.idleBuilderCount,
    required this.idleEngineerCount,
    this.assignedCivilians = const [],
  });

  final String regionId;
  final List<DevelopmentPanelScopeRow> ownedScopes;
  final List<DevelopmentPanelScopeRow> purchasedScopes;
  final Map<String, int> landExtractionByCommodity;
  final int idleBuilderCount;
  final int idleEngineerCount;
  final List<DevelopmentAssignedCivilianRow> assignedCivilians;
}

/// Full Development panel read model (both regions).
class DevelopmentPanelModel {
  const DevelopmentPanelModel({
    required this.oldWorld,
    required this.newWorld,
    required this.connectedTileKeys,
  });

  final DevelopmentPanelRegionModel oldWorld;
  final DevelopmentPanelRegionModel newWorld;

  /// Capital-connected tile keys for the human player (single connectivity pass).
  final Set<String> connectedTileKeys;

  DevelopmentPanelRegionModel forRegion(String regionId) =>
      regionId == kRegionNewWorld ? newWorld : oldWorld;
}

/// Placeholder before a lazy region tab is first selected (Slice E).
DevelopmentPanelRegionModel emptyDevelopmentPanelRegionModel(String regionId) =>
    DevelopmentPanelRegionModel(
      regionId: regionId,
      ownedScopes: const [],
      purchasedScopes: const [],
      landExtractionByCommodity: const {},
      idleBuilderCount: 0,
      idleEngineerCount: 0,
    );
