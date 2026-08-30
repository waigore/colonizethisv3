/// Shared types and style helpers for the province / sea-zone detail overlay
/// de-parted cluster (Refs #4117).
library;

import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_action_state_calculator.dart';

/// Tap callbacks for civilian inline actions on [ProvinceSeaZoneDetailOverlay].
typedef ProvinceInlineActionCallbacks = ({
  VoidCallback? onExploreWithExplorerTap,
  VoidCallback? onProspectWithExplorerTap,
  VoidCallback? onBuildImprovementTap,
  VoidCallback? onBuildRoadTap,
  VoidCallback? onBuildFortTap,
  VoidCallback? onBuildPortTap,
  VoidCallback? onBuildRailroadTap,
  VoidCallback? onPurchaseLandTap,
});

const ProvinceInlineActionCallbacks kEmptyProvinceInlineActionCallbacks = (
  onExploreWithExplorerTap: null,
  onProspectWithExplorerTap: null,
  onBuildImprovementTap: null,
  onBuildRoadTap: null,
  onBuildFortTap: null,
  onBuildPortTap: null,
  onBuildRailroadTap: null,
  onPurchaseLandTap: null,
);

/// Builds [ProvinceActionStates] with optional slot overrides (Widgetbook/tests).
ProvinceActionStates provinceOverlayInlineActions({
  ProvinceInlineActionState? explore,
  ProvinceInlineActionState? prospect,
  ProvinceInlineActionState? buildImprovement,
  ProvinceInlineActionState? buildRoad,
  ProvinceInlineActionState? buildFort,
  ProvinceInlineActionState? buildPort,
  ProvinceInlineActionState? buildRail,
  ProvinceInlineActionState? purchaseLand,
}) {
  return (
    explore: explore ?? kHiddenProvinceActionStates.explore,
    prospect: prospect ?? kHiddenProvinceActionStates.prospect,
    buildImprovement:
        buildImprovement ?? kHiddenProvinceActionStates.buildImprovement,
    buildRoad: buildRoad ?? kHiddenProvinceActionStates.buildRoad,
    buildFort: buildFort ?? kHiddenProvinceActionStates.buildFort,
    buildPort: buildPort ?? kHiddenProvinceActionStates.buildPort,
    buildRail: buildRail ?? kHiddenProvinceActionStates.buildRail,
    purchaseLand: purchaseLand ?? kHiddenProvinceActionStates.purchaseLand,
  );
}

/// Tab / wide-layout body bundle for [ProvinceSeaZoneDetailOverlay].
class OverlayContent {
  OverlayContent({
    required this.tabLabels,
    required this.tabViews,
    required this.sections,
  });

  final List<String> tabLabels;
  final List<Widget> tabViews;
  final Widget sections;
}

bool isProvinceSeaZoneOverlaySeaZone(RegionMapViewData region, String id) {
  final regionPart = prefixedIdRegionSegment(id);
  if (regionPart == null || regionPart != region.regionId) return false;
  final localId = prefixedIdLocalSegment(id);
  for (final cell in region.cells) {
    if (cell.regionCellId == localId) return cell.isSea;
  }
  return false;
}

Widget buildOverlaySection(String title, Widget child) {
  return Padding(
    padding: const EdgeInsets.only(bottom: CtSpacing.ml),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty) ...[
          CtSectionLabel(title),
          SizedBox(height: CtSpacing.m / 2),
        ],
        child,
      ],
    ),
  );
}

class OverlayObfuscatedSection extends StatelessWidget {
  const OverlayObfuscatedSection({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return buildOverlaySection(
      '',
      overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
    );
  }
}

TextStyle overlayObfuscatedBodyStyle() =>
    TextStyle(color: EditorialMonoclePalette.muted);

Widget overlayObfuscatedBodyText(String data) =>
    Text(data, style: overlayObfuscatedBodyStyle());

TextStyle overlayFgBodyStyle() => TextStyle(color: EditorialMonoclePalette.fg);

TextStyle overlayTitleStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final TextStyle base =
      theme.textTheme.titleMedium ??
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  return base.copyWith(
    color: EditorialMonoclePalette.accent,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.05,
  );
}

Widget overlayEmptyBodyDashText() {
  return Text('—', style: TextStyle(color: EditorialMonoclePalette.muted));
}

/// MAP20001 Civilian **Station spy** control props (Refs #4439).
typedef ProvinceOverlayStationSpyProps = ({
  bool showControl,
  bool enabled,
  String tooltip,
  VoidCallback? onTap,
});

const ProvinceOverlayStationSpyProps kProvinceOverlayStationSpyHidden = (
  showControl: false,
  enabled: false,
  tooltip: '',
  onTap: null,
);

/// MAP20001 Civilian **Counter-espionage** control props (Refs #4528).
typedef ProvinceOverlayCounterEspionageProps = ({
  bool showControl,
  bool enabled,
  String tooltip,
  String gist,
  VoidCallback? onTap,
});

const ProvinceOverlayCounterEspionageProps
kProvinceOverlayCounterEspionageHidden = (
  showControl: false,
  enabled: false,
  tooltip: '',
  gist: '',
  onTap: null,
);

/// Tab labels, narrow tab views, and wide stacked sections for a province.
OverlayContent overlayProvinceSectionBundle({
  required AppLocalizations l10n,
  required Widget political,
  required Widget tileSection,
  required Widget economic,
  required Widget military,
  required Widget civilian,
  required Widget naval,
}) {
  return OverlayContent(
    tabLabels: [
      l10n.provinceOverlay_sectionPolitical,
      l10n.provinceOverlay_sectionTile,
      l10n.provinceOverlay_sectionEconomic,
      l10n.provinceOverlay_sectionMilitary,
      l10n.provinceOverlay_sectionCivilian,
      l10n.provinceOverlay_sectionNaval,
    ],
    tabViews: [political, tileSection, economic, military, civilian, naval],
    sections: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [political, tileSection, economic, military, civilian, naval],
    ),
  );
}
