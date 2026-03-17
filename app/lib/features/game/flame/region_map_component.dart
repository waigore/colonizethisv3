import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'terrain_tileset.dart';

final _log = Logger();

/// Fog strength for fogged tiles: lerp toward black (0 = no fog, 1 = full black).
const double _fogLerp = 0.4;
/// Fog overlay opacity when drawing a dark rect over tiles (0 = no overlay, 1 = full black).
const double _fogOverlayOpacity = 0.4;

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

/// Base layer display mode: which tile letters are drawn. SPEC/ui/map-widget.md § Base layer display mode.
enum BaseLayerDisplayMode {
  /// Terrain only; no resource or improvement/road letters.
  terrainOnly,

  /// Terrain + resource letters (g, t, i, …).
  terrainAndResources,

  /// Terrain + resource letters + improvement/road labels (I0, R0, …).
  terrainResourcesImprovements,
}

/// Flame-based region map component. Renders one RegionMapViewData and exposes
/// hover/selection state via callbacks. SPEC/ui/map-widget.md.
class CtRegionMapComponent extends PositionComponent {
  CtRegionMapComponent({
    required this.region,
    required this.cellSize,
    required this.showPoliticalOverlay,
    required this.visibilityMode,
    this.baseLayerDisplayMode =
        BaseLayerDisplayMode.terrainResourcesImprovements,
    this.onProvinceSelected,
    this.onProvinceHovered,
    this.onTileHovered,
    this.highlightedTileKey,
    this.validTileKeys,
  });

  RegionMapViewData region;
  double cellSize;
  bool showPoliticalOverlay;
  CtMapVisibilityMode visibilityMode;
  BaseLayerDisplayMode baseLayerDisplayMode;
  void Function(String provinceId)? onProvinceSelected;
  void Function(String? provinceId)? onProvinceHovered;
  void Function(String? tileKey)? onTileHovered;
  String? highlightedTileKey;
  Set<String>? validTileKeys;

  int? _hoveredTileX;
  int? _hoveredTileY;
  String? _hoveredProvinceId;
  double _hoverAnimationT = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await terrainTilesetCache.load();
    _log.i(
      'TerrainTilesetCache loaded. '
      'sea_plains: ${terrainTilesetCache.getSeaPlainsTileset() != null}, '
      'sea_desert: ${terrainTilesetCache.getSeaDesertTileset() != null}, '
      'plains_desert: ${terrainTilesetCache.getPlainsDesertTileset() != null}',
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
      if (validTileKeys!.isNotEmpty && validTileKeys!.contains(tileKey)) {
        // Work-target mode with valid tiles: widget wrapper will translate to onTileSelected.
        onTileHovered?.call(tileKey);
      } else {
        // No valid tiles OR non-valid tile tapped: trigger cancel via wrapper.
        onTileHovered?.call(null);
      }
      return;
    }
    // Not in work target mode: allow province selection.
    final provinceId = '${region.regionId}|${cell.regionCellId}';
    onProvinceSelected?.call(provinceId);

