import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, resourceIdVisibleInPlayerView;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'gp_ownership_tint_layer.dart';
import 'resource_icon_cache.dart';
import 'terrain_tileset.dart';
import 'town_icon_cache.dart';

final _log = gameLogger();

/// Fog overlay opacity when drawing a dark rect over tiles (0 = no overlay, 1 = full black).
const double _fogOverlayOpacity = 0.4;

/// GP land ownership tint (province overlay). SPEC/ui/map-widget.md: alpha 0.10–0.20.
const double _gpOwnershipTintAlpha = 0.15;

/// Political border stroke colors.
/// These are intentionally subtle so they don't overpower the terrain art.
const Color _provinceBorderLandColor = Color.fromRGBO(0, 0, 0, 0.35);
const Color _provinceBorderSeaLandColor = Color.fromRGBO(0, 0, 0, 0.25);
const Color _provinceBorderSeaZoneColor = Color.fromRGBO(130, 200, 255, 0.55);

/// Land province labels: max text width and font size in **logical pixels** (screen space).
const double _provinceLabelMaxWidthPx = 120;
const double _provinceLabelFontSizePx = 11;
const double _provinceLabelPlatePaddingPx = 4;
const Color _provinceLabelPlateColor = Color.fromRGBO(0, 0, 0, 0.55);

/// Check if a terrain type uses L2+ standalone tile rendering (features).
/// L0: Sea (Wang). L1: Plains/Desert (Wang). L2+: Features (standalone).
bool _isFeatureTerrain(TerrainType terrain) {
  return terrain == TerrainType.forest ||
      terrain == TerrainType.hills ||
      terrain == TerrainType.mountain ||
      terrain == TerrainType.swamp;
}

/// Get the dominant adjacent land base type for coastline tileset selection.
/// Returns 'plains' or 'desert' based on which is more common among neighbors.
TerrainType? _getDominantAdjacentLandBase(
  int x,
  int y,
  CellViewData? Function(int, int) getCellAt,
) {
  int plainsCount = 0;
  int desertCount = 0;

  for (final dy in [-1, 0, 1]) {
    for (final dx in [-1, 0, 1]) {
      if (dx == 0 && dy == 0) continue;
      final cell = getCellAt(x + dx, y + dy);
      if (cell != null && !cell.isSea) {
        final terrain = cell.terrainType;
        if (terrain == TerrainType.plains) {
          plainsCount++;
        } else if (terrain == TerrainType.desert) {
          desertCount++;
        } else if (terrain != null && _isFeatureTerrain(terrain)) {
          plainsCount++; // Features have plains underneath
        }
      }
    }
  }

  if (plainsCount >= desertCount) return TerrainType.plains;
  return TerrainType.desert;
}

/// Visibility mode for the region map. SPEC/ui/map-widget.md.
enum CtMapVisibilityMode {
  /// Full visibility: ignore per-tile visibility and render all tiles as visible.
  full,

  /// Player-constrained visibility: honor [CellViewData.visibility] for each tile.
  playerConstrained,
}

/// [CtMapVisibilityMode.playerConstrained] requires [playerViewForResources].
void assertCtMapPlayerViewRequired({
  required CtMapVisibilityMode visibilityMode,
  required PlayerView? playerViewForResources,
}) {
  if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
      playerViewForResources == null) {
    throw StateError(
      'CtMapVisibilityMode.playerConstrained requires a non-null '
      'PlayerView (pass playerViewForResources), e.g. '
      'buildPlayerView(game, topology, humanPlayerId).',
    );
  }
}

/// Base layer display mode: terrain, resource icons, improvement/road labels.
/// SPEC/ui/map-widget.md § Base layer display mode.
enum BaseLayerDisplayMode {
  /// Terrain only; no resource icons or improvement/road labels.
  terrainOnly,

  /// Terrain + resource icons; no improvement or road labels.
  terrainAndResources,

  /// Terrain + resource icons + improvement labels (`I{n}` when n > 0); no road labels.
  terrainAndResourcesImprovementLabels,

  /// Terrain + resource icons + improvement labels + road/rail labels (`R{n}` when n > 0).
  /// Roads are painted after improvements (on top). Road labels require improvement mode on.
  terrainAndResourcesImprovementsRoads,
}

/// Flame-based region map component. Renders one RegionMapViewData and exposes
/// hover/selection state via callbacks. SPEC/ui/map-widget.md.
class CtRegionMapComponent extends PositionComponent {
  CtRegionMapComponent({
    required this.region,
    required this.cellSize,
    required this.showPoliticalOverlay,
    required this.showProvinceOverlay,
    required this.showProvinceOwnershipTint,
    required this.showProvinceNamesLayer,
    required this.visibilityMode,
    this.baseLayerDisplayMode =
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
    this.onProvinceSelected,
    this.onMapTileTappedForDetail,
    this.onProvinceHovered,
    this.onTileHovered,
    this.onTileTapped,
    this.selectedTileKey,
    this.secondaryHighlightTileKey,
    this.validTileKeys,
    this.onTownIconTapped,
    this.playerViewForResources,
  });

  RegionMapViewData region;
  double cellSize;
  bool showPoliticalOverlay;
  bool showProvinceOverlay;
  bool showProvinceOwnershipTint;
  bool showProvinceNamesLayer;
  CtMapVisibilityMode visibilityMode;

