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

TextStyle overlayFgBodyStyle() =>
    TextStyle(color: EditorialMonoclePalette.fg);

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
