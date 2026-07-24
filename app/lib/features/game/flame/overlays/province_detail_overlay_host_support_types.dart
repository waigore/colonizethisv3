import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;

/// The three province-overlay shortcut `onTap` callbacks. Each entry is `null`
/// when its action is disabled or no tile is selected, matching the previous
/// inline `state.enabled && selectedTileKey != null ? ... : null` gating.
typedef ProvinceDetailShortcutCallbacks = ({
  void Function()? onExploreWithExplorerTap,
  void Function()? onProspectWithExplorerTap,
  void Function()? onBuildImprovementTap,
});

/// Shared map-data + secondary-highlight / close wiring for wide and narrow
/// province-detail overlay hosts (Refs #4035 AC3).
typedef ProvinceDetailHostOverlayArgs = ({
  GameMapData? mapData,
  void Function(String?) onHighlightTile,
  void Function(Iterable<String>?) onHighlightTiles,
  void Function() onClose,
  ct_models.AppEventBus bus,
});