    // On touch/mobile, treat tap as hover so the selector and province glow
    // move to the tapped tile (for non-unrevealed tiles). SPEC/ui/map-widget.md.
    _setHoverFromCell(x, y);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _paintTiles(canvas);
    _paintLetters(canvas);
    _paintProvinceBorders(canvas);
    if (_hoveredProvinceId != null) {
      _paintHoveredProvinceGlow(canvas);
    }
    if (showPoliticalOverlay) _paintFactionBorders(canvas);
    _paintCapitals(canvas);
    _paintPorts(canvas);
    if (_hoveredTileX != null && _hoveredTileY != null) {
      _paintSelector(canvas);
    }
    if (highlightedTileKey != null) {
      _paintHighlightedTile(canvas);
    }
    if (validTileKeys != null && validTileKeys!.isNotEmpty) {
      _paintValidTilesGlow(canvas);
    }
  }

  void _paintValidTilesGlow(Canvas canvas) {
    final keys = validTileKeys!;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x44AAFF88);
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

  void _paintHighlightedTile(Canvas canvas) {
    final key = highlightedTileKey!;
    final parts = key.split('|');
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
      ..strokeWidth = 2.5
      ..color = const Color(0xFFFFAA00);
    canvas.drawRect(rect, paint);
  }

  void _paintTiles(Canvas canvas) {
    if (!terrainTilesetCache.isLoaded) {
      _paintTilesFallback(canvas);
      return;
    }
    _paintTilesWithTilesets(canvas);
  }

  void _paintTilesFallback(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final cell in region.cells) {
      final left = cell.x * cellSize;
      final top = cell.y * cellSize;

      Color baseColor;
      if (cell.isSea) {
        baseColor = const Color(0xFF003366);
      } else {
        final terrain =
            cell.terrainType ??
            (cell.terrainTypeId != null
                ? TerrainType.values.byName(cell.terrainTypeId!)
                : null);
        final rgb = terrain != null
            ? (region.terrainColors[terrain] ?? (128, 128, 128))
            : (128, 128, 128);
        baseColor = Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3);
      }

      Color finalColor = baseColor;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained) {
        switch (cell.visibility) {
          case TileVisibility.visible:
            break;
          case TileVisibility.fogged:
            finalColor = Color.lerp(baseColor, Colors.black, _fogLerp)!;
            break;
          case TileVisibility.unrevealed:
            finalColor = Colors.black;
            break;
        }
      }

      paint.color = finalColor;
      canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
    }
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
      final baseColor = const Color(0xFF1e3a5f);
      final foggedColor =
          visibilityMode == CtMapVisibilityMode.playerConstrained &&
              cell.visibility == TileVisibility.fogged
          ? Color.lerp(baseColor, Colors.black, _fogLerp)!
          : baseColor;
      canvas.drawRect(
        Rect.fromLTWH(left, top, cellSize, cellSize),
        Paint()..color = foggedColor,
      );
      return;
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

    // Handle invalid terrain (should not happen, but fallback)
    if (terrain == null) {
      _paintSolidColor(
        canvas,
        cell,
        const Color(0xFF7cb342),
      ); // Plains fallback
      return;
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
      if (tileset != null) {
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
    }

    if (isDesert && !nearPlainsCorner.same && nearPlainsCorner.value) {
      final tileset = terrainTilesetCache.getPlainsDesertTileset();
      if (tileset != null) {
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
    }

    // Interior cell - use base tile from sea tileset (cleaner with transition_size=0.5)
    // Plains uses sea_plains tileset, Desert uses sea_desert tileset
    // Note: In sea tilesets, 'lower'=sea, 'upper'=land
    final interiorTileset = terrain == TerrainType.desert
        ? terrainTilesetCache.getSeaDesertTileset()
        : terrainTilesetCache.getSeaPlainsTileset();
    if (interiorTileset != null) {
      // Use upperBaseTileId for both plains and desert (land is 'upper' in sea tilesets)
      final tile = interiorTileset.upperBaseTileId != null
          ? interiorTileset.findTileById(interiorTileset.upperBaseTileId!)
          : null;
      if (tile != null) {
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
        return;
      }
    }

    // Fallback - use solid color
    final rgb = terrain == TerrainType.desert
        ? (215, 204, 200) // Desert beige
        : (124, 179, 66); // Plains green
    _paintSolidColor(canvas, cell, Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3));
  }

  void _paintSolidColor(Canvas canvas, CellViewData cell, Color baseColor) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;
    final paint = Paint();
    paint.color = _applyFog(cell, baseColor);
    canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
  }

  void _applyVisibilityFilter(CellViewData cell, Paint paint) {
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.fogged) {
      paint.colorFilter = ColorFilter.mode(
        Color.fromRGBO(0, 0, 0, _fogOverlayOpacity),
        BlendMode.darken,
      );
    }
  }

  Color _applyFog(CellViewData cell, Color baseColor) {
    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.fogged) {
      return Color.lerp(baseColor, Colors.black, _fogLerp)!;
    }
    return baseColor;
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

    // All features use standalone tiles; plains base is already drawn in pass 1
    final standaloneTile = terrainTilesetCache.getStandaloneTile(terrain);

    if (standaloneTile != null) {
      final paint = Paint();
      _applyVisibilityFilter(cell, paint);

      final srcRect = Rect.fromLTWH(
        0,
        0,
        standaloneTile.image.width.toDouble(),
        standaloneTile.image.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
      canvas.drawImageRect(standaloneTile.image, srcRect, dstRect, paint);
      return;
    }

    // Fallback to solid color if no tile available
    final paint = Paint();
    final rgb = _getFallbackColor(terrain);
    Color baseColor = Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3);
    baseColor = _applyFog(cell, baseColor);
    paint.color = baseColor;
    canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
  }

  (int, int, int) _getFallbackColor(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.forest => (46, 125, 50),
      TerrainType.hills => (109, 76, 65),
      TerrainType.mountain => (120, 144, 156),
      TerrainType.swamp => (61, 74, 63),
      TerrainType.plains => (124, 179, 66),
      TerrainType.desert => (215, 204, 200),
    };
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

  void _paintLetters(Canvas canvas) {
    final showResources =
        baseLayerDisplayMode == BaseLayerDisplayMode.terrainAndResources ||
        baseLayerDisplayMode ==
            BaseLayerDisplayMode.terrainResourcesImprovements;
    final showImprovements =
        baseLayerDisplayMode ==
        BaseLayerDisplayMode.terrainResourcesImprovements;

    final double fontSize = math.max(10.0, cellSize * 0.35);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          cell.visibility == TileVisibility.unrevealed) {
        continue;
      }
      final parts = <String>[];
      if (showResources) {
        final letter = resourceIdToLegendLetter(cell.resourceId);
        if (letter != null) parts.add(letter);
      }
      if (showImprovements) {
        final imp = cell.improvementLevel ?? 0;
        parts.add('I$imp');
        final road = cell.roadLevel ?? 0;
        parts.add('R$road');
      }
      final text = parts.join(' ');
      if (text.isEmpty) continue;
      final cx = cell.x * cellSize + cellSize / 2;
      final cy = cell.y * cellSize + cellSize / 2;
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
    }
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
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFFFFFFF);
    canvas.drawRect(rect, paint);
  }

  void _paintProvinceBorders(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.black;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (cell.regionCellId != right.regionCellId) {
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

  void _paintPorts(Canvas canvas) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF00648C);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black;
    const half = 4.0;
    for (final port in region.portMarkers) {
      final cx = port.x * cellSize + cellSize / 2;
      final cy = port.y * cellSize + cellSize / 2;
      final rect = Rect.fromLTWH(cx - half, cy - half, half * 2, half * 2);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
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
