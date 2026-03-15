import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'terrain_tileset.dart';

/// Visibility mode for the region map. SPEC/ui/map-widget.md.
enum CtMapVisibilityMode {
  /// Full visibility: ignore per-tile visibility and render all tiles as visible.
  full,

  /// Player-constrained visibility: honor [CellViewData.visibility] for each tile.
  playerConstrained,
}

/// Flame-based region map component. Renders one RegionMapViewData and exposes
/// hover/selection state via callbacks. SPEC/ui/map-widget.md.
class CtRegionMapComponent extends PositionComponent {
  CtRegionMapComponent({
    required this.region,
    required this.cellSize,
    required this.showPoliticalOverlay,
    required this.visibilityMode,
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
    if (validTileKeys != null && validTileKeys!.isNotEmpty) {
      if (validTileKeys!.contains(tileKey)) {
        // Work-target mode: widget wrapper will translate to onTileSelected.
        onTileHovered?.call(tileKey);
      } else {
        // Non-valid tile: wrapper may treat as cancel.
        onTileHovered?.call(null);
      }
      return;
    }
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
            finalColor = Color.lerp(baseColor, Colors.black, 0.7)!;
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
    for (final cell in region.cells) {
      _paintCellWithTileset(canvas, cell);
    }
  }

  void _paintCellWithTileset(Canvas canvas, CellViewData cell) {
    final left = cell.x * cellSize;
    final top = cell.y * cellSize;

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.unrevealed) {
      final paint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
      return;
    }

    final cellTerrain = cell.isSea ? null : cell.terrainType;

    bool tileDrawn = false;
    final nearSea = _isNearTerrain(cell.x, cell.y, seaTerrainId);

    if (!cell.isSea) {
      if (nearSea) {
        tileDrawn = _drawSeaBeachTransition(canvas, cell, left, top);
      }
      if (cellTerrain != null && cellTerrain != TerrainType.plains) {
        tileDrawn =
            _drawPlainsFeatureTransition(canvas, cell, left, top) || tileDrawn;
      }
      if (!tileDrawn && !nearSea) {
        tileDrawn = _drawBeachPlainsTransition(canvas, cell, left, top);
      }
    }

    if (!tileDrawn && cell.isSea) {
      tileDrawn = _drawSeaTile(canvas, cell, left, top);
    }

    if (!tileDrawn) {
      _paintCellFallback(canvas, cell, left, top);
    }
  }

  bool _isNearTerrain(int x, int y, String terrainId) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= region.width || ny < 0 || ny >= region.height) {
          continue;
        }
        final neighbor = region.cellAt(nx, ny);
        if (terrainId == seaTerrainId && neighbor.isSea) return true;
        if (terrainId == TerrainType.plains.name &&
            !neighbor.isSea &&
            neighbor.terrainType == TerrainType.plains) {
          return true;
        }
      }
    }
    return false;
  }

  bool _drawSeaTile(Canvas canvas, CellViewData cell, double left, double top) {
    final seaCorner = _getCornerValues(cell.x, cell.y, (c) => !c.isSea);
    if (seaCorner.same) return false;

    final tileset = terrainTilesetCache.getSeaBeachTileset();
    if (tileset == null) return false;

    return _drawTile(
      canvas,
      tileset,
      left,
      top,
      nw: seaCorner.nw,
      ne: seaCorner.ne,
      sw: seaCorner.sw,
      se: seaCorner.se,
      cell: cell,
    );
  }

  bool _drawSeaBeachTransition(
    Canvas canvas,
    CellViewData cell,
    double left,
    double top,
  ) {
    final nearSeaCorner = _getCornerValues(cell.x, cell.y, (c) => c.isSea);
    if (nearSeaCorner.same) return false;

    final tileset = terrainTilesetCache.getSeaBeachTileset();
    if (tileset == null) return false;

    return _drawTile(
      canvas,
      tileset,
      left,
      top,
      nw: nearSeaCorner.nw,
      ne: nearSeaCorner.ne,
      sw: nearSeaCorner.sw,
      se: nearSeaCorner.se,
      cell: cell,
    );
  }

  bool _drawBeachPlainsTransition(
    Canvas canvas,
    CellViewData cell,
    double left,
    double top,
  ) {
    final tileset = terrainTilesetCache.getBeachPlainsTileset();
    if (tileset == null) return false;

    return _drawTile(
      canvas,
      tileset,
      left,
      top,
      nw: false,
      ne: false,
      sw: false,
      se: false,
      cell: cell,
    );
  }

  bool _drawPlainsFeatureTransition(
    Canvas canvas,
    CellViewData cell,
    double left,
    double top,
  ) {
    final terrain = cell.terrainType;
    if (terrain == null || terrain == TerrainType.plains) return false;

    final featureCorner = _getCornerValues(cell.x, cell.y, (c) {
      if (c.isSea) return false;
      return c.terrainType == terrain || c.terrainType == null;
    });

    final tileset = terrainTilesetCache.getTilesetForIds(
      TerrainType.plains.name,
      terrain.name,
    );
    if (tileset == null) return false;

    if (featureCorner.same && !featureCorner.value) {
      return false;
    }

    return _drawTile(
      canvas,
      tileset,
      left,
      top,
      nw: featureCorner.nw,
      ne: featureCorner.ne,
      sw: featureCorner.sw,
      se: featureCorner.se,
      cell: cell,
    );
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
    if (tile == null) return false;

    final srcRect = tile.boundingBox;
    final dstRect = Rect.fromLTWH(left, top, cellSize, cellSize);
    final paint = Paint();

    if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.fogged) {
      paint.colorFilter = const ColorFilter.mode(
        Color.fromRGBO(0, 0, 0, 0.7),
        BlendMode.darken,
      );
    }

    canvas.drawImageRect(tileset.image, srcRect, dstRect, paint);
    return true;
  }

  CellViewData? _getCellAt(int x, int y) {
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return null;
    return region.cellAt(x, y);
  }

  void _paintCellFallback(
    Canvas canvas,
    CellViewData cell,
    double left,
    double top,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;

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
          finalColor = Color.lerp(baseColor, Colors.black, 0.7)!;
          break;
        case TileVisibility.unrevealed:
          finalColor = Colors.black;
          break;
      }
    }

    paint.color = finalColor;
    canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
  }

  void _paintLetters(Canvas canvas) {
    final double fontSize = math.max(10.0, cellSize * 0.35);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final cell in region.cells) {
      if (cell.isSea) continue;
      if (visibilityMode == CtMapVisibilityMode.playerConstrained &&
          cell.visibility == TileVisibility.unrevealed) {
        continue;
      }
      final parts = <String>[];
      final letter = resourceIdToLegendLetter(cell.resourceId);
      if (letter != null) parts.add(letter);
      final imp = cell.improvementLevel ?? 0;
      parts.add('I$imp');
      final road = cell.roadLevel ?? 0;
      parts.add('R$road');
      final text = parts.join(' ');
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
