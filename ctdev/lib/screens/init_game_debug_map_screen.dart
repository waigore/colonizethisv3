import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../ctdev_log.dart';
import '../debug_map_painter.dart';
import 'running_game_screen.dart';

class InitGameDebugMapScreen extends StatefulWidget {
  const InitGameDebugMapScreen({
    super.key,
    required this.initResult,
    required this.baseSeed,
  });

  final InitGameResult initResult;
  final int baseSeed;

  @override
  State<InitGameDebugMapScreen> createState() => _InitGameDebugMapScreenState();
}

class _InitGameDebugMapScreenState extends State<InitGameDebugMapScreen> {
  late InitGameMapViewData _viewData;

  CellViewData? _selectedCell;
  String? _selectedRegionId;

  final TransformationController _controller = TransformationController();
  bool _initialTransformApplied = false;

  bool _showOwnership = true;
  bool _showCapitals = true;
  bool _showPorts = true;
   // When true, render geographic (terrain/resources) view instead of political ownership fill.
  bool _geographicMode = false;
  bool _hoveringResourceLegend = false;
  bool _useSimGameAi = true;
  bool _useFullAI = false;

  @override
  void initState() {
    super.initState();
    _viewData = widget.initResult.mapViewData;
  }

  Game get _currentGame => widget.initResult.game;

  void _updateSelectedFromScenePoint(Offset scenePos) {
    final ow = _viewData.oldWorld;
    final nw = _viewData.newWorld;
    final baseCellSize = ow.cellSize.toDouble();
    final viewCellSize = baseCellSize * kDebugMapScale;
    final gap = viewCellSize * 2;
    final owWidthPx = ow.width * viewCellSize;

    RegionMapViewData region;
    double localX;
    if (scenePos.dx < owWidthPx) {
      region = ow;
      localX = scenePos.dx;
    } else if (scenePos.dx > owWidthPx + gap) {
      region = nw;
      localX = scenePos.dx - owWidthPx - gap;
    } else {
      // Gap between maps.
      return;
    }

    final x = (localX / viewCellSize).floor();
    final y = (scenePos.dy / viewCellSize).floor();
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return;

    final cell = region.cellAt(x, y);
    setState(() {
      _selectedCell = cell;
      _selectedRegionId = region.regionId;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    final scenePos = _controller.toScene(details.localPosition);
    _updateSelectedFromScenePoint(scenePos);
  }

  void _handleHover(PointerHoverEvent event) {
    // Use localPosition so coordinates are relative to the MouseRegion/map,
    // matching the tap path and avoiding vertical offsets from header widgets.
    final scenePos = _controller.toScene(event.localPosition);
    _updateSelectedFromScenePoint(scenePos);
  }

  void _clearSelection() {
    setState(() {
      _selectedCell = null;
      _selectedRegionId = null;
    });
  }

  /// Resolves faction display name from current game for legend.
  String _factionDisplayName(String factionId) {
    final game = _currentGame;
    for (final p in game.players) {
      if (p.id == factionId) return p.displayName;
    }
    for (final m in game.minorNations) {
      if (m.id == factionId) return m.displayName ?? factionId;
    }
    for (final t in game.tribes) {
      if (t.id == factionId) return t.displayName ?? factionId;
    }
    return factionId;
  }

  bool _isCapitalTile(CellViewData cell, String? regionId) {
    if (regionId == null) return false;
    final region = regionId == 'oldWorld' ? _viewData.oldWorld : _viewData.newWorld;
    for (final cap in region.capitalMarkers) {
      if (cap.x == cell.x && cap.y == cell.y) return true;
    }
    return false;
  }

  String _capitalDisplayNameAt(int x, int y, String? regionId) {
    if (regionId == null) return '—';
    final region = regionId == 'oldWorld' ? _viewData.oldWorld : _viewData.newWorld;
    for (final cap in region.capitalMarkers) {
      if (cap.x == x && cap.y == y) return cap.displayName;
    }
    return '—';
  }

  Widget _buildLegend(InitGameMapViewData viewData) {
    final ow = viewData.oldWorld;
    final items = <Widget>[];

    // Sea.
    items.add(_legendSwatchRow(const Color(0xFF003366), 'Sea'));

    if (_geographicMode) {
      // Terrain colours (geographic view).
      ow.terrainColors.forEach((terrain, rgb) {
        items.add(
          _legendSwatchRow(
            Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3),
            'Terrain: $terrain',
          ),
        );
      });
      // Compact glyph reference: all 18 resource letters. Hover to see full legend in right panel.
      final glyphLetters = Resource.values
          .map((r) => resourceIdToLegendLetter(r.name))
          .whereType<String>()
          .join(' ');
      final (owCounts, nwCounts) = _resourceCountsPerRegion(viewData);
      final owLine = _formatResourceCountLine('OW', owCounts);
      final nwLine = _formatResourceCountLine('NW', nwCounts);
      items.add(
        MouseRegion(
          onEnter: (_) => setState(() => _hoveringResourceLegend = true),
          onExit: (_) => setState(() => _hoveringResourceLegend = false),
          cursor: SystemMouseCursors.help,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Resources: $glyphLetters',
                style: const TextStyle(fontSize: 11),
              ),
              Text('$owLine\n$nwLine', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );
    } else {
      // Ownership colours (political view): displayName (factionId).
      ow.factionColors.forEach((factionId, rgb) {
        final label = '${_factionDisplayName(factionId)} ($factionId)';
        items.add(
          _legendSwatchRow(
            Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3),
            label,
          ),
        );
      });
    }

    // Capitals and ports markers.
    items.add(const Text('Capitals: gold circle; Ports: teal square'));

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }

  void _startSimGame() {
    final sessionId =
        '${DateTime.now().millisecondsSinceEpoch}_${(math.Random().nextDouble() * 0xFFFF).floor().toRadixString(16)}';
    startSimSession(sessionId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RunningGameScreen(
          sessionId: sessionId,
          initResult: widget.initResult,
          baseSeed: widget.baseSeed,
          useSimGameAi: _useSimGameAi,
          useFullAI: _useFullAI,
        ),
      ),
    );
  }

