import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'debug_map_painter.dart';

void main() {
  runApp(const CtDevApp());
}

class CtDevApp extends StatelessWidget {
  const CtDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColonizeThis Dev',
      theme: ThemeData.light(useMaterial3: true),
      home: const CtDevHomeScreen(),
    );
  }
}

class CtDevHomeScreen extends StatelessWidget {
  const CtDevHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ColonizeThis Dev'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InitGameScreen(),
                  ),
                );
              },
              child: const Text('Init Game'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Placeholder for Load Savegame flow.
              },
              child: const Text('Load Savegame'),
            ),
          ],
        ),
      ),
    );
  }
}

class InitGameScreen extends StatelessWidget {
  const InitGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, just run default config and show a placeholder; wiring
    // full controls and a debug map viewer will follow.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Init Game (ctdev)'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final config = GameSetupConfig.defaultConfig;
            final result = runInitGame(
              config: config,
              options: const InitGameOptions(cellSize: 24),
            );
            final viewData = result.mapViewData;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InitGameDebugMapScreen(viewData: viewData),
              ),
            );
          },
          child: const Text('Run default init_game and view map'),
        ),
      ),
    );
  }
}

class InitGameDebugMapScreen extends StatefulWidget {
  const InitGameDebugMapScreen({super.key, required this.viewData});

  final InitGameMapViewData viewData;

  @override
  State<InitGameDebugMapScreen> createState() => _InitGameDebugMapScreenState();
}

class _InitGameDebugMapScreenState extends State<InitGameDebugMapScreen> {
  CellViewData? _selectedCell;
  String? _selectedRegionId;

  final TransformationController _controller = TransformationController();
  bool _initialTransformApplied = false;

  bool _showOwnership = true;
  bool _showCapitals = true;
  bool _showPorts = true;
   // When true, render geographic (terrain/resources) view instead of political ownership fill.
  bool _geographicMode = false;

  void _updateSelectedFromScenePoint(Offset scenePos) {
    final ow = widget.viewData.oldWorld;
    final nw = widget.viewData.newWorld;
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
      items.add(const Text('Resources: per-tile glyphs (g = grain, t = timber, i = iron)'));
    } else {
      // Ownership colours (political view).
      ow.factionColors.forEach((factionId, rgb) {
        items.add(
          _legendSwatchRow(
            Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3),
            'Owner: $factionId',
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
    final ow = widget.viewData.oldWorld;
    final nw = widget.viewData.newWorld;
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
                    'NewWorld: ${nw.width}x${nw.height}',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildLegend(widget.viewData),
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
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Compute initial scale to fit map in viewport.
                      final scaleX = constraints.maxWidth / totalWidth;
                      final scaleY = constraints.maxHeight / totalHeight;
                      final initialScale = math.min(scaleX, scaleY);
                      if (!_initialTransformApplied &&
                          initialScale.isFinite &&
                          initialScale > 0) {
                        _controller.value =
                            Matrix4.identity()..scale(initialScale);
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
                                viewData: widget.viewData,
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
                  child: _selectedCell == null
                      ? const Text('Hover a tile to see details.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Region: ${_selectedRegionId ?? ''}  '
                              'Tile: (${_selectedCell!.x}, ${_selectedCell!.y})',
                            ),
                            Text('Id: ${_selectedCell!.regionCellId}'),
                            Text(
                              'Owner: ${_selectedCell!.ownerFactionId ?? '—'}',
                            ),
                            Text(
                              'Terrain: ${_selectedCell!.terrainTypeId ?? '—'}',
                            ),
                            Text(
                              'Resource: ${_selectedCell!.resourceId ?? '—'}',
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
