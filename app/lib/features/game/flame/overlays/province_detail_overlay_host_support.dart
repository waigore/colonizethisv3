// Shared province-detail overlay host wiring (Refs #3594 — resolve flame-host
// ↔ widget duplication / coupling, work item 7).
//
// De-parted wave-9 cluster (Refs #4117): thin re-export façade over
// explicit-import libraries. Public surface unchanged for overlay hosts.

export '../../../../core/services/game_service/try_get_game_map_data.dart'
    show tryGetGameMapData;
export 'province_detail_overlay_host_support_bonus.dart'
    show
        provinceAvailableResourceCountsPreview,
        provinceExtractionSnapshotPreview,
        provinceTownProductionBonusPreview;
export 'province_detail_overlay_host_support_display.dart'
    show resolveProvinceDetailDisplayId;
export 'province_detail_overlay_host_support_factory.dart'
    show buildProvinceSeaZoneDetailOverlayForPanel;
export 'province_detail_overlay_host_support_map_data.dart'
    show resolveProvinceDetailHostOverlayArgs;
export 'province_detail_overlay_host_support_shortcuts.dart'
    show buildProvinceDetailShortcutCallbacks;
export 'province_detail_overlay_host_support_types.dart'
    show ProvinceDetailHostOverlayArgs, ProvinceDetailShortcutCallbacks;