  /// Returns (OW resource counts, NW resource counts) from view data.
  (Map<String, int> ow, Map<String, int> nw) _resourceCountsPerRegion(
    InitGameMapViewData viewData,
  ) {
    final owCounts = <String, int>{};
    final nwCounts = <String, int>{};
    for (final cell in viewData.oldWorld.cells) {
      if (cell.isSea || cell.resourceId == null || cell.resourceId!.isEmpty) {
        continue;
      }
      owCounts[cell.resourceId!] = (owCounts[cell.resourceId!] ?? 0) + 1;
    }
    for (final cell in viewData.newWorld.cells) {
      if (cell.isSea || cell.resourceId == null || cell.resourceId!.isEmpty) {
        continue;
      }
      nwCounts[cell.resourceId!] = (nwCounts[cell.resourceId!] ?? 0) + 1;
    }
    return (owCounts, nwCounts);
  }

  /// Formats resource counts as compact line, e.g. "OW: g12 m8 w5".
  String _formatResourceCountLine(String prefix, Map<String, int> counts) {
    if (counts.isEmpty) return '$prefix: (none)';
    final parts = <String>[];
    for (final r in Resource.values) {
      final count = counts[r.name];
      if (count != null && count > 0) {
        final letter = resourceIdToLegendLetter(r.name);
        if (letter != null) parts.add('$letter$count');
      }
    }
    return '$prefix: ${parts.join(' ')}';
  }

