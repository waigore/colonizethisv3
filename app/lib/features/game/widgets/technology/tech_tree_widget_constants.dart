// Category color/icon maps and layout dimensions for [TechTreeWidget].
// De-parted wave-9 cluster (Refs #4117).

import 'package:flutter/material.dart';

import '../../../../config/app_assets.dart';

/// Node width in logical pixels for tech-tree graph nodes.
const double kTechTreeNodeWidth = 100;

/// Node height in logical pixels for tech-tree graph nodes.
const double kTechTreeNodeHeight = 68;

/// Horizontal gap between layout layers (columns).
const double kTechTreeLayerGap = 140;

/// Vertical gap between rows within a layer.
const double kTechTreeRowGap = 52;

/// Stroke width for prerequisite connector edges.
const double kTechTreeEdgeStrokeWidth = 2;

/// Offset from source right edge for the vertical segment so it stays in the
/// inter-column gap (never through nodes).
const double kTechTreeEdgeBendOffset =
    (kTechTreeLayerGap - kTechTreeNodeWidth) / 2;

/// Category color map. SPEC/ui/tech-tree-widget.md: color-coded by category.
const Map<String, Color> kTechTreeCategoryColors = {
  'gathering': Color(0xFF2E7D32),
  'transport': Color(0xFF1565C0),
  'labour': Color(0xFFF9A825),
  'civilian': Color(0xFF6A1B9A),
  'diplomacy': Color(0xFF00838F),
  'naval': Color(0xFF0D47A1),
  'military': Color(0xFFC62828),
  'new-world': Color(0xFF4E342E),
};

/// Category icon map. SPEC/ui/tech-tree-widget.md: one icon per category.
const Map<String, String> kTechTreeCategoryIcons = {
  'gathering': '${kAppIconAssetPrefix}ui_icon_tech_gathering.png',
  'new-world': '${kAppIconAssetPrefix}ui_icon_tech_new_world.png',
  'transport': '${kAppIconAssetPrefix}ui_icon_tech_transport.png',
  'labour': '${kAppIconAssetPrefix}ui_icon_tech_labour.png',
  'civilian': '${kAppIconAssetPrefix}ui_icon_tech_civilian.png',
  'diplomacy': '${kAppIconAssetPrefix}ui_icon_tech_diplomacy.png',
  'naval': '${kAppIconAssetPrefix}ui_icon_tech_naval.png',
  'military': '${kAppIconAssetPrefix}ui_icon_tech_military.png',
};
