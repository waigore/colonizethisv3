/// Fully unrevealed province tab assembly for [ProvinceSeaZoneDetailOverlay].

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_support.dart';

OverlayContent provinceContentUnrevealed({required AppLocalizations l10n}) {
  final politicalObs = buildOverlaySection(
    l10n.provinceOverlay_sectionPolitical,
    overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
  );
  final tileObs = buildOverlaySection(
    l10n.provinceOverlay_sectionTile,
    overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
  );
  final obfuscatedSectionTitles = <String>[
    l10n.provinceOverlay_sectionPolitical,
    l10n.provinceOverlay_sectionTile,
    l10n.provinceOverlay_sectionEconomic,
    l10n.provinceOverlay_sectionMilitary,
    l10n.provinceOverlay_sectionCivilian,
    l10n.provinceOverlay_sectionNaval,
  ];
  final sections = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final title in obfuscatedSectionTitles)
        buildOverlaySection(
          title,
          overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
        ),
    ],
  );
  final tabLabels = obfuscatedSectionTitles;
  final tabViews = [
    politicalObs,
    tileObs,
    OverlayObfuscatedSection(l10n: l10n),
    OverlayObfuscatedSection(l10n: l10n),
    OverlayObfuscatedSection(l10n: l10n),
    OverlayObfuscatedSection(l10n: l10n),
  ];
  return OverlayContent(
    tabLabels: tabLabels,
    tabViews: tabViews,
    sections: sections,
  );
}