  Widget _buildFullResourceLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Resource glyphs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            for (final r in Resource.values)
              Builder(
                builder: (_) {
                  final letter = resourceIdToLegendLetter(r.name);
                  if (letter == null) return const SizedBox.shrink();
                  final name = r.name == 'sugarCane'
                      ? 'Sugar cane'
                      : r.name[0].toUpperCase() + r.name.substring(1);
                  return Text(
                    '$letter = $name',
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _legendSwatchRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ow = _viewData.oldWorld;
    final nw = _viewData.newWorld;
    final baseCellSize = ow.cellSize.toDouble();
    final viewCellSize = baseCellSize * kDebugMapScale;
    final gap = viewCellSize * 2;
    final owWidthPx = ow.width * viewCellSize;
    final nwWidthPx = nw.width * viewCellSize;
    final totalWidth = owWidthPx + gap + nwWidthPx;
    final totalHeight =
        math.max(ow.height * viewCellSize, nw.height * viewCellSize).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Init Game Map Debug'),
      ),
      body: Row(
        children: [
          // Left: map and controls.
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'OldWorld: ${ow.width}x${ow.height}, '
                    'NewWorld: ${nw.width}x${nw.height}  '
                    '(Seed: ${_viewData.seed ?? '—'})',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildLegend(_viewData),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Switch(
                            value: _geographicMode,
                            onChanged: (v) =>
                                setState(() => _geographicMode = v),
                          ),
                          const Text('Geographic view'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _showOwnership,
                            onChanged: _geographicMode
                                ? null
                                : (v) => setState(
                                      () => _showOwnership = v ?? true,
                                    ),
                          ),
                          const Text('Ownership'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _showCapitals,
                            onChanged: (v) =>
                                setState(() => _showCapitals = v ?? true),
                          ),
                          const Text('Capitals'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _showPorts,
                            onChanged: (v) =>
                                setState(() => _showPorts = v ?? true),
                          ),
                          const Text('Ports'),
                        ],
                      ),
                      const SizedBox(width: 24),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Sim Game AI'),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('AI Planner'),
                          ),
                        ],
                        selected: {_useSimGameAi},
                        onSelectionChanged: (s) {
                          setState(() => _useSimGameAi = s.first);
                        },
                      ),
                      if (!_useSimGameAi) ...[
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _useFullAI,
                              onChanged: (v) =>
                                  setState(() => _useFullAI = v ?? false),
                            ),
                            const Text('Use full AI (Phase 6)'),
                          ],
                        ),
                      ],
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _startSimGame,
                        child: const Text('Start Game (Sim)'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Compute initial scale to fit map in viewport, but never
                      // start smaller than a 1:1 tile size for readability.
                      final scaleX = constraints.maxWidth / totalWidth;
                      final scaleY = constraints.maxHeight / totalHeight;
                      final fitScale = math.min(scaleX, scaleY);
                      final initialScale = math.max(1.0, fitScale);
                      if (!_initialTransformApplied &&
                          initialScale.isFinite &&
                          initialScale > 0) {
                        _controller.value = Matrix4.identity()
                          ..scaleByDouble(initialScale, initialScale, initialScale, 1.0);
                        _initialTransformApplied = true;
                      }

                      return MouseRegion(
                        onHover: _handleHover,
                        onExit: (_) => _clearSelection(),
                        child: GestureDetector(
                          onTapDown: _handleTapDown,
                          child: InteractiveViewer(
                            transformationController: _controller,
                            minScale: 0.25,
                            maxScale: 4.0,
                            child: CustomPaint(
                              size: Size(totalWidth, totalHeight),
                              painter: CombinedMapPainter(
                                viewData: _viewData,
                                showOwnership: _showOwnership,
                                showCapitals: _showCapitals,
                                showPorts: _showPorts,
                                geographicMode: _geographicMode,
                                selectedRegionId: _selectedRegionId,
                                selectedX: _selectedCell?.x,
                                selectedY: _selectedCell?.y,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right: hover details panel.
          SizedBox(
            width: 280,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hoveringResourceLegend)
                        _buildFullResourceLegend()
                      else if (_selectedCell == null)
                        const Text('Hover a tile to see details.')
                      else ...[
                        Text(
                          'Region: ${_selectedRegionId ?? ''}  '
                          'Tile: (${_selectedCell!.x}, ${_selectedCell!.y})',
                        ),
                        Text('Id: ${_selectedCell!.regionCellId}'),
                        Text(
                          'Province: ${_selectedCell!.provinceDisplayName ?? _selectedCell!.regionCellId}',
                        ),
                        Text(
                          'Owner: ${_selectedCell!.ownerFactionId != null ? _factionDisplayName(_selectedCell!.ownerFactionId!) : '—'}',
                        ),
                        if (_isCapitalTile(_selectedCell!, _selectedRegionId))
                          Text(
                            'Capital of ${_capitalDisplayNameAt(_selectedCell!.x, _selectedCell!.y, _selectedRegionId)}.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        Text(
                          'Terrain: ${_selectedCell!.terrainTypeId ?? '—'}',
                        ),
                        Text(
                          'Resource: ${_selectedCell!.resourceId ?? '—'}',
                        ),
                      ],
                      const Divider(),
                      const Text(
                        'Press Start Game (Sim) to run simulation.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
