import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show DevelopmentImprovableCommodityRow, DevelopmentPanelRegionModel;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show kRegionNewWorld, kRegionOldWorld;
import 'package:flutter/material.dart';

/// Resolve OW/NW tab for inbound feedstock focus (Refs #4725).
int resolveDevelopmentInboundTabIndex({
  required String? highlightCommodityId,
  required String? highlightTileKey,
  required DevelopmentPanelRegionModel oldWorld,
  required DevelopmentPanelRegionModel newWorld,
}) {
  if (highlightTileKey != null) {
    final parsed = parseTileKeyCoordinates(highlightTileKey);
    if (parsed?.regionId == kRegionNewWorld) return 1;
    if (parsed?.regionId == kRegionOldWorld) return 0;
  }
  if (highlightCommodityId != null) {
    if (developmentRegionHasImprovableCommodity(oldWorld, highlightCommodityId)) {
      return 0;
    }
    if (developmentRegionHasImprovableCommodity(newWorld, highlightCommodityId)) {
      return 1;
    }
  }
  return 0;
}

bool developmentRegionHasImprovableCommodity(
  DevelopmentPanelRegionModel regionModel,
  String commodityId,
) {
  for (final scope in [
    ...regionModel.ownedScopes,
    ...regionModel.purchasedScopes,
  ]) {
    for (final row in scope.improvableCommodities) {
      if (row.commodityId == commodityId) return true;
    }
  }
  return false;
}

({String scopeKey, DevelopmentImprovableCommodityRow row})?
findFirstDevelopmentImprovableCommodity({
  required DevelopmentPanelRegionModel regionModel,
  required String commodityId,
}) {
  for (final scope in [
    ...regionModel.ownedScopes,
    ...regionModel.purchasedScopes,
  ]) {
    for (final row in scope.improvableCommodities) {
      if (row.commodityId == commodityId) {
        return (scopeKey: scope.scopeKey, row: row);
      }
    }
  }
  return null;
}

/// Inbound chrome + first-frame scroll for a matching assign row (Refs #4725).
class DevelopmentInboundCommodityHighlight extends StatefulWidget {
  const DevelopmentInboundCommodityHighlight({
    required this.commodityId,
    required this.highlighted,
    required this.child,
    super.key,
  });

  final String commodityId;
  final bool highlighted;
  final Widget child;

  static Key highlightKey(String commodityId) =>
      ValueKey<String>('developmentInboundRowHighlight:$commodityId');

  @override
  State<DevelopmentInboundCommodityHighlight> createState() =>
      _DevelopmentInboundCommodityHighlightState();
}

class _DevelopmentInboundCommodityHighlightState
    extends State<DevelopmentInboundCommodityHighlight> {
  @override
  void initState() {
    super.initState();
    if (!widget.highlighted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.15,
        duration: Duration.zero,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.highlighted) return widget.child;
    return DecoratedBox(
      key: DevelopmentInboundCommodityHighlight.highlightKey(widget.commodityId),
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.accentDim.withValues(alpha: 0.2),
        border: Border.all(
          color: EditorialMonoclePalette.accentBright,
          width: 2,
        ),
      ),
      child: widget.child,
    );
  }
}
