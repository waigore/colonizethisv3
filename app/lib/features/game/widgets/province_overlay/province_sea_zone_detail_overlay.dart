// Province and sea zone detail overlay. SPEC/ui/province-sea-zone-detail-overlay.md.
//
// De-parted wave-9 cluster (Refs #4117): explicit-import libraries replace the
// former 17-part library. Public surface: [ProvinceSeaZoneDetailOverlay] and
// @visibleForTesting helpers re-exported below.

export 'province_sea_zone_detail_overlay_close_button.dart'
    show OverlayCloseButton;
export 'province_sea_zone_detail_overlay_designation.dart'
    show provinceOverlayIsCapital, provinceOverlayTileDesignationLine;
export 'province_sea_zone_detail_overlay_sections_economic_labels.dart'
    show provinceOverlayImprovementNameForResource;
export 'province_sea_zone_detail_overlay_sections_political.dart'
    show provinceOverlayOwnerName, provinceOverlayRegionLabel;
export 'province_sea_zone_detail_overlay_tile_section_labels.dart'
    show
        kProvinceOverlayTileInlineActionDisabledAlpha,
        roadRailSupplementaryLabel,
        roadRailTileDetailLinesForTests,
        roadRailTransportLevelPrimaryLine,
        tileDetailProspectedDisplayLabel,
        tryParseProvinceOverlayTileCoords;
export 'province_sea_zone_detail_overlay_widget.dart'
    show ProvinceSeaZoneDetailOverlay;
