// Debug-mode map widget: solid colors, letters for resources/improvements/roads,
// solid lines for province and faction borders. SPEC/ui/map-widget.md.
// For Widgetbook mockup and development; production map uses Flame.

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

/// Debug-mode region map widget. Renders [region] with:
/// - Solid colors per terrain (sea = fixed blue).
/// - Single letters for resources (g, t, i, etc.), improvement level (I0–I4), road (R0/R1/R2/R4).
/// - Solid lines: province borders (black), faction borders when [showPoliticalOverlay] (darker/thicker).
/// Pan/zoom via [InteractiveViewer]; tap reports province via [onProvinceSelected].
/// Hover: selector (square) with subtle bounce; hovered province borders glow with subtle animation.
class CtRegionMapDebug extends StatefulWidget {
  const CtRegionMapDebug({
    super.key,
    required this.region,
    this.showPoliticalOverlay = true,
    this.cellSizePx = 32,
    this.onProvinceSelected,
    this.onRegionViewChanged,
    this.onProvinceHovered,
    this.highlightedTileKey,
  });

  final RegionMapViewData region;
  final bool showPoliticalOverlay;
  final double cellSizePx;
  final void Function(String provinceId)? onProvinceSelected;
  final VoidCallback? onRegionViewChanged;
  final void Function(String? provinceId)? onProvinceHovered;
  /// When set, shows a secondary highlight over the tile (e.g. from overlay coordinate hover).
  /// Format: regionId|provinceId|x|y. Only used when regionId matches and x,y are in bounds.
  final String? highlightedTileKey;

  @override
  State<CtRegionMapDebug> createState() => _CtRegionMapDebugState();
}

