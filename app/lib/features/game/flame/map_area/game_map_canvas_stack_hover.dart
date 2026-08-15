import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout.dart';
import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout_copy.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

/// Whether the MAP10001 owner/sight readout should paint.
bool shouldShowMapTileHoverReadout({
  required bool inWorkTargetSelectionMode,
  required String? hoveredTileKey,
}) {
  return !inWorkTargetSelectionMode &&
      hoveredTileKey != null &&
      hoveredTileKey.isNotEmpty;
}

/// Hosts [map] and overlays owner/sight chrome from [onTileHovered] without
/// rebuilding the Flame map on every pointer move.
class GameMapCanvasStackHoverHost extends StatefulWidget {
  const GameMapCanvasStackHoverHost({
    required this.inWorkTargetSelectionMode,
    required this.game,
    required this.region,
    required this.mapBuilder,
    this.onWorkTargetTileHovered,
    super.key,
  });

  final bool inWorkTargetSelectionMode;
  final Game game;
  final RegionMapViewData region;
  final Widget Function(void Function(String? tileKey) onTileHovered)
  mapBuilder;
  final void Function(String? tileKey)? onWorkTargetTileHovered;

  @override
  State<GameMapCanvasStackHoverHost> createState() =>
      _GameMapCanvasStackHoverHostState();
}

class _GameMapCanvasStackHoverHostState
    extends State<GameMapCanvasStackHoverHost> {
  final ValueNotifier<String?> _hoveredTileKey = ValueNotifier<String?>(null);

  @override
  void didUpdateWidget(GameMapCanvasStackHoverHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inWorkTargetSelectionMode && _hoveredTileKey.value != null) {
      _hoveredTileKey.value = null;
    }
  }

  @override
  void dispose() {
    _hoveredTileKey.dispose();
    super.dispose();
  }

  void _onTileHovered(String? tileKey) {
    if (widget.inWorkTargetSelectionMode) {
      widget.onWorkTargetTileHovered?.call(tileKey);
      if (_hoveredTileKey.value != null) {
        _hoveredTileKey.value = null;
      }
      return;
    }
    if (_hoveredTileKey.value != tileKey) {
      _hoveredTileKey.value = tileKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.mapBuilder(_onTileHovered),
        ValueListenableBuilder<String?>(
          valueListenable: _hoveredTileKey,
          builder: (context, hoveredTileKey, _) {
            final tileKey = hoveredTileKey;
            if (!shouldShowMapTileHoverReadout(
              inWorkTargetSelectionMode: widget.inWorkTargetSelectionMode,
              hoveredTileKey: tileKey,
            )) {
              return const SizedBox.shrink();
            }
            if (tileKey == null) {
              return const SizedBox.shrink();
            }
            final copy = tryMapTileHoverReadoutCopy(
              l10n: appL10n(context),
              game: widget.game,
              region: widget.region,
              tileKey: tileKey,
            );
            if (copy == null) {
              return const SizedBox.shrink();
            }
            return MapTileHoverReadout(copy: copy);
          },
        ),
      ],
    );
  }
}
