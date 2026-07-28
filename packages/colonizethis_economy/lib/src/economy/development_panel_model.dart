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

/// Per-region Development panel projection.
class DevelopmentPanelRegionModel {
  const DevelopmentPanelRegionModel({
    required this.regionId,
    required this.ownedScopes,
    required this.purchasedScopes,
    required this.landExtractionByCommodity,
    required this.idleBuilderCount,
    required this.idleEngineerCount,
  });

  final String regionId;
  final List<DevelopmentPanelScopeRow> ownedScopes;
  final List<DevelopmentPanelScopeRow> purchasedScopes;
  final Map<String, int> landExtractionByCommodity;
  final int idleBuilderCount;
  final int idleEngineerCount;
}

/// Full Development panel read model (both regions).
class DevelopmentPanelModel {
  const DevelopmentPanelModel({
    required this.oldWorld,
    required this.newWorld,
  });

  final DevelopmentPanelRegionModel oldWorld;
  final DevelopmentPanelRegionModel newWorld;

  DevelopmentPanelRegionModel forRegion(String regionId) =>
      regionId == kRegionNewWorld ? newWorld : oldWorld;
}
