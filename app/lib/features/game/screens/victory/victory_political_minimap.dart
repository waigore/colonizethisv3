import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show kRegionNewWorld, kRegionOldWorld;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'victory_political_minimap_painter.dart';
import 'victory_province_origin.dart';
import 'victory_screen_keys.dart';

/// Old World political ownership minimap with hover/tap province inspect.
class VictoryPoliticalMinimap extends StatefulWidget {
  const VictoryPoliticalMinimap({
    super.key,
    required this.game,
    required this.region,
    this.selectedPlayerId,
    this.onGreatPowerOwnerSelected,
  });

  final Game game;
  final RegionMapViewData region;
  final String? selectedPlayerId;
  final ValueChanged<String>? onGreatPowerOwnerSelected;

  @override
  State<VictoryPoliticalMinimap> createState() => _VictoryPoliticalMinimapState();
}

class _VictoryPoliticalMinimapState extends State<VictoryPoliticalMinimap> {
  String? _highlightedProvinceLocalId;
  String? _inspectLabel;

  Province? _provinceAtLocalOffset(Offset local, Size size) {
    final cellW = size.width / widget.region.width;
    final cellH = size.height / widget.region.height;
    if (cellW <= 0 || cellH <= 0) return null;
    final x = (local.dx / cellW).floor().clamp(0, widget.region.width - 1);
    final y = (local.dy / cellH).floor().clamp(0, widget.region.height - 1);
    final cell = widget.region.cellAt(x, y);
    if (cell.isSea) return null;
    final fullId = ProvinceId.full(widget.region.regionId, cell.regionCellId);
    for (final province in widget.game.worldState.oldWorld.provinces) {
      if (province.id == fullId) return province;
    }
    return null;
  }

  void _updateInspect(Offset? local, Size size) {
    if (local == null) {
      setState(() {
        _highlightedProvinceLocalId = null;
        _inspectLabel = null;
      });
      return;
    }
    final province = _provinceAtLocalOffset(local, size);
    if (province == null) {
      setState(() {
        _highlightedProvinceLocalId = null;
        _inspectLabel = null;
      });
      return;
    }
    final ownerId = province.ownerId;
    final ownerIsGp =
        ownerId != null && widget.game.players.any((p) => p.id == ownerId);
    setState(() {
      _highlightedProvinceLocalId = ProvinceId.localIdFrom(province.id);
      _inspectLabel = victoryProvinceInspectLabel(widget.game, province);
    });
    if (ownerIsGp) {
      widget.onGreatPowerOwnerSelected?.call(ownerId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: widget.region.width / widget.region.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return MouseRegion(
                onExit: (_) => _updateInspect(null, size),
                onHover: (event) => _updateInspect(event.localPosition, size),
                child: GestureDetector(
                  key: VictoryScreenKeys.politicalMinimapGestureKey,
                  onTapDown: (details) =>
                      _updateInspect(details.localPosition, size),
                  child: CustomPaint(
                    key: VictoryScreenKeys.politicalMinimapPaintKey,
                    painter: VictoryPoliticalMinimapPainter(
                      region: widget.region,
                      highlightedProvinceLocalId: _highlightedProvinceLocalId,
                      selectedFactionId: widget.selectedPlayerId,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
        if (_inspectLabel != null) ...[
          const SizedBox(height: 8),
          Text(
            key: VictoryScreenKeys.politicalMinimapInspectKey,
            _inspectLabel!,
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Builds Old World [RegionMapViewData] for the Victory political minimap.
RegionMapViewData? buildVictoryOldWorldMapViewData({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  int cellSize = 8,
}) {
  final owTileMap = tileMapByRegion[kRegionOldWorld];
  final nwTileMap = tileMapByRegion[kRegionNewWorld];
  final owTopology = topologyByRegion[kRegionOldWorld];
  final nwTopology = topologyByRegion[kRegionNewWorld];
  if (owTileMap == null ||
      nwTileMap == null ||
      owTopology == null ||
      nwTopology == null) {
    return null;
  }
  return buildInitGameMapViewData(
    game: game,
    tileMapByRegion: {
      kRegionOldWorld: owTileMap,
      kRegionNewWorld: nwTileMap,
    },
    topologyByRegion: {
      kRegionOldWorld: owTopology,
      kRegionNewWorld: nwTopology,
    },
    cellSize: cellSize,
  ).oldWorld;
}
