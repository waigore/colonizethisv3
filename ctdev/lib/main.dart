import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
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

class InitGameScreen extends StatefulWidget {
  const InitGameScreen({super.key});

  @override
  State<InitGameScreen> createState() => _InitGameScreenState();
}

class _InitGameScreenState extends State<InitGameScreen> {
  final _formKey = GlobalKey<FormState>();

  late int _greatPowerCount;
  late int _minorNationCount;
  late int _tribeCount;
  late int _numProvincesOldWorld;
  late int _numProvincesNewWorld;
  late int _continentCount;
  late int _minProvincesPerMinor;
  late int _seed;
  bool _skipFillLakes = false;
  bool _renderPng = false;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    const cfg = GameSetupConfig.defaultConfig;
    _greatPowerCount = cfg.greatPowerCount;
    _minorNationCount = cfg.minorNationCount;
    _tribeCount = cfg.tribeCount;
    _numProvincesOldWorld = cfg.numProvincesOldWorld;
    _numProvincesNewWorld = cfg.numProvincesNewWorld;
    _continentCount = cfg.continentCount;
    _minProvincesPerMinor = cfg.minProvincesPerMinor;
    // Seed is not prefilled from config; default to 0 so orchestration
    // chooses a time-based seed when the field is left blank.
    _seed = 0;
  }

  String? _validatePositiveInt(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Must be an integer';
    if (parsed < 0 || (!allowZero && parsed == 0)) {
      return allowZero ? 'Must be >= 0' : 'Must be > 0';
    }
    return null;
  }

  Future<void> _runInitGame(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    final cfg = GameSetupConfig(
      greatPowerCount: _greatPowerCount,
      continentCount: _continentCount,
      minorNationCount: _minorNationCount,
      tribeCount: _tribeCount,
      numProvincesOldWorld: _numProvincesOldWorld,
      numProvincesNewWorld: _numProvincesNewWorld,
      minProvincesPerMinor: _minProvincesPerMinor,
      seed: _seed,
    );

    // Basic runtime guard to surface config/topology mismatches early in dev.
    if (_minorNationCount > 0 &&
        _minProvincesPerMinor > 0 &&
        _numProvincesOldWorld <
            _greatPowerCount + _minorNationCount * _minProvincesPerMinor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Old World provinces must be >= GPs + minors * minProvincesPerMinor',
          ),
        ),
      );
      return;
    }

    final options = InitGameOptions(
      cellSize: 24,
      skipFillLakes: _skipFillLakes,
      renderPng: _renderPng,
    );

    setState(() {
      _isRunning = true;
    });

    try {
      // Yield to the event loop so the disabled button and spinner/overlay
      // can paint before heavy work starts.
      await Future<void>.delayed(Duration.zero);

      final result = runInitGame(
        config: cfg,
        options: options,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InitGameDebugMapScreen(
            initResult: result,
            baseSeed: _seed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game setup parameters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        initialValue: '$_greatPowerCount',
                        decoration: const InputDecoration(
                          labelText: 'Great Powers',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => _validatePositiveInt(v),
                        onSaved: (v) =>
                            _greatPowerCount = int.parse(v!.trim()),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        initialValue: '$_minorNationCount',
                        decoration: const InputDecoration(
                          labelText: 'Minor Nations',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _validatePositiveInt(v, allowZero: true),
                        onSaved: (v) =>
                            _minorNationCount = int.parse(v!.trim()),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        initialValue: '$_tribeCount',
                        decoration: const InputDecoration(
                          labelText: 'Tribes',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _validatePositiveInt(v, allowZero: true),
                        onSaved: (v) => _tribeCount = int.parse(v!.trim()),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextFormField(
                        initialValue: '$_numProvincesOldWorld',
                        decoration: const InputDecoration(
                          labelText: 'Old World provinces',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => _validatePositiveInt(v),
                        onSaved: (v) =>
                            _numProvincesOldWorld = int.parse(v!.trim()),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextFormField(
                        initialValue: '$_numProvincesNewWorld',
                        decoration: const InputDecoration(
                          labelText: 'New World provinces',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => _validatePositiveInt(v),
                        onSaved: (v) =>
                            _numProvincesNewWorld = int.parse(v!.trim()),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        initialValue: '$_continentCount',
                        decoration: const InputDecoration(
                          labelText: 'Continents',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => _validatePositiveInt(v),
                        onSaved: (v) =>
                            _continentCount = int.parse(v!.trim()),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextFormField(
                        initialValue: '$_minProvincesPerMinor',
                        decoration: const InputDecoration(
                          labelText: 'Min provinces per minor',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _validatePositiveInt(v, allowZero: true),
                        onSaved: (v) =>
                            _minProvincesPerMinor = int.parse(v!.trim()),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        // Start blank each time; user may optionally enter a seed.
                        initialValue: '',
                        decoration: const InputDecoration(
                          labelText: 'Seed',
                        ),
                        keyboardType: TextInputType.number,
                        // Seed is optional: blank or 0 means "use time-based seed".
                        validator: (v) {
                          final trimmed = v?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return null;
                          }
                          return _validatePositiveInt(trimmed, allowZero: true);
                        },
                        onSaved: (v) {
                          final trimmed = v?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            _seed = 0;
                          } else {
                            _seed = int.parse(trimmed);
                          }
                        },
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _skipFillLakes,
                  onChanged: (v) =>
                      setState(() => _skipFillLakes = v ?? false),
                ),
                const Flexible(
                  child: Text('Skip Fill Lakes (Pass 4)'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _renderPng,
                  onChanged: (v) =>
                      setState(() => _renderPng = v ?? false),
                ),
                const Flexible(
                  child: Text('Render PNG snapshot (slower)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _isRunning ? null : () => _runInitGame(context),
                child: _isRunning
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Running init_game...'),
                        ],
                      )
                    : const Text('Run init_game and view map'),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Init Game (ctdev config)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            content,
            if (_isRunning)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
  SimGameController? _simController;
  bool _isSimulatingBatch = false;

  CellViewData? _selectedCell;
  String? _selectedRegionId;

  final TransformationController _controller = TransformationController();
  bool _initialTransformApplied = false;

  bool _showOwnership = true;
  bool _showCapitals = true;
  bool _showPorts = true;
   // When true, render geographic (terrain/resources) view instead of political ownership fill.
  bool _geographicMode = false;

  @override
  void initState() {
    super.initState();
    _viewData = widget.initResult.mapViewData;
  }

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

  Future<void> _startSimGame() async {
    if (_simController != null) return;
    final result = widget.initResult;
    setState(() {
      _simController = SimGameController(
        initialGame: result.game,
        topology: result.combinedTopology,
        tileMapByRegion: result.tileMapByRegion,
        baseSeed: widget.baseSeed,
      );
    });
  }

  Future<void> _stepNextPlayer() async {
    final controller = _simController;
    if (controller == null || _isSimulatingBatch) return;
    setState(() {
      controller.generateOrdersForNextPlayer();
    });
  }

  Future<void> _resolvePendingTurn() async {
    final controller = _simController;
    if (controller == null || _isSimulatingBatch) return;
    if (!controller.allPlayersHaveOrders) return;
    setState(() {
      _isSimulatingBatch = true;
    });
    try {
      controller.resolveFromPendingOrders();
      _refreshViewDataFromController();
    } finally {
      if (mounted) {
        setState(() {
          _isSimulatingBatch = false;
        });
      }
    }
  }

  Future<void> _stepFullTurn() async {
    final controller = _simController;
    if (controller == null || _isSimulatingBatch) return;
    setState(() {
      _isSimulatingBatch = true;
    });
    try {
      controller.stepFullTurn();
      _refreshViewDataFromController();
    } finally {
      if (mounted) {
        setState(() {
          _isSimulatingBatch = false;
        });
      }
    }
  }

  Future<void> _fastForwardTen() async {
    final controller = _simController;
    if (controller == null || _isSimulatingBatch) return;
    setState(() {
      _isSimulatingBatch = true;
    });
    try {
      controller.fastForward(turns: 10);
      _refreshViewDataFromController();
    } finally {
      if (mounted) {
        setState(() {
          _isSimulatingBatch = false;
        });
      }
    }
  }

  void _refreshViewDataFromController() {
    final controller = _simController;
    if (controller == null) return;
    _viewData = buildInitGameMapViewData(
      game: controller.game,
      tileMapByRegion: controller.tileMapByRegion,
      topologyByRegion: controller.topologyByRegion,
      cellSize: _viewData.oldWorld.cellSize,
      seed: _viewData.seed,
      configSummary: _viewData.configSummary,
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
                      if (_simController == null)
                        ElevatedButton(
                          onPressed: _isSimulatingBatch ? null : _startSimGame,
                          child: const Text('Start Game (Sim)'),
                        )
                      else
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _isSimulatingBatch
                                  ? null
                                  : _stepNextPlayer,
                              child: const Text('Next Player'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isSimulatingBatch ||
                                      !(_simController?.allPlayersHaveOrders ??
                                          false)
                                  ? null
                                  : _resolvePendingTurn,
                              child: const Text('Resolve Turn'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  _isSimulatingBatch ? null : _stepFullTurn,
                              child: const Text('Next Turn'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  _isSimulatingBatch ? null : _fastForwardTen,
                              child: const Text('Fast-forward 10'),
                            ),
                          ],
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
                      if (_selectedCell == null)
                        const Text('Hover a tile to see details.')
                      else ...[
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
                      const Divider(),
                      const Text(
                        'Sim Game Log',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            (_simController?.logLines ?? const [])
                                .join('\n'),
                          ),
                        ),
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

/// In-memory controller for Sim Game mode used by ctdev.
class SimGameController {
  SimGameController({
    required Game initialGame,
    required MapTopology topology,
    required Map<String, TileMapResult> tileMapByRegion,
    required int baseSeed,
  })  : _game = initialGame,
        _topology = topology,
        _tileMapByRegion = tileMapByRegion,
        _baseSeed = baseSeed;

  Game _game;
  final MapTopology _topology;
  final Map<String, TileMapResult> _tileMapByRegion;
  final int _baseSeed;

  final Map<String, Orders> _pendingOrdersByPlayerId = {};
  final List<String> _logLines = [];

  Game get game => _game;
  Map<String, TileMapResult> get tileMapByRegion => _tileMapByRegion;
  Map<String, MapTopology> get topologyByRegion => {
        'oldWorld': MapTopology(
          nodes:
              _topology.nodes.where((n) => n.regionId == 'oldWorld').toList(),
          edges: _topology.edges,
        ),
        'newWorld': MapTopology(
          nodes:
              _topology.nodes.where((n) => n.regionId == 'newWorld').toList(),
          edges: _topology.edges,
        ),
      };

  List<String> get logLines => List.unmodifiable(_logLines);

  bool get allPlayersHaveOrders {
    final ids = _game.players.map((p) => p.id).toList();
    return ids.every(_pendingOrdersByPlayerId.containsKey);
  }

  /// Generates orders for the next Great Power that does not yet have orders
  /// for the current turn (player-by-player mode).
  void generateOrdersForNextPlayer() {
    final currentTurn = _game.worldState.turnState.turnNumber;
    for (final player in _game.players) {
      if (_pendingOrdersByPlayerId.containsKey(player.id)) continue;
      final orders = defaultSimGameAi(
        game: _game,
        player: player,
        topology: _topology,
        baseSeed: _baseSeed,
      );
      _pendingOrdersByPlayerId[player.id] = orders;
      _logLines.add(
        'Turn $currentTurn: generated orders for ${player.displayName} (${player.id})',
      );
      break;
    }
  }

  /// Resolves one full turn from the currently accumulated per-player orders.
  void resolveFromPendingOrders() {
    if (!allPlayersHaveOrders) return;
    final combined = _combineOrders(_pendingOrdersByPlayerId.values.toList());
    _pendingOrdersByPlayerId.clear();
    _advanceOneTurnFromOrders(combined);
  }

  /// Generates orders for all Great Powers and advances one full turn.
  void stepFullTurn() {
    final perPlayer = <String, Orders>{};
    for (final player in _game.players) {
      perPlayer[player.id] = defaultSimGameAi(
        game: _game,
        player: player,
        topology: _topology,
        baseSeed: _baseSeed,
      );
    }
    final combined = _combineOrders(perPlayer.values.toList());
    _pendingOrdersByPlayerId.clear();
    _advanceOneTurnFromOrders(combined);
  }

  /// Advances the game by [turns] full turns using the default AI.
  void fastForward({required int turns}) {
    for (var i = 0; i < turns; i++) {
      stepFullTurn();
    }
  }

  Orders _combineOrders(List<Orders> all) {
    final moveByPlayer = <String, List<MoveOrder>>{};
    final buildByPlayer = <String, List<BuildUnitOrder>>{};
    final workByPlayer = <String, List<WorkOrder>>{};

    for (final o in all) {
      o.moveOrdersByPlayerId.forEach((pid, list) {
        moveByPlayer.putIfAbsent(pid, () => <MoveOrder>[]).addAll(list);
      });
      o.buildUnitOrdersByPlayerId.forEach((pid, list) {
        buildByPlayer.putIfAbsent(pid, () => <BuildUnitOrder>[]).addAll(list);
      });
      o.workOrdersByPlayerId.forEach((pid, list) {
        workByPlayer.putIfAbsent(pid, () => <WorkOrder>[]).addAll(list);
      });
    }

    return Orders(
      moveOrdersByPlayerId: moveByPlayer,
      buildUnitOrdersByPlayerId: buildByPlayer,
      workOrdersByPlayerId: workByPlayer,
    );
  }

  void _advanceOneTurnFromOrders(Orders orders) {
    final before = _game;
    final next = resolveTurnForGame(
      game: _game,
      topology: _topology,
      orders: orders,
      tileMapByRegion: _tileMapByRegion,
      defaultAssignments: const [],
    );
    _game = next;
    _recordTurnLog(before: before, after: next);
  }

  void _recordTurnLog({required Game before, required Game after}) {
    final turn = after.worldState.turnState.turnNumber;
    final year = turnToYear(turn, after.turnTimeMapping);

    final beforeOwners = <String, String?>{};
    for (final p in before.worldState.oldWorld.provinces) {
      beforeOwners[p.id] = p.ownerId;
    }
    for (final p in before.worldState.newWorld.provinces) {
      beforeOwners[p.id] = p.ownerId;
    }

    final flips = <String>[];
    for (final p in after.worldState.oldWorld.provinces) {
      final prev = beforeOwners[p.id];
      if (prev != p.ownerId) {
        flips.add('${p.id}: ${prev ?? '—'} → ${p.ownerId ?? '—'}');
      }
    }
    for (final p in after.worldState.newWorld.provinces) {
      final prev = beforeOwners[p.id];
      if (prev != p.ownerId) {
        flips.add('${p.id}: ${prev ?? '—'} → ${p.ownerId ?? '—'}');
      }
    }

    if (flips.isEmpty) {
      _logLines.add('Turn $turn ($year): no province ownership changes');
    } else {
      _logLines.add(
        'Turn $turn ($year): province ownership changes: ${flips.join(', ')}',
      );
    }
  }
}

