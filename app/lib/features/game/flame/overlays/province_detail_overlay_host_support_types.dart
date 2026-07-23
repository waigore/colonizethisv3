// Shared typedefs for province-detail overlay host wiring (Refs #3594, #4117).

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;

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
