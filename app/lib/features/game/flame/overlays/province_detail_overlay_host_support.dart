// Shared province-detail overlay host wiring (Refs #3594 — resolve flame-host
// ↔ widget duplication / coupling, work item 7).
//
// Both province-detail overlay hosts — the wide side panel
// (`GameMapProvinceDetailSidePanel`) and the narrow bottom-sheet slot
// (`GameMapNarrowDetailOverlaySlot`) — previously duplicated two identical
// blocks verbatim: the `displayId` resolution from the selected tile key and
// the explore / prospect / build-improvement shortcut `onTap` callbacks (each
// re-validating its action state before emitting an
// `OpenCivilianUnitsPanelEvent`). The only differences between the two hosts
// are the slide axis, wrapper sizing, and the wide host's e2e snapshot — not
// this wiring. Following the precedent of `ProvinceActionStateCalculator`
// (issue #3279 item 4), the shared logic lives here so each host instantiates
// the overlay directly (keeping the SPEC § Architecture and wiring host→overlay
// contract intact) without copy-pasting the wiring.

export '../../../../core/services/game_service/try_get_game_map_data.dart'
    show tryGetGameMapData;
export 'province_detail_overlay_host_support_bonus.dart';
export 'province_detail_overlay_host_support_display.dart';
export 'province_detail_overlay_host_support_factory.dart';
export 'province_detail_overlay_host_support_map_data.dart';
export 'province_detail_overlay_host_support_shortcuts.dart';
export 'province_detail_overlay_host_support_types.dart';