class _CtRegionMapDebugState extends State<CtRegionMapDebug>
    with SingleTickerProviderStateMixin {
  int? _hoveredTileX;
  int? _hoveredTileY;
  late AnimationController _hoverAnimationController;

  static const int _hoverAnimationDurationMs = 800;

  @override
  void initState() {
    super.initState();
    _hoverAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _hoverAnimationDurationMs),
    );
    _hoverAnimationController.addListener(_onHoverAnimationTick);
  }

  void _onHoverAnimationTick() {
    if (_hoveredTileX != null && _hoveredTileY != null) {
      setState(() {});
    }
  }

  void _startHoverAnimationIfNeeded() {
    if (_hoveredTileX != null && _hoveredTileY != null) {
      if (!_hoverAnimationController.isAnimating) {
        _hoverAnimationController.repeat(reverse: true);
      }
    } else {
      _hoverAnimationController.stop();
      _hoverAnimationController.reset();
    }
  }

  @override
  void dispose() {
    _hoverAnimationController.removeListener(_onHoverAnimationTick);
    _hoverAnimationController.dispose();
    super.dispose();
  }

  void _updateHover(Offset? local) {
    final region = widget.region;
    final cellSizePx = widget.cellSizePx;
    int? nx;
    int? ny;
    if (local != null) {
      final x = (local.dx / cellSizePx).floor();
      final y = (local.dy / cellSizePx).floor();
      if (x >= 0 && x < region.width && y >= 0 && y < region.height) {
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
      widget.onProvinceHovered?.call(nextId);
    }
    setState(() {
      _hoveredTileX = nx;
      _hoveredTileY = ny;
    });
    _startHoverAnimationIfNeeded();
  }

  void _handleTap(Offset local, double mapWidth, double mapHeight) {
    final region = widget.region;
    final cellSizePx = widget.cellSizePx;
    final x = (local.dx / cellSizePx).floor();
    final y = (local.dy / cellSizePx).floor();
    if (x >= 0 && x < region.width && y >= 0 && y < region.height) {
      final cell = region.cellAt(x, y);
      final provinceId = '${region.regionId}|${cell.regionCellId}';
      widget.onProvinceSelected?.call(provinceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final region = widget.region;
    final mapWidth = region.width * widget.cellSizePx;
    final mapHeight = region.height * widget.cellSizePx;
    final animationT = _hoverAnimationController.value;
    final hoveredProvinceId = _hoveredTileX != null && _hoveredTileY != null
        ? region.cellAt(_hoveredTileX!, _hoveredTileY!).regionCellId
        : null;

    return InteractiveViewer(
      minScale: 0.25,
      maxScale: 4,
      child: SizedBox(
        width: mapWidth,
        height: mapHeight,
        child: MouseRegion(
          hitTestBehavior: HitTestBehavior.opaque,
          onHover: (event) => _updateHover(event.localPosition),
          onExit: (_) => _updateHover(null),
          child: GestureDetector(
            onTapUp: (details) =>
                _handleTap(details.localPosition, mapWidth, mapHeight),
            child: CustomPaint(
              size: Size(mapWidth, mapHeight),
              painter: _RegionMapDebugPainter(
                region: region,
                cellSize: widget.cellSizePx,
                showPoliticalOverlay: widget.showPoliticalOverlay,
                hoveredTileX: _hoveredTileX,
                hoveredTileY: _hoveredTileY,
                hoveredProvinceId: hoveredProvinceId,
                hoverAnimationT: animationT,
                highlightedTileKey: widget.highlightedTileKey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionMapDebugPainter extends CustomPainter {
  _RegionMapDebugPainter({
    required this.region,
    required this.cellSize,
    required this.showPoliticalOverlay,
    this.hoveredTileX,
    this.hoveredTileY,
    this.hoveredProvinceId,
    this.hoverAnimationT = 0.0,
    this.highlightedTileKey,
  });

  final RegionMapViewData region;
  final double cellSize;
  final bool showPoliticalOverlay;
  final int? hoveredTileX;
  final int? hoveredTileY;
  final String? hoveredProvinceId;
  final double hoverAnimationT;
  final String? highlightedTileKey;

  static const Color _seaColor = Color(0xFF003366);
  static const Color _provinceBorderColor = Colors.black;
  static const Color _factionBorderColor = Color(0xFF1A237E);
  static const double _provinceBorderWidth = 1.0;
  static const double _factionBorderWidth = 2.0;
  static const Color _selectorColor = Color(0xFFFFFFFF);
  static const Color _hoverGlowColor = Color(0x88FFFFFF);
  static const Color _highlightedTileColor = Color(0xFFFFAA00);
  static const double _highlightedTileStrokeWidth = 2.5;
  static const double _selectorInset = 2.0;
  static const double _selectorStrokeWidth = 2.0;
  static const double _hoverGlowStrokeWidth = 3.0;
  static const double _bounceScaleAmplitude = 0.04;
  static const double _glowOpacityMin = 0.5;
  static const double _glowOpacityAmplitude = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    _paintTiles(canvas);
    _paintLetters(canvas);
    _paintProvinceBorders(canvas);
    if (hoveredProvinceId != null) {
      _paintHoveredProvinceGlow(canvas);
    }
    if (showPoliticalOverlay) _paintFactionBorders(canvas);
    _paintCapitals(canvas);
    _paintPorts(canvas);
    if (hoveredTileX != null && hoveredTileY != null) {
      _paintSelector(canvas);
    }
    if (highlightedTileKey != null) {
      _paintHighlightedTile(canvas);
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
      ..strokeWidth = _highlightedTileStrokeWidth
      ..color = _highlightedTileColor;
    canvas.drawRect(rect, paint);
  }

  void _paintTiles(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final cell in region.cells) {
      final left = cell.x * cellSize;
      final top = cell.y * cellSize;
      if (cell.isSea) {
        paint.color = _seaColor;
      } else {
        final terrain = cell.terrainType ??
            (cell.terrainTypeId != null
                ? TerrainType.values.byName(cell.terrainTypeId!)
                : null);
        final rgb = terrain != null
            ? (region.terrainColors[terrain] ?? (128, 128, 128))
            : (128, 128, 128);
        paint.color = Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3);
      }
      canvas.drawRect(
        Rect.fromLTWH(left, top, cellSize, cellSize),
        paint,
      );
    }
  }

  void _paintLetters(Canvas canvas) {
    final double fontSize = math.max(10.0, cellSize * 0.35);
    for (final cell in region.cells) {
      if (cell.isSea) continue;
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
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
    }
  }

  void _paintHoveredProvinceGlow(Canvas canvas) {
    final t = hoverAnimationT;
    final opacity =
        _glowOpacityMin + _glowOpacityAmplitude * math.sin(t * 2 * math.pi);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _hoverGlowStrokeWidth
      ..color = _hoverGlowColor.withValues(alpha: opacity);
    final provinceId = hoveredProvinceId!;
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
    final x = hoveredTileX!;
    final y = hoveredTileY!;
    final bounce = 1.0 + _bounceScaleAmplitude * math.sin(hoverAnimationT * 2 * math.pi);
    final cx = x * cellSize + cellSize / 2;
    final cy = y * cellSize + cellSize / 2;
    final half = (cellSize / 2 - _selectorInset) * bounce;
    final left = cx - half;
    final top = cy - half;
    final size = half * 2;
    final rect = Rect.fromLTWH(left, top, size, size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _selectorStrokeWidth
      ..color = _selectorColor;
    canvas.drawRect(rect, paint);
  }

  void _paintProvinceBorders(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _provinceBorderWidth
      ..color = _provinceBorderColor;
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
      ..strokeWidth = _factionBorderWidth
      ..color = _factionBorderColor;
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.isSea) continue;
        final owner = cell.ownerFactionId ?? '';
        if (x + 1 < region.width) {
          final right = region.cellAt(x + 1, y);
          if (!right.isSea && (region.cellAt(x + 1, y).ownerFactionId ?? '') != owner) {
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

  @override
  bool shouldRepaint(covariant _RegionMapDebugPainter old) {
    return old.region != region ||
        old.cellSize != cellSize ||
        old.showPoliticalOverlay != showPoliticalOverlay ||
        old.hoveredTileX != hoveredTileX ||
        old.hoveredTileY != hoveredTileY ||
        old.hoveredProvinceId != hoveredProvinceId ||
        old.hoverAnimationT != hoverAnimationT ||
        old.highlightedTileKey != highlightedTileKey;
  }
}