  /// When [visibilityMode] is [CtMapVisibilityMode.playerConstrained], gates
  /// resource icons by fog + prospecting (SPEC/game/fog-and-exploration.md).
  /// Must be non-null in that mode; see [assertCtMapPlayerViewRequired].
  PlayerView? playerViewForResources;

  /// Camera zoom from Flame viewfinder; used to keep label size constant on screen.
  double cameraZoom = 1.0;
  BaseLayerDisplayMode baseLayerDisplayMode;
  void Function(String provinceId)? onProvinceSelected;
  void Function(String tileKey)? onMapTileTappedForDetail;
  void Function(String? provinceId)? onProvinceHovered;
  void Function(String? tileKey)? onTileHovered;
  void Function(String? tileKey)? onTileTapped;
  String? selectedTileKey;
  String? secondaryHighlightTileKey;
  Set<String>? validTileKeys;
  void Function(String provinceId)? onTownIconTapped;

  int? _hoveredTileX;
  int? _hoveredTileY;
  String? _hoveredProvinceId;
  double _hoverAnimationT = 0.0;

  RegionMapViewData? _provinceLabelsRegionRef;
  double? _provinceLabelsCellSize;
  CtMapVisibilityMode? _provinceLabelsVisibilityMode;
  List<({double cx, double cy, String text})>? _provinceLabelsCached;

