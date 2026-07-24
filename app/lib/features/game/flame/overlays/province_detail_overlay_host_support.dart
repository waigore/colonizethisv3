// Shared province-detail overlay host wiring (Refs #3594, #4117).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        PlayerView,
        ProvinceImprovableCommodityCount,
        previewTownManufacturingBonusByProvince,
        projectProvinceExtraction,
        provinceImprovableResourceTileCounts,
        WorldStateProvinceLookup;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../../../providers/map_province_panel_provider.dart'
    show displayProvinceOrSeaIdFromTileKey, MapProvincePanelNotifier;
import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../../../core/services/game_service/try_get_game_map_data.dart'
    show tryGetGameMapData;
import '../map_state/map_state.dart';
import '../caches/per_player_work_target_selection_cache.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay.dart';

export '../../../../core/services/game_service/try_get_game_map_data.dart'
    show tryGetGameMapData;

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
