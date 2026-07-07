/// Fully unrevealed province tab assembly for [ProvinceSeaZoneDetailOverlay].

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'province_sea_zone_detail_overlay.dart';

_OverlayContent _provinceContentUnrevealed({required AppLocalizations l10n}) {
  final politicalObs = _buildSection(
    l10n.provinceOverlay_sectionPolitical,
    _obfuscatedBodyText(l10n.provinceOverlay_unknown),
  );
  final tileObs = _buildSection(
    l10n.provinceOverlay_sectionTile,
    _obfuscatedBodyText(l10n.provinceOverlay_unknown),
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
        _buildSection(
          title,
          _obfuscatedBodyText(l10n.provinceOverlay_unknown),
        ),
    ],
  );
  final tabLabels = obfuscatedSectionTitles;
  final tabViews = [
    politicalObs,
    tileObs,
    _ObfuscatedSection(l10n: l10n),
    _ObfuscatedSection(l10n: l10n),
    _ObfuscatedSection(l10n: l10n),
    _ObfuscatedSection(l10n: l10n),
  ];
  return _OverlayContent(
    tabLabels: tabLabels,
    tabViews: tabViews,
    sections: sections,
  );
}