  @override
  Future<void> onLoad() async {
    assertCtMapPlayerViewRequired(
      visibilityMode: visibilityMode,
      playerViewForResources: playerViewForResources,
    );
    await super.onLoad();
    await Future.wait([
      terrainTilesetCache.load(),
      resourceIconCache.load(),
      townIconCache.load(),
    ]);
    _log.i(
      'TerrainTilesetCache loaded. '
      'sea_plains: ${terrainTilesetCache.getSeaPlainsTileset() != null}, '
      'sea_desert: ${terrainTilesetCache.getSeaDesertTileset() != null}, '
      'plains_desert: ${terrainTilesetCache.getPlainsDesertTileset() != null}. '
      'ResourceIconCache loaded: ${resourceIconCache.isLoaded}. '
      'TownIconCache loaded: ${townIconCache.isLoaded}',
    );
    size = Vector2(region.width * cellSize, region.height * cellSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _hoverAnimationT += dt;
  }

  /// Updates hover state from a world-space position.
  void updateHoverFromWorld(Vector2 worldPosition) {
    final local = worldPosition - absoluteTopLeftPosition;
    final x = (local.x / cellSize).floor();
    final y = (local.y / cellSize).floor();
    _setHoverFromCell(x, y);
  }

  void _setHoverFromCell(int x, int y) {
    int? nx;
    int? ny;
    if (x >= 0 && x < region.width && y >= 0 && y < region.height) {
      final cell = region.cellAt(x, y);
      final isUnrevealed =
          visibilityMode == CtMapVisibilityMode.playerConstrained &&
          cell.visibility == TileVisibility.unrevealed;
      if (!isUnrevealed) {
        nx = x;
        ny = y;
      }
    }
    final prevId = _hoveredTileX != null && _hoveredTileY != null
        ? '${region.regionId}|${region.cellAt(_hoveredTileX!, _hoveredTileY!).regionCellId}'
        : null;
    final nextId = nx != null && ny != null
        ? '${region.regionId}|${region.cellAt(nx, ny).regionCellId}'
        : null;
    if (prevId != nextId) {
      onProvinceHovered?.call(nextId);
    }
    final nextTileKey = nx != null && ny != null
        ? '${region.regionId}|${region.cellAt(nx, ny).regionCellId}|$nx|$ny'
        : null;
    onTileHovered?.call(nextTileKey);
    _hoveredTileX = nx;
    _hoveredTileY = ny;
    _hoveredProvinceId = nx != null && ny != null
        ? region.cellAt(nx, ny).regionCellId
        : null;
  }

  /// Handles a tap at the given world-space position.
  /// Reports province selection and the tapped tile (so overlay can show tile
  /// details on mobile where hover is unavailable). SPEC/ui/province-sea-zone-detail-overlay.md.
  void handleTapAtWorld(Vector2 worldPosition) {
    final local = worldPosition - absoluteTopLeftPosition;
    final x = (local.x / cellSize).floor();
    final y = (local.y / cellSize).floor();
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return;
    final cell = region.cellAt(x, y);
    final tileKey = '${region.regionId}|${cell.regionCellId}|$x|$y';
    if (validTileKeys != null) {
      // Work target mode: use tap handler for selection/cancellation.
      if (validTileKeys!.isNotEmpty && validTileKeys!.contains(tileKey)) {
        onTileTapped?.call(tileKey);
      } else {
        onTileTapped?.call(null);
      }
      return;
    }
    // Not in work target mode: allow province selection.
    // Town or port icon hit (port may be on an adjacent sea tile). SPEC/ui/town-port-icons.md.
    final tappedTown = _getTownAtTile(x, y);
    if (tappedTown != null) {
      final provinceId = '${region.regionId}|${tappedTown.provinceId}';
      onTownIconTapped?.call(provinceId);
    }
    final provinceId = '${region.regionId}|${cell.regionCellId}';
    onMapTileTappedForDetail?.call(tileKey);
    onProvinceSelected?.call(provinceId);
  }

  TownMarkerView? _getTownAtTile(int x, int y) {
    for (final town in region.townMarkers) {
      if (town.x == x && town.y == y) {
        return town;
      }
      if (town.isPort) {
        final px = town.portIconX;
        final py = town.portIconY;
        if (px != null && py != null && px == x && py == y) {
          return town;
        }
      }
    }
    return null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _paintTiles(canvas);
    if (showProvinceOwnershipTint) {
      _paintGreatPowerLandOwnershipTint(canvas);
    }
    _paintOverlay(canvas);
    if (showProvinceOverlay) {
      _paintProvinceBorders(canvas);
    }
    if (_hoveredProvinceId != null) {
      _paintHoveredProvinceGlow(canvas);
    }
    if (showPoliticalOverlay && showProvinceOverlay) {
      _paintFactionBorders(canvas);
    }
    if (showProvinceNamesLayer) {
      _paintProvinceNames(canvas);
    }
    _paintCapitals(canvas);
    _paintTowns(canvas);
    _paintWarpZones(canvas);
    if (_hoveredTileX != null && _hoveredTileY != null) {
      _paintSelector(canvas);
    }
    if (selectedTileKey != null) {
      _paintSelectedTile(canvas);
    }
    if (secondaryHighlightTileKey != null) {
      _paintSecondaryHighlightTile(canvas);
    }
    if (validTileKeys != null && validTileKeys!.isNotEmpty) {
      _paintValidTilesGlow(canvas);
    }
  }

  void _paintValidTilesGlow(Canvas canvas) {
    final keys = validTileKeys!;
    // Flashing yellow border for valid tiles (opacity oscillates 0.4-0.8).
    // SPEC/ui/map-widget.md § Work target selection mode.
    final t = _hoverAnimationT;
    final opacity = 0.4 + 0.4 * (0.5 + 0.5 * math.sin(t * 3));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Color(0xFFFFFF00).withValues(alpha: opacity);
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        final tileKey = '${region.regionId}|${cell.regionCellId}|$x|$y';
        if (!keys.contains(tileKey)) continue;
        final left = x * cellSize;
        final top = y * cellSize;
        canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      }
    }
  }

  void _paintSelectedTile(Canvas canvas) {
    _paintTileOutlineRing(
      canvas,
      tileKey: selectedTileKey!,
      color: const Color(0xFFFFAA00),
      strokeWidth: 3,
    );
  }

  void _paintSecondaryHighlightTile(Canvas canvas) {
    _paintTileOutlineRing(
      canvas,
      tileKey: secondaryHighlightTileKey!,
      color: const Color(0xFF66D9FF),
      strokeWidth: 2.5,
    );
  }

  void _paintTileOutlineRing(
    Canvas canvas, {
    required String tileKey,
    required Color color,
    required double strokeWidth,
  }) {
    final parts = tileKey.split('|');
    if (parts.length < 4) return;
    if (parts[0] != region.regionId) return;
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) return;
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return;
    final left = x * cellSize;
    final top = y * cellSize;
    final rect = Rect.fromLTWH(left, top, cellSize, cellSize);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    canvas.drawRect(rect, paint);
  }

  void _ensureProvinceLabelCache() {
    if (identical(_provinceLabelsRegionRef, region) &&
        _provinceLabelsCellSize == cellSize &&
        _provinceLabelsVisibilityMode == visibilityMode &&
        _provinceLabelsCached != null) {
      return;
    }
    _provinceLabelsRegionRef = region;
    _provinceLabelsCellSize = cellSize;
    _provinceLabelsVisibilityMode = visibilityMode;
    _provinceLabelsCached = _computeProvinceLabels();
  }

  List<({double cx, double cy, String text})> _computeProvinceLabels() {
    final byLocalId = <String, List<CellViewData>>{};
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          cell.visibility == TileVisibility.unrevealed) {
        continue;
      }
      byLocalId.putIfAbsent(cell.regionCellId, () => []).add(cell);
    }
    final out = <({double cx, double cy, String text})>[];
    for (final e in byLocalId.entries) {
      final cells = e.value;
      if (cells.isEmpty) continue;
      var sx = 0.0;
      var sy = 0.0;
      for (final c in cells) {
        sx += (c.x + 0.5) * cellSize;
        sy += (c.y + 0.5) * cellSize;
      }
      final n = cells.length;
      final cx = sx / n;
      final cy = sy / n;
      String? name;
      for (final c in cells) {
        final dn = c.provinceDisplayName;
        if (dn != null && dn.isNotEmpty) {
          name = dn;
          break;
        }
      }
      final text = name ?? e.key;
      out.add((cx: cx, cy: cy, text: text));
    }
    return out;
  }

  void _paintProvinceNames(Canvas canvas) {
    _ensureProvinceLabelCache();
    final labels = _provinceLabelsCached;
    if (labels == null || labels.isEmpty) {
      return;
    }

    final invZ = 1.0 / cameraZoom.clamp(0.25, 4.0);
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: _provinceLabelFontSizePx,
      fontWeight: FontWeight.w600,
      shadows: <Shadow>[
        Shadow(
          blurRadius: 2,
          color: Color(0x8A000000),
          offset: Offset(0.5, 0.5),
        ),
      ],
    );
    final platePaint = Paint()..color = _provinceLabelPlateColor;

    for (final item in labels) {
      final tp = TextPainter(
        text: TextSpan(text: item.text, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 3,
        ellipsis: '…',
      )..layout(maxWidth: _provinceLabelMaxWidthPx);

      final tw = tp.width;
      final th = tp.height;
      const pad = _provinceLabelPlatePaddingPx;
      final bw = tw + pad * 2;
      final bh = th + pad * 2;

      canvas.save();
      canvas.translate(item.cx, item.cy);
      canvas.scale(invZ);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, platePaint);
      tp.paint(canvas, Offset(-tw / 2, -th / 2));
      canvas.restore();
    }
  }

  void _paintTiles(Canvas canvas) {
    // Guard: if tilesets not loaded yet, render nothing (will render on next frame after load)
    // This can happen when render() is called before onLoad() completes due to Flame's sync rendering
    if (!terrainTilesetCache.isLoaded) {
      return;
    }
    _paintTilesWithTilesets(canvas);
  }

  void _paintTilesWithTilesets(Canvas canvas) {
    // Pass 0: Draw sea layer (base)
    for (final cell in region.cells) {
      if (cell.isSea) {
        _paintSeaCell(canvas, cell);
      }
    }

    // Pass 1: Draw land base layer (plains, desert)
    for (final cell in region.cells) {
      if (!cell.isSea) {
        _paintLandBaseCell(canvas, cell);
      }
    }

    // Pass 2: Draw terrain features layer (forest, hills, mountain, swamp)
    for (final cell in region.cells) {
      if (!cell.isSea &&
          cell.terrainType != null &&
          _isFeatureTerrain(cell.terrainType!)) {
        _paintFeatureCell(canvas, cell);
      }
    }
  }

  void _paintSeaCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.unrevealed) {
      final paint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      return;
    }

    // Sea layer with coastline transitions
    // Check if this sea cell has land neighbors (coastline)
    final landCorner = _getCoastlineCornerValues(cell.x, cell.y);

    // Determine which tileset to use based on adjacent land type (for both interior and coastline)
    final dominantLandType = _getDominantAdjacentLandBase(
      cell.x,
      cell.y,
      _getCellAt,
    );
    final tileset = dominantLandType == TerrainType.desert
        ? terrainTilesetCache.getSeaDesertTileset()
        : terrainTilesetCache.getSeaPlainsTileset();

    if (tileset == null) {
      throw StateError(
        'Sea tileset is null for dominantLandType=$dominantLandType - '
        'terrain tileset failed to load',
      );
    }

    if (landCorner.same) {
      // Interior sea - no land neighbors, use sea base tile
      final seaBaseTileId = tileset.lowerBaseTileId;
      final tile = seaBaseTileId != null
          ? tileset.findTileById(seaBaseTileId)
          : tileset.findTile(nw: false, ne: false, sw: false, se: false);
      if (tile != null) {
        final srcRect = tile.boundingBox;
        final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
        canvas.drawImageRect(tileset.image, srcRect, dstRect, Paint());
        if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
            cell.visibility == TileVisibility.fogged) {
          canvas.drawRect(
            dstRect,
            Paint()..color = Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
          );
        }
      }
      return;
    }

    _drawTile(
      canvas,
      tileset,
      left,
      top,
      nw: landCorner.nw,
      ne: landCorner.ne,
      sw: landCorner.sw,
      se: landCorner.se,
      cell: cell,
    );
  }

  void _paintLandBaseCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.unrevealed) {
      final paint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      return;
    }

    final terrain = cell.terrainType;

    // Handle invalid terrain - should not happen
    if (terrain == null) {
      throw StateError('Cell has no terrain type: $cell');
    }

    // Features draw their land base (plains or desert) first, then overlay
    if (_isFeatureTerrain(terrain)) {
      _paintLandBaseTile(canvas, cell);
      return;
    }

    // Land base (plains or desert) - use Wang tileset for transitions
    _paintLandBaseTile(canvas, cell);
  }

  /// Paint a land base tile (plains or desert) with Wang transitions.
  void _paintLandBaseTile(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;
    final terrain = cell.terrainType;

    // Determine if this cell is plains or desert
    final isPlains =
        terrain == TerrainType.plains ||
        (terrain != null && _isFeatureTerrain(terrain));
    final isDesert = terrain == TerrainType.desert;

    // Check for plains↔desert border
    final nearDesertCorner = _getCornerValues(
      cell.x,
      cell.y,
      (c) => !c.isSea && c.terrainType == TerrainType.desert,
    );
    final nearPlainsCorner = _getCornerValues(
      cell.x,
      cell.y,
      (c) =>
          !c.isSea &&
          (c.terrainType == TerrainType.plains ||
              (c.terrainType != null && _isFeatureTerrain(c.terrainType!))),
    );

    // Use plains_desert tileset for plains↔desert transitions
    if (isPlains && !nearDesertCorner.same && nearDesertCorner.value) {
      final tileset = terrainTilesetCache.getPlainsDesertTileset();
      if (tileset == null) {
        throw StateError(
          'Plains desert tileset is null - terrain tileset failed to load',
        );
      }
      _drawTile(
        canvas,
        tileset,
        left,
        top,
        nw: nearDesertCorner.nw,
        ne: nearDesertCorner.ne,
        sw: nearDesertCorner.sw,
        se: nearDesertCorner.se,
        cell: cell,
      );
      return;
    }

    if (isDesert && !nearPlainsCorner.same && nearPlainsCorner.value) {
      final tileset = terrainTilesetCache.getPlainsDesertTileset();
      if (tileset == null) {
        throw StateError(
          'Plains desert tileset is null - terrain tileset failed to load',
        );
      }
      // For desert viewing from desert side, invert corners
      _drawTile(
        canvas,
        tileset,
        left,
        top,
        nw: !nearPlainsCorner.nw,
        ne: !nearPlainsCorner.ne,
        sw: !nearPlainsCorner.sw,
        se: !nearPlainsCorner.se,
        cell: cell,
      );
      return;
    }

    // Interior cell - use base tile from sea tileset (cleaner with transition_size=0.5)
    // Plains uses sea_plains tileset, Desert uses sea_desert tileset
    // Note: In sea tilesets, 'lower'=sea, 'upper'=land
    final interiorTileset = terrain == TerrainType.desert
        ? terrainTilesetCache.getSeaDesertTileset()
        : terrainTilesetCache.getSeaPlainsTileset();
    if (interiorTileset == null) {
      throw StateError(
        'Interior tileset is null for terrain=$terrain - '
        'terrain tileset failed to load',
      );
    }
    // Use upperBaseTileId for both plains and desert (land is 'upper' in sea tilesets)
    final tile = interiorTileset.upperBaseTileId != null
        ? interiorTileset.findTileById(interiorTileset.upperBaseTileId!)
        : null;
    if (tile == null) {
      throw StateError(
        'Base tile not found for terrain=$terrain - '
        'upperBaseTileId=${interiorTileset.upperBaseTileId}',
      );
    }
    final srcRect = tile.boundingBox;
    final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
    final paint = Paint();
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.fogged) {
      paint.colorFilter = ColorFilter.mode(
        Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
        BlendMode.darken,
      );
    }
    canvas.drawImageRect(interiorTileset.image, srcRect, dstRect, paint);
  }

  void _paintFeatureCell(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.unrevealed) {
      return; // Already handled by land base pass
    }

    final terrain = cell.terrainType;
    if (terrain == null || !_isFeatureTerrain(terrain)) return;

    // All features use standalone tiles; plains base is already drawn in pass 1.
    // If a standalone tile is missing (e.g. asset regression), skip drawing the
    // overlay rather than failing the entire map render. Wang tilesets remain
    // strict (they must exist), but L2+ overlays are best-effort.
    final standaloneTile = terrainTilesetCache.getStandaloneTile(terrain);
    if (standaloneTile == null) {
      _log.w(
        'Standalone tile missing for terrain=$terrain; '
        'skipping feature overlay for cell (${cell.x}, ${cell.y})',
      );
      return;
    }

    final paint = Paint();
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.fogged) {
      paint.colorFilter = ColorFilter.mode(
        Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
        BlendMode.darken,
      );
    }

    final srcRect = Rect.fromLTWH(
      0,
      0,
      standaloneTile.image.width.toDouble(),
      standaloneTile.image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
    canvas.drawImageRect(standaloneTile.image, srcRect, dstRect, paint);
  }

  _CornerValues _getCornerValues(
    int x,
    int y,
    bool Function(CellViewData) predicate,
  ) {
    final nwCell = _getCellAt(x - 1, y - 1);
    final nCell = _getCellAt(x, y - 1);
    final neCell = _getCellAt(x + 1, y - 1);
    final wCell = _getCellAt(x - 1, y);
    final cCell = _getCellAt(x, y);
    final eCell = _getCellAt(x + 1, y);
    final swCell = _getCellAt(x - 1, y + 1);
    final sCell = _getCellAt(x, y + 1);
    final seCell = _getCellAt(x + 1, y + 1);

    bool test(CellViewData? c) => c != null && predicate(c);

    final centerMatches = cCell != null && predicate(cCell);
    final hasNW = centerMatches && (test(nwCell) || test(nCell) || test(wCell));
    final hasNE = centerMatches && (test(neCell) || test(nCell) || test(eCell));
    final hasSW = centerMatches && (test(swCell) || test(sCell) || test(wCell));
    final hasSE = centerMatches && (test(seCell) || test(sCell) || test(eCell));

    final allSame = (hasNW == hasNE && hasNE == hasSW && hasSW == hasSE);
    final same = allSame && (!hasNW || centerMatches);
    final value = hasNW;

    return _CornerValues(
      nw: hasNW,
      ne: hasNE,
      sw: hasSW,
      se: hasSE,
      same: same,
      value: value,
    );
  }

  _CornerValues _getCoastlineCornerValues(int x, int y) {
    final nwCell = _getCellAt(x - 1, y - 1);
    final nCell = _getCellAt(x, y - 1);
    final neCell = _getCellAt(x + 1, y - 1);
    final wCell = _getCellAt(x - 1, y);
    final eCell = _getCellAt(x + 1, y);
    final swCell = _getCellAt(x - 1, y + 1);
    final sCell = _getCellAt(x, y + 1);
    final seCell = _getCellAt(x + 1, y + 1);

    bool isLand(CellViewData? c) => c != null && !c.isSea;

    final hasNW = isLand(nwCell) || isLand(nCell) || isLand(wCell);
    final hasNE = isLand(neCell) || isLand(nCell) || isLand(eCell);
    final hasSW = isLand(swCell) || isLand(sCell) || isLand(wCell);
    final hasSE = isLand(seCell) || isLand(sCell) || isLand(eCell);

    final allSame = (hasNW == hasNE && hasNE == hasSW && hasSW == hasSE);
    final same = allSame && !hasNW;

    return _CornerValues(
      nw: hasNW,
      ne: hasNE,
      sw: hasSW,
      se: hasSE,
      same: same,
      value: hasNW,
    );
  }

  bool _drawTile(
    Canvas canvas,
    WangTileset tileset,
    double left,
    double top, {
    required bool nw,
    required bool ne,
    required bool sw,
    required bool se,
    required CellViewData cell,
  }) {
    final tile = tileset.findTile(nw: nw, ne: ne, sw: sw, se: se);
    if (tile == null) {
      _log.w(
        'No tile found in ${tileset.name} for corners: NW=$nw, NE=$ne, SW=$sw, SE=$se',
      );
      return false;
    }

    final srcRect = tile.boundingBox;
    final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
    canvas.drawImageRect(tileset.image, srcRect, dstRect, Paint());

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.fogged) {
      canvas.drawRect(
        dstRect,
        Paint()..color = Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
      );
    }
    return true;
  }

  CellViewData? _getCellAt(int x, int y) {
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return null;
    return region.cellAt(x, y);
  }

  String? _resourceIdForMapIcon(CellViewData cell) {
    final raw = cell.resourceId;
    if (raw == null) return null;
    if (visibilityMode != CtMapVisibilityMode.playerConstrained) {
      return raw;
    }
    final view = playerViewForResources;
    if (view == null) {
      throw StateError(
        'CtRegionMapComponent: playerConstrained requires playerViewForResources',
      );
    }
    final tileKey =
        '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
    return resourceIdVisibleInPlayerView(view, tileKey, raw);
  }

  void _paintOverlay(Canvas canvas) {
    final showResources =
        baseLayerDisplayMode != BaseLayerDisplayMode.terrainOnly;
    final showImprovementLabels =
        baseLayerDisplayMode ==
            BaseLayerDisplayMode.terrainAndResourcesImprovementLabels ||
        baseLayerDisplayMode ==
            BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;
    final showRoadLabels = baseLayerDisplayMode ==
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;

    // Z-order: resource icons, then improvement labels, then road labels
    // (SPEC/ui/map-widget.md § Base overlay paint order).
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          cell.visibility == TileVisibility.unrevealed) {
        continue;
      }

      final resourceForIcon = _resourceIdForMapIcon(cell);
      if (showResources && resourceForIcon != null) {
        final icon = resourceIconCache.getIcon(resourceForIcon);
        if (icon != null) {
          final iconSize = ResourceIconCache.iconSize;
          final tileLeft = cell.x * cellSize;
          final tileTop = cell.y * cellSize;

          final double iconX;
          final double iconY;
          if (cellSize > iconSize) {
            iconX = tileLeft;
            iconY = tileTop + cellSize - iconSize;
          } else {
            iconX = tileLeft + (cellSize - iconSize) / 2;
            iconY = cellSize < iconSize
                ? tileTop + cellSize - iconSize
                : tileTop + (cellSize - iconSize) / 2;
          }

          final dstRect = Rect.fromLTWH(iconX, iconY, iconSize, iconSize);
          final srcRect = Rect.fromLTWH(0, 0, iconSize, iconSize);
          final paint = Paint();
          if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
              cell.visibility == TileVisibility.fogged) {
            paint.colorFilter = ColorFilter.mode(
              const Color(0xFFFFFFFF).withValues(alpha: 0.6),
              BlendMode.modulate,
            );
          }
          canvas.drawImageRect(icon, srcRect, dstRect, paint);
        }
      }
    }

    if (showImprovementLabels) {
      for (final cell in region.cells) {
        if (cell.isSea) continue;
        if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
            cell.visibility == TileVisibility.unrevealed) {
          continue;
        }
        final imp = cell.improvementLevel ?? 0;
        if (imp <= 0) continue;
        _paintTileCornerLabel(
          canvas,
          cell,
          'I$imp',
          alignEnd: false,
        );
      }
    }

    if (showRoadLabels) {
      for (final cell in region.cells) {
        if (cell.isSea) continue;
        if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
            cell.visibility == TileVisibility.unrevealed) {
          continue;
        }
        final road = cell.roadLevel ?? 0;
        if (road <= 0) continue;
        _paintTileCornerLabel(
          canvas,
          cell,
          'R$road',
          alignEnd: true,
        );
      }
    }
  }

  /// Improvement labels: top-left; road labels: top-right. Inset from edges.
  void _paintTileCornerLabel(
    Canvas canvas,
    CellViewData cell,
    String text, {
    required bool alignEnd,
  }) {
    final tileLeft = cell.x * cellSize;
    final tileTop = cell.y * cellSize;
    final pad = math.max(1.0, cellSize * 0.06);
    final fontSize = math.max(8.0, cellSize * 0.25);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout(maxWidth: cellSize - 2 * pad);
    final y = tileTop + pad;
    final x = alignEnd
        ? tileLeft + cellSize - pad - textPainter.width
        : tileLeft + pad;
    textPainter.paint(canvas, Offset(x, y));
  }

  void _paintHoveredProvinceGlow(Canvas canvas) {
    final t = _hoverAnimationT;
    final opacity = 0.5 + 0.25 * math.sin(t * 2 * math.pi);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = const Color(0x88FFFFFF).withValues(alpha: opacity);
    final provinceId = _hoveredProvinceId!;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.regionCellId != provinceId) continue;
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (right.regionCellId != provinceId) {
            final xEdge = (x + 1) * cellSize;
            canvas.drawLine(
              Offset(xEdge, y * cellSize),
              Offset(xEdge, (y + 1) * cellSize),
              paint,
            );
          }
        }
        if (y + 1 < region.height) {
          final bottom = region.cellAt(x, y + 1);
          if (bottom.regionCellId != provinceId) {
            final yEdge = (y + 1) * cellSize;
            canvas.drawLine(
              Offset(x * cellSize, yEdge),
              Offset((x + 1) * cellSize, yEdge),
              paint,
            );
          }
        }
      }
    }
  }

  void _paintSelector(Canvas canvas) {
    final x = _hoveredTileX!;
    final y = _hoveredTileY!;
    final bounce = 1.0 + 0.04 * math.sin(_hoverAnimationT * 2 * math.pi);
    final cx = x * cellSize + cellSize / 2;
    final cy = y * cellSize + cellSize / 2;
    final half = (cellSize / 2 - 2.0) * bounce;
    final left = cx - half;
    final top = cy - half;
    final size = half * 2;
    final rect = Rect.fromLTWH(left, top, size, size);
    // Orange cursor when in work target selection mode; white otherwise.
    // SPEC/ui/map-widget.md § Work target selection mode.
    final color = (validTileKeys != null && validTileKeys!.isNotEmpty)
        ? const Color(0xFFFFAA00)
        : const Color(0xFFFFFFFF);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color;
    canvas.drawRect(rect, paint);
  }

  /// Semi-transparent tint on GP-owned land. SPEC/ui/map-widget.md § Province ownership.
  void _paintGreatPowerLandOwnershipTint(Canvas canvas) {
    paintGreatPowerOwnershipTintLayer(
      canvas: canvas,
      region: region,
      cellSize: cellSize,
      honorUnrevealedTiles:
          visibilityMode == CtMapVisibilityMode.playerConstrained,
    );
  }

  void _paintProvinceBorders(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _provinceBorderLandColor;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (cell.regionCellId != right.regionCellId) {
            paint.color = _provinceBorderColor(cell, right);
            final xEdge = (x + 1) * cellSize;
            canvas.drawLine(
              Offset(xEdge, y * cellSize),
              Offset(xEdge, (y + 1) * cellSize),
              paint,
            );
          }
        }
        if (y + 1 < region.height) {
          final bottom = region.cellAt(x, y + 1);
          if (cell.regionCellId != bottom.regionCellId) {
            paint.color = _provinceBorderColor(cell, bottom);
            final yEdge = (y + 1) * cellSize;
            canvas.drawLine(
              Offset(x * cellSize, yEdge),
              Offset((x + 1) * cellSize, yEdge),
              paint,
            );
          }
        }
      }
    }
  }

  Color _provinceBorderColor(CellViewData a, CellViewData b) {
    final aIsSea = a.isSea;
    final bIsSea = b.isSea;
    if (aIsSea && bIsSea) return _provinceBorderSeaZoneColor;
    if (!aIsSea && !bIsSea) return _provinceBorderLandColor;
    // Mixed land/sea edge.
    return _provinceBorderSeaLandColor;
  }

  void _paintFactionBorders(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF1A237E);
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.isSea) continue;
        final owner = cell.ownerFactionId ?? '';
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (!right.isSea && (right.ownerFactionId ?? '') != owner) {
            final xEdge = (x + 1) * cellSize;
            canvas.drawLine(
              Offset(xEdge, y * cellSize),
              Offset(xEdge, (y + 1) * cellSize),
              paint,
            );
          }
        }
        if (y + 1 < region.height) {
          final bottom = region.cellAt(x, y + 1);
          if (!bottom.isSea && (bottom.ownerFactionId ?? '') != owner) {
            final yEdge = (y + 1) * cellSize;
            canvas.drawLine(
              Offset(x * cellSize, yEdge),
              Offset((x + 1) * cellSize, yEdge),
              paint,
            );
          }
        }
      }
    }
  }

  void _paintCapitals(Canvas canvas) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black;
    for (final cap in region.capitalMarkers) {
      final cx = cap.x * cellSize + cellSize / 2;
      final cy = cap.y * cellSize + cellSize / 2;
      fill.color = const Color(0xFFFFD700);
      canvas.drawCircle(Offset(cx, cy), 6, fill);
      canvas.drawCircle(Offset(cx, cy), 6, stroke);
    }
  }

  void _paintTowns(Canvas canvas) {
    if (!townIconCache.isLoaded) return;

    for (final town in region.townMarkers) {
      final cell = region.cellAt(town.x, town.y);

      if (visibilityMode == CtMapVisibilityMode.playerConstrained) {
        if (cell.visibility == TileVisibility.unrevealed) {
          continue;
        }
      }

      final String townIconId =
          town.touchesSea ? 'town_coastal' : 'town_inland';
      _paintTownIconAt(
        canvas,
        cell: cell,
        cx: town.x,
        cy: town.y,
        icon: townIconId,
      );
    }

    for (final town in region.townMarkers) {
      if (!town.isPort) continue;
      final px = town.portIconX;
      final py = town.portIconY;
      if (px == null || py == null) continue;
      final portCell = region.cellAt(px, py);
      if (visibilityMode == CtMapVisibilityMode.playerConstrained) {
        if (portCell.visibility == TileVisibility.unrevealed) {
          continue;
        }
      }
      _paintTownIconAt(
        canvas,
        cell: portCell,
        cx: px,
        cy: py,
        icon: 'port',
      );
    }
  }

  void _paintTownIconAt(
    Canvas canvas, {
    required CellViewData cell,
    required int cx,
    required int cy,
    required String icon,
  }) {
    final uiImage = townIconCache.getIcon(icon);
    if (uiImage == null) return;

    final centerX = cx * cellSize + cellSize / 2;
    final centerY = cy * cellSize + cellSize / 2;
    final halfIcon = TownIconCache.iconSize / 2;

    final srcRect = Rect.fromLTWH(
      0,
      0,
      TownIconCache.iconSize,
      TownIconCache.iconSize,
    );
    final dstRect = Rect.fromLTWH(
      centerX - halfIcon,
      centerY - halfIcon,
      TownIconCache.iconSize,
      TownIconCache.iconSize,
    );

    var paint = Paint();
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.fogged) {
      paint.color = Color.fromRGBO(0, 0, 0, _fogOverlayOpacity);
    }
    canvas.drawImageRect(uiImage, srcRect, dstRect, paint);
  }

  void _paintWarpZones(Canvas canvas) {
    // Collect sea zone ids that are warp zones.
    final warpSeaZoneIds = region.warpMarkers.map((m) => m.seaZoneId).toSet();
    if (warpSeaZoneIds.isEmpty) return;

    // Build a set of all tile positions belonging to warp sea zones.
    final warpTiles = <(int x, int y)>{};
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (warpSeaZoneIds.contains(cell.regionCellId)) {
          warpTiles.add((x, y));
        }
      }
    }

    // Draw glowing yellow border around warp sea zone tiles.
    // Outer glow (wider, more transparent).
    final glowOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3); // gold glow
    // Inner bright border.
    final glowInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFFEA00); // bright yellow

    for (final (x, y) in warpTiles) {
      final cell = region.cellAt(x, y);
      if (!warpSeaZoneIds.contains(cell.regionCellId)) continue;

      // Check right neighbor.
      if (x + 1 < region.width) {
        final right = region.cellAt(x + 1, y);
        if (!warpSeaZoneIds.contains(right.regionCellId)) {
          final xEdge = (x + 1) * cellSize;
          canvas.drawLine(
            Offset(xEdge, y * cellSize),
            Offset(xEdge, (y + 1) * cellSize),
            glowOuter,
          );
          canvas.drawLine(
            Offset(xEdge, y * cellSize),
            Offset(xEdge, (y + 1) * cellSize),
            glowInner,
          );
        }
      }
      // Check bottom neighbor.
      if (y + 1 < region.height) {
        final bottom = region.cellAt(x, y + 1);
        if (!warpSeaZoneIds.contains(bottom.regionCellId)) {
          final yEdge = (y + 1) * cellSize;
          canvas.drawLine(
            Offset(x * cellSize, yEdge),
            Offset((x + 1) * cellSize, yEdge),
            glowOuter,
          );
          canvas.drawLine(
            Offset(x * cellSize, yEdge),
            Offset((x + 1) * cellSize, yEdge),
            glowInner,
          );
        }
      }
      // Check left neighbor (for left edge of warp zone).
      if (x > 0) {
        final left = region.cellAt(x - 1, y);
        if (!warpSeaZoneIds.contains(left.regionCellId)) {
          final xEdge = x * cellSize;
          canvas.drawLine(
            Offset(xEdge, y * cellSize),
            Offset(xEdge, (y + 1) * cellSize),
            glowOuter,
          );
          canvas.drawLine(
            Offset(xEdge, y * cellSize),
            Offset(xEdge, (y + 1) * cellSize),
            glowInner,
          );
        }
      }
      // Check top neighbor (for top edge of warp zone).
      if (y > 0) {
        final top = region.cellAt(x, y - 1);
        if (!warpSeaZoneIds.contains(top.regionCellId)) {
          final yEdge = y * cellSize;
          canvas.drawLine(
            Offset(x * cellSize, yEdge),
            Offset((x + 1) * cellSize, yEdge),
            glowOuter,
          );
          canvas.drawLine(
            Offset(x * cellSize, yEdge),
            Offset((x + 1) * cellSize, yEdge),
            glowInner,
          );
        }
      }
    }
  }
}

class _CornerValues {
  final bool nw;
  final bool ne;
  final bool sw;
  final bool se;
  final bool same;
  final bool value;

  _CornerValues({
    required this.nw,
    required this.ne,
    required this.sw,
    required this.se,
    required this.same,
    required this.value,
  });
}
