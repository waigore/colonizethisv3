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

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        PlayerView,
        ProvinceImprovableCommodityCount,
        previewTownManufacturingBonusByProvince,
        provinceImprovableResourceTileCounts,
        WorldStateProvinceLookup;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/map_province_panel_provider.dart'
    show displayProvinceOrSeaIdFromTileKey, mapProvincePanelProvider;
import '../../../../core/services/game_service/game_service.dart' show GameMapData;
import '../map_state/map_state.dart';
import '../caches/per_player_work_target_selection_cache.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay.dart';

part 'province_detail_overlay_host_support_display.dart';
part 'province_detail_overlay_host_support_shortcuts.dart';
part 'province_detail_overlay_host_support_bonus.dart';
part 'province_detail_overlay_host_support_factory.dart';
part 'province_detail_overlay_host_support_map_data.dart';

/// The three province-overlay shortcut `onTap` callbacks. Each entry is `null`
/// when its action is disabled or no tile is selected, matching the previous
/// inline `state.enabled && selectedTileKey != null ? ... : null` gating.
typedef ProvinceDetailShortcutCallbacks = ({
  VoidCallback? onExploreWithExplorerTap,
  VoidCallback? onProspectWithExplorerTap,
  VoidCallback? onBuildImprovementTap,
});

/// Shared map-data + secondary-highlight / close wiring for wide and narrow
/// province-detail overlay hosts (Refs #4035 AC3).
typedef ProvinceDetailHostOverlayArgs = ({
  GameMapData? mapData,
  void Function(String?) onHighlightTile,
  void Function(Iterable<String>?) onHighlightTiles,
  VoidCallback onClose,
  ct_models.AppEventBus bus,
});
