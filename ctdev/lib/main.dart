import 'dart:async';
import 'dart:math' as math;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'ctdev_log.dart';
import 'debug_map_painter.dart';
import 'player_view_map_painter.dart';

/// Converts [Game.greatPowerColorOverride] (list form) to tuple form for [buildInitGameMapViewData].
/// Use when building map view from a loaded game (Load Savegame flow).
Map<String, (int r, int g, int b)>? greatPowerColorOverrideFromGame(Game game) {
  final raw = game.greatPowerColorOverride;
  if (raw == null || raw.isEmpty) return null;
  return raw.map(
    (k, v) => MapEntry(k, (v[0], v[1], v[2])),
  );
}

/// Short display form for a tile key (regionId|provinceId|x|y).
String _formatTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length >= 4) return '${parts[2]},${parts[3]}';
  return tileKey;
}

void main() {
  initCtdevLogging();
  runZonedGuarded(
    () => runApp(const CtDevApp()),
    (Object error, StackTrace stackTrace) {
      Logger().e('ctdev: uncaught error', error: error, stackTrace: stackTrace);
    },
  );
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

  late Set<String> _selectedGreatPowerIds;
  late int _minorNationCount;
  late int _tribeCount;
  late int _numProvincesOldWorld;
  late int _numProvincesNewWorld;
  late int _continentCount;
  late int _minProvincesPerMinor;
  late int _seed;
  late String _prussiaLeaderVariantId;
  late Map<String, (int r, int g, int b)> _greatPowerColorByGpId;
  bool _skipFillLakes = false;
  bool _renderPng = false;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    final cfg = GameSetupConfig.defaultConfig;
    _selectedGreatPowerIds = cfg.selectedGreatPowerIds.toSet();
    _minorNationCount = cfg.minorNationCount;
    _tribeCount = cfg.tribeCount;
    _numProvincesOldWorld = cfg.numProvincesOldWorld;
    _numProvincesNewWorld = cfg.numProvincesNewWorld;
    _continentCount = cfg.continentCount;
    _minProvincesPerMinor = cfg.minProvincesPerMinor;
    _prussiaLeaderVariantId =
        cfg.leaderVariantByGpId['prussia'] ?? prussiaVariantFrederickTheGreat;
    _greatPowerColorByGpId = {
      for (final id in allGreatPowerIds) id: greatPowerDefaultColorRgb[id]!,
    };
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

    if (_selectedGreatPowerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one Great Power'),
        ),
      );
      return;
    }

    final selectedIds = _selectedGreatPowerIds.toList()..sort();
    final cfg = GameSetupConfig(
      selectedGreatPowerIds: selectedIds,
      leaderVariantByGpId: _selectedGreatPowerIds.contains('prussia')
          ? {'prussia': _prussiaLeaderVariantId}
          : {},
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
            _selectedGreatPowerIds.length +
                _minorNationCount * _minProvincesPerMinor) {
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
      greatPowerColorOverride: {
        for (final id in _selectedGreatPowerIds) id: _greatPowerColorByGpId[id]!,
      },
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
            const Text(
              'Great Powers',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final id in allGreatPowerIds)
                  FilterChip(
                    label: Text(
                      defaultNamingConfig.gpById(id)?.countryName ?? id,
                    ),
                    selected: _selectedGreatPowerIds.contains(id),
                    onSelected: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedGreatPowerIds = {..._selectedGreatPowerIds, id};
                        } else {
                          _selectedGreatPowerIds =
                              Set.from(_selectedGreatPowerIds)..remove(id);
                        }
                      });
                    },
                  ),
              ],
            ),
            if (_selectedGreatPowerIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Select at least one Great Power',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (_selectedGreatPowerIds.contains('prussia')) ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: prussiaVariantFrederickTheGreat,
                    label: Text('Frederick the Great'),
                  ),
                  ButtonSegment<String>(
                    value: prussiaVariantFrederickWilliam,
                    label: Text('Frederick William'),
                  ),
                ],
                selected: {_prussiaLeaderVariantId},
                onSelectionChanged: (Set<String> selected) {
                  setState(() {
                    _prussiaLeaderVariantId = selected.single;
                  });
                },
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Map colour (per Great Power)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ...(_selectedGreatPowerIds.toList()..sort()).map((gpId) {
              final currentRgb = _greatPowerColorByGpId[gpId]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        defaultNamingConfig.gpById(gpId)?.countryName ?? gpId,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<(int r, int g, int b)>(
                      value: currentRgb,
                      isExpanded: false,
                      items: greatPowerColorOptions.map((opt) {
                        final rgb = opt.$3;
                        return DropdownMenuItem<(int r, int g, int b)>(
                          value: rgb,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3),
                                  border: Border.all(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(opt.$2, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newRgb) {
                        if (newRgb == null || newRgb == currentRgb) return;
                        setState(() {
                          final others = _greatPowerColorByGpId.entries
                              .where((e) =>
                                  e.key != gpId &&
                                  _selectedGreatPowerIds.contains(e.key) &&
                                  e.value.$1 == newRgb.$1 &&
                                  e.value.$2 == newRgb.$2 &&
                                  e.value.$3 == newRgb.$3)
                              .map((e) => e.key)
                              .toList();
                          final other = others.isNotEmpty ? others.first : null;
                          if (other != null) {
                            _greatPowerColorByGpId[other] = currentRgb;
                          }
                          _greatPowerColorByGpId[gpId] = newRgb;
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
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

/// Running Game Screen: sim game with control bar and tabs.
class RunningGameScreen extends StatefulWidget {
  const RunningGameScreen({
    super.key,
    required this.sessionId,
    required this.initResult,
    required this.baseSeed,
    this.useSimGameAi = true,
    this.useFullAI = false,
  });

  final String sessionId;
  final InitGameResult initResult;
  final int baseSeed;
  final bool useSimGameAi;
  final bool useFullAI;

  @override
  State<RunningGameScreen> createState() => _RunningGameScreenState();
}

class _RunningGameScreenState extends State<RunningGameScreen>
    with SingleTickerProviderStateMixin {
  late SimGameController _controller;
  late TabController _tabController;
  bool _isSimulatingBatch = false;
  late InitGameMapViewData _viewData;

  bool _showOwnership = true;
  bool _showCapitals = true;
  bool _showPorts = true;
  bool _geographicMode = false;
  bool _showImprovements = false;
  bool _showUnits = false;

  @override
  void initState() {
    super.initState();
    _controller = SimGameController(
      initialGame: widget.initResult.game,
      topology: widget.initResult.combinedTopology,
      tileMapByRegion: widget.initResult.tileMapByRegion,
      baseSeed: widget.baseSeed,
      useSimGameAi: widget.useSimGameAi,
      useFullAI: widget.useFullAI,
    );
    _viewData = buildInitGameMapViewData(
      game: _controller.game,
      tileMapByRegion: _controller.tileMapByRegion,
      topologyByRegion: _controller.topologyByRegion,
      cellSize: 24,
      seed: widget.baseSeed,
      configSummary: widget.initResult.mapViewData.configSummary,
      greatPowerColorOverride: widget.initResult.greatPowerColorOverride,
    );
    final tabCount = 3 + _controller.game.players.length;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  InitGameMapViewData get _currentViewData => buildInitGameMapViewData(
        game: _controller.game,
        tileMapByRegion: _controller.tileMapByRegion,
        topologyByRegion: _controller.topologyByRegion,
        cellSize: _viewData.oldWorld.cellSize,
        seed: _viewData.seed,
        configSummary: _viewData.configSummary,
        greatPowerColorOverride: widget.initResult.greatPowerColorOverride,
      );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _viewData = _currentViewData;
    });
  }

  Future<void> _stepNextPlayer() async {
    if (_isSimulatingBatch) return;
    setState(() => _controller.generateOrdersForNextPlayer());
  }

  Future<void> _resolvePendingTurn() async {
    if (_isSimulatingBatch || !_controller.allPlayersHaveOrders) return;
    setState(() => _isSimulatingBatch = true);
    try {
      _controller.resolveFromPendingOrders();
      _refresh();
    } catch (e, st) {
      Logger().e('ctdev: resolve turn failed', error: e, stackTrace: st);
      rethrow;
    } finally {
      if (mounted) setState(() => _isSimulatingBatch = false);
    }
  }

  Future<void> _stepFullTurn() async {
    if (_isSimulatingBatch) return;
    setState(() => _isSimulatingBatch = true);
    try {
      _controller.stepFullTurn();
      _refresh();
    } catch (e, st) {
      Logger().e('ctdev: step full turn failed', error: e, stackTrace: st);
      rethrow;
    } finally {
      if (mounted) setState(() => _isSimulatingBatch = false);
    }
  }

  Future<void> _fastForwardTen() async {
    if (_isSimulatingBatch) return;
    setState(() => _isSimulatingBatch = true);
    try {
      _controller.fastForward(turns: 10);
      _refresh();
    } catch (e, st) {
      Logger().e('ctdev: fast-forward failed', error: e, stackTrace: st);
      rethrow;
    } finally {
      if (mounted) setState(() => _isSimulatingBatch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      const Tab(text: 'Map'),
      const Tab(text: 'Overview'),
      const Tab(text: 'Orders'),
      ..._controller.game.players.map((p) => Tab(text: p.displayName)),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Game'),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
          isScrollable: true,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text('Session: ${widget.sessionId}', style: Theme.of(context).textTheme.bodySmall),
                Text('Log: ${sessionLogPath ?? "—"}', style: Theme.of(context).textTheme.bodySmall),
                ElevatedButton(
                  onPressed: _isSimulatingBatch ? null : _stepNextPlayer,
                  child: const Text('Next Player'),
                ),
                ElevatedButton(
                  onPressed: _isSimulatingBatch ||
                          !_controller.allPlayersHaveOrders
                      ? null
                      : _resolvePendingTurn,
                  child: const Text('Resolve Turn'),
                ),
                ElevatedButton(
                  onPressed: _isSimulatingBatch ? null : _stepFullTurn,
                  child: const Text('Next Turn'),
                ),
                ElevatedButton(
                  onPressed: _isSimulatingBatch ? null : _fastForwardTen,
                  child: const Text('Fast-forward 10'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildGameOverviewTab(),
                _buildOrdersTab(),
                ..._controller.game.players.map(_buildPlayerTab),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    final ow = _viewData.oldWorld;
    final nw = _viewData.newWorld;
    final viewCellSize = ow.cellSize.toDouble() * kDebugMapScale;
    final gap = viewCellSize * 2;
    final totalWidth =
        ow.width * viewCellSize + gap + nw.width * viewCellSize;
    final totalHeight = math.max(
      ow.height * viewCellSize,
      nw.height * viewCellSize,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            children: [
              _SwitchRow('Geographic', _geographicMode, (v) => setState(() => _geographicMode = v)),
              _CheckRow('Ownership', _showOwnership, _geographicMode ? null : (v) => setState(() => _showOwnership = v ?? true)),
              _CheckRow('Capitals', _showCapitals, (v) => setState(() => _showCapitals = v ?? true)),
              _CheckRow('Ports', _showPorts, (v) => setState(() => _showPorts = v ?? true)),
              _CheckRow('Improvements', _showImprovements, (v) => setState(() => _showImprovements = v ?? true)),
              _CheckRow('Units', _showUnits, (v) => setState(() => _showUnits = v ?? true)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: InteractiveViewer(
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
                  showImprovements: _showImprovements,
                  showUnits: _showUnits,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverviewTab() {
    final game = _controller.game;
    final turn = game.worldState.turnState.turnNumber;
    final year = turnToYear(turn, game.turnTimeMapping);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Turn $turn ($year)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          const Text('Turn seed (monitored)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...game.players.map((p) {
            final seed = turnSeedForPlayer(
              game,
              p.id,
              turn,
              fallbackAiSeed: _controller.baseSeed,
            );
            return Text('${p.displayName} (${p.id}): $seed');
          }),
          const SizedBox(height: 16),
          const Text('Provinces', style: TextStyle(fontWeight: FontWeight.bold)),
          ...game.players.map((p) {
            final ow = game.worldState.oldWorld.provinces.where((pr) => pr.ownerId == p.id);
            final nw = game.worldState.newWorld.provinces.where((pr) => pr.ownerId == p.id);
            final names = [
              ...ow.map((pr) => pr.displayName ?? pr.id),
              ...nw.map((pr) => pr.displayName ?? pr.id),
            ];
            return Text('${p.displayName}: ${names.join(', ')}');
          }),
          const SizedBox(height: 16),
          const Text('Military strength', style: TextStyle(fontWeight: FontWeight.bold)),
          ...game.players.map((p) {
            final str = aggregateMilitaryStrengthForPlayer(game, p.id);
            return Text('${p.displayName}: ${str.toStringAsFixed(1)}');
          }),
          const SizedBox(height: 16),
          const Text('Sim Log', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(getLastUiLogLines().join('\n')),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    final history = _controller.orderHistory;
    final game = _controller.game;
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No orders recorded yet. Run at least one turn to see AI orders.'),
        ),
      );
    }

    final byTurn = <int, List<_SimOrderHistoryEntry>>{};
    for (final entry in history) {
      byTurn.putIfAbsent(entry.turnNumber, () => <_SimOrderHistoryEntry>[]).add(entry);
    }
    final sortedTurns = byTurn.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final turn in sortedTurns) ...[
            Builder(
              builder: (context) {
                final year = turnToYear(turn, game.turnTimeMapping);
                return Text(
                  'Turn $turn ($year)',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
            const SizedBox(height: 4),
            Builder(
              builder: (context) {
                final entriesForTurn = List<_SimOrderHistoryEntry>.from(
                  byTurn[turn] ?? const <_SimOrderHistoryEntry>[],
                )..sort((a, b) {
                    final playerCompare = a.playerId.compareTo(b.playerId);
                    if (playerCompare != 0) return playerCompare;
                    return a.orderType.compareTo(b.orderType);
                  });
                final byPlayer = <String, List<_SimOrderHistoryEntry>>{};
                for (final e in entriesForTurn) {
                  byPlayer.putIfAbsent(e.playerId, () => <_SimOrderHistoryEntry>[]).add(e);
                }
                final playerIds = byPlayer.keys.toList()..sort();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final pid in playerIds) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${byPlayer[pid]!.first.playerName} ($pid)',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      for (final entry in byPlayer[pid]!) Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 2),
                        child: Builder(
                          builder: (context) {
                            final isAccepted =
                                entry.status == OrderValidationStatus.accepted;
                            final statusLabel =
                                isAccepted ? 'ACCEPTED' : 'REJECTED';
                            final statusColor = isAccepted
                                ? Colors.green
                                : Colors.red;
                            final reasonText = entry.reason == null
                                ? ''
                                : ' — ${entry.reason}';
                            return RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: '[$statusLabel] ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${entry.orderType}: ${entry.summary}$reasonText',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerTab(Player player) {
    final orders = _controller.pendingOrdersByPlayerId[player.id];
    final game = _controller.game;
    final topology = _controller.topology;
    final units = [
      ...game.worldState.oldWorld.units.where((u) => u.ownerId == player.id),
      ...game.worldState.newWorld.units.where((u) => u.ownerId == player.id),
    ];

    final currentOrders = orders ?? const Orders();
    final view = buildPlayerView(game, topology, player.id);
    const suggestionApi = DefaultOrderSuggestionAPI();
    final suggestedMoves = suggestionApi.suggestMoveOrders(view, game, topology, currentOrders);
    final suggestedBuilds = suggestionApi.suggestBuildOrders(view, game, topology, currentOrders);
    final suggestedWorks = suggestionApi.suggestWorkOrders(view, game, topology, currentOrders);
    final suggestedResearch = suggestionApi.suggestResearchOrders(view, game, topology, currentOrders);

    // Key by regionId|id so OW and NW can share province ids (e.g. p1).
    final provinceNamesByRegionAndId = <String, String>{};
    for (final p in game.worldState.oldWorld.provinces) {
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
    }
    for (final p in game.worldState.newWorld.provinces) {
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
    }
    String provinceLabelInRegion(String regionId, String id) =>
        provinceNamesByRegionAndId['$regionId|$id'] ?? id;

    final unitsById = <String, Unit>{};
    for (final u in game.worldState.oldWorld.units) {
      unitsById[u.id] = u;
    }
    for (final u in game.worldState.newWorld.units) {
      unitsById[u.id] = u;
    }

    final ow = _viewData.oldWorld;
    final nw = _viewData.newWorld;
    final viewCellSize = ow.cellSize.toDouble() * kDebugMapScale;
    final gap = viewCellSize * 2;
    final totalMapWidth = ow.width * viewCellSize + gap + nw.width * viewCellSize;
    final totalMapHeight = math.max(
      ow.height * viewCellSize,
      nw.height * viewCellSize,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${player.displayName} (${player.id})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Per-player map', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SizedBox(
            width: totalMapWidth,
            height: totalMapHeight,
            child: CustomPaint(
              painter: PlayerViewMapPainter(
                viewData: _viewData,
                playerView: view,
                showOwnership: _showOwnership,
                showCapitals: _showCapitals,
                showPorts: _showPorts,
                geographicMode: _geographicMode,
                showImprovements: _showImprovements,
                showUnits: _showUnits,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Stockpile', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(player.stockpile.quantities.isEmpty
              ? '—'
              : player.stockpile.quantities.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join(', ')),
          const SizedBox(height: 12),
          const Text('Workers', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${player.workerPool.totalWorkers}'),
          const SizedBox(height: 12),
          const Text('Treasury', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${player.treasury}'),
          const SizedBox(height: 12),
          const Text('Tech unlocked', style: TextStyle(fontWeight: FontWeight.bold)),
          Text((player.techUnlocked?.entries.where((e) => e.value).map((e) => e.key).join(', ')) ?? '—'),
          const SizedBox(height: 12),
          const Text('Pending orders', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(orders != null ? '${orders.moveOrdersByPlayerId[player.id]?.length ?? 0} move, ${orders.buildUnitOrdersByPlayerId[player.id]?.length ?? 0} build' : '—'),
          const SizedBox(height: 12),
          const Text('Available orders (suggestion API)', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildAvailableOrdersSection(
            suggestedMoves: suggestedMoves,
            suggestedBuilds: suggestedBuilds,
            suggestedWorks: suggestedWorks,
            suggestedResearch: suggestedResearch,
            unitsById: unitsById,
            provinceLabelInRegion: provinceLabelInRegion,
          ),
          const SizedBox(height: 12),
          const Text('Units', style: TextStyle(fontWeight: FontWeight.bold)),
          if (units.isEmpty)
            const Text('—')
          else
            ...units.map((unit) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.type,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Province: ${provinceLabelInRegion(Unit.regionIdFromTileKey(unit.tileKey) ?? "oldWorld", unit.locationProvinceId)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _civilianUnitCapabilities[unit.type] ?? unit.type,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersSection({
    required List<MoveOrder> suggestedMoves,
    required List<BuildUnitOrder> suggestedBuilds,
    required List<WorkOrder> suggestedWorks,
    required List<ResearchOrder> suggestedResearch,
    required Map<String, Unit> unitsById,
    required String Function(String regionId, String id) provinceLabelInRegion,
  }) {
    final hasAny = suggestedMoves.isNotEmpty ||
        suggestedBuilds.isNotEmpty ||
        suggestedWorks.isNotEmpty ||
        suggestedResearch.isNotEmpty;
    if (!hasAny) {
      return const Text('—');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (suggestedMoves.isNotEmpty) ...[
          const Text('Move', style: TextStyle(fontWeight: FontWeight.w600)),
          ...suggestedMoves.map((o) {
            final unit = unitsById[o.unitId];
            final unitLabel = unit != null ? '${unit.id} (${unit.type})' : o.unitId;
            final regionId = unit != null
                ? (Unit.regionIdFromTileKey(unit.tileKey) ?? 'oldWorld')
                : 'oldWorld';
            final origin = unit != null
                ? provinceLabelInRegion(regionId, unit.locationProvinceId)
                : '?';
            final dest = provinceLabelInRegion(regionId, o.destinationProvinceId);
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('$unitLabel: $origin → $dest', style: Theme.of(context).textTheme.bodySmall),
            );
          }),
          const SizedBox(height: 6),
        ],
        if (suggestedBuilds.isNotEmpty) ...[
          const Text('Build', style: TextStyle(fontWeight: FontWeight.w600)),
          ...suggestedBuilds.map((o) {
            final location = provinceLabelInRegion('oldWorld', o.spawnProvinceId);
            final kind = o.isMilitary ? 'military' : 'civilian';
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('${o.unitType} ($kind) at $location', style: Theme.of(context).textTheme.bodySmall),
            );
          }),
          const SizedBox(height: 6),
        ],
        if (suggestedWorks.isNotEmpty) ...[
          const Text('Work', style: TextStyle(fontWeight: FontWeight.w600)),
          ...suggestedWorks.map((o) {
            final unit = unitsById[o.unitId];
            final unitLabel = unit != null ? '${unit.id} (${unit.type})' : o.unitId;
            final unitRegion = unit != null
                ? (Unit.regionIdFromTileKey(unit.tileKey) ?? 'oldWorld')
                : 'oldWorld';
            final targetRegion = Unit.regionIdFromTileKey(o.targetTileKey) ?? unitRegion;
            final currentProvince = unit != null
                ? provinceLabelInRegion(unitRegion, unit.locationProvinceId)
                : '?';
            final targetProvince = provinceLabelInRegion(
                targetRegion, Unit.provinceIdFromTileKey(o.targetTileKey) ?? '');
            final currentTile = (unit != null && unit.tileKey != null && unit.tileKey!.isNotEmpty)
                ? _formatTileKey(unit.tileKey!)
                : '?';
            final targetTile = o.targetTileKey.isNotEmpty ? _formatTileKey(o.targetTileKey) : '?';
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '$unitLabel at $currentTile ($currentProvince) → ${o.target} at $targetTile ($targetProvince)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
        if (suggestedResearch.isNotEmpty) ...[
          const Text('Research', style: TextStyle(fontWeight: FontWeight.w600)),
          ...suggestedResearch.map((o) {
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('slot ${o.slotIndex} → ${o.techId} (${o.funding})', style: Theme.of(context).textTheme.bodySmall),
            );
          }),
        ],
      ],
    );
  }

  static const _civilianUnitCapabilities = {
    'Explorer': 'Prospect, explore',
    'Builder': 'Develop tile',
    'Engineer': 'Build road, port, fort',
  };
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: value, onChanged: onChanged),
          Text(label),
        ],
      );
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final void Function(bool?)? onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Text(label),
        ],
      );
}

class _SimOrderHistoryEntry {
  const _SimOrderHistoryEntry({
    required this.turnNumber,
    required this.playerId,
    required this.playerName,
    required this.orderType,
    required this.summary,
    required this.status,
    this.reason,
  });

  final int turnNumber;
  final String playerId;
  final String playerName;
  final String orderType;
  final String summary;
  final OrderValidationStatus status;
  final String? reason;
}

/// Ensures every Great Power has an aiSeed so turnSeed[P, T] is well-defined (Option A).
Game _ensureAiSeedsForSim(Game game, int baseSeed) {
  final byGp = Map<String, int>.from(game.aiSeedByGpId);
  for (final p in game.players) {
    byGp.putIfAbsent(p.id, () => baseSeed);
  }
  return game.copyWith(aiSeedByGpId: byGp);
}

/// In sim game all GPs are AI-controlled; no human player.
Game _forceAllGpsAiControlled(Game game) {
  return game.copyWith(
    aiControlByGpId: {for (final p in game.players) p.id: true},
  );
}

/// In-memory controller for Sim Game mode used by ctdev.
class SimGameController {
  SimGameController({
    required Game initialGame,
    required MapTopology topology,
    required Map<String, TileMapResult> tileMapByRegion,
    required int baseSeed,
    this.useSimGameAi = true,
    this.useFullAI = false,
  })  : _game = _forceAllGpsAiControlled(
            _ensureAiSeedsForSim(initialGame, baseSeed)),
        _topology = topology,
        _tileMapByRegion = tileMapByRegion,
        _baseSeed = baseSeed {
    if (!useSimGameAi && useFullAI) {
      _game = assignHiddenAgendasForGame(_game);
    }
  }

  Game _game;
  final MapTopology _topology;
  final Map<String, TileMapResult> _tileMapByRegion;
  final int _baseSeed;

  /// When true, use Sim Game AI (defaultSimGameAi) for all GPs. When false, use AI Planner (minimal or full).
  final bool useSimGameAi;

  /// When true and useSimGameAi is false, use Phase 6 full AI (personalities, hidden agendas, naval orders). When false, use Phase 4 simple AI.
  final bool useFullAI;

  /// Base seed used for sim; also fallback for turnSeed when a GP has no aiSeed.
  int get baseSeed => _baseSeed;

  final Map<String, Orders> _pendingOrdersByPlayerId = {};
  final List<_SimOrderHistoryEntry> _orderHistory = [];

  Game get game => _game;
  Map<String, Orders> get pendingOrdersByPlayerId =>
      Map.unmodifiable(_pendingOrdersByPlayerId);
  MapTopology get topology => _topology;
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

  List<_SimOrderHistoryEntry> get orderHistory =>
      List.unmodifiable(_orderHistory);

  bool get allPlayersHaveOrders {
    final ids = _game.players.map((p) => p.id).toList();
    return ids.every(_pendingOrdersByPlayerId.containsKey);
  }

  /// Generates orders for the next Great Power that does not yet have orders
  /// for the current turn (player-by-player mode). All GPs use the selected AI.
  void generateOrdersForNextPlayer() {
    final currentTurn = _game.worldState.turnState.turnNumber;
    for (final player in _game.players) {
      if (_pendingOrdersByPlayerId.containsKey(player.id)) continue;
      final orders = useSimGameAi
          ? defaultSimGameAi(
              game: _game,
              player: player,
              topology: _topology,
              baseSeed: _baseSeed,
            )
          : (useFullAI
              ? generateOrdersForPlayerFullAI(_game, _topology, player.id)
              : generateOrdersForPlayer(_game, _topology, player.id));
      _pendingOrdersByPlayerId[player.id] = orders;
      Logger().i(
        'ctdev: Turn $currentTurn: generated orders for ${player.displayName} (${player.id})',
      );
      break;
    }
  }

  /// Resolves one full turn from the currently accumulated per-player orders.
  void resolveFromPendingOrders() {
    if (!allPlayersHaveOrders) return;
    clearUiLog();
    final combined = _combineOrders(_pendingOrdersByPlayerId.values.toList());
    _pendingOrdersByPlayerId.clear();
    _advanceOneTurnFromOrders(combined);
  }

  /// Generates orders for all Great Powers and advances one full turn.
  /// All GPs use the selected AI (Sim Game AI or AI Planner).
  void stepFullTurn() {
    clearUiLog();
    final List<Orders> ordersList;
    if (useSimGameAi) {
      ordersList = [
        for (final player in _game.players)
          defaultSimGameAi(
            game: _game,
            player: player,
            topology: _topology,
            baseSeed: _baseSeed,
          ),
      ];
    } else {
      ordersList = [
        useFullAI
            ? generateOrdersForGameFullAI(_game, _topology)
            : generateOrdersForGame(_game, _topology),
      ];
    }
    final combined = _combineOrders(ordersList);
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
    final diploByPlayer = <String, List<DiplomaticOrder>>{};
    final researchByPlayer = <String, List<ResearchOrder>>{};
    final navalByPlayer = <String, List<NavalMoveOrder>>{};
    final missionByPlayer = <String, List<NavalMissionOrder>>{};

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
      o.diplomaticOrdersByPlayerId.forEach((pid, list) {
        diploByPlayer.putIfAbsent(pid, () => <DiplomaticOrder>[]).addAll(list);
      });
      o.researchOrdersByPlayerId.forEach((pid, list) {
        researchByPlayer.putIfAbsent(pid, () => <ResearchOrder>[]).addAll(list);
      });
      o.navalMoveOrdersByPlayerId.forEach((pid, list) {
        navalByPlayer.putIfAbsent(pid, () => <NavalMoveOrder>[]).addAll(list);
      });
      o.navalMissionOrdersByPlayerId.forEach((pid, list) {
        missionByPlayer.putIfAbsent(pid, () => <NavalMissionOrder>[]).addAll(list);
      });
    }

    return Orders(
      moveOrdersByPlayerId: moveByPlayer,
      buildUnitOrdersByPlayerId: buildByPlayer,
      workOrdersByPlayerId: workByPlayer,
      diplomaticOrdersByPlayerId: diploByPlayer,
      researchOrdersByPlayerId: researchByPlayer,
      navalMoveOrdersByPlayerId: navalByPlayer,
      navalMissionOrdersByPlayerId: missionByPlayer,
    );
  }

  void _advanceOneTurnFromOrders(Orders orders) {
    _recordOrderHistory(orders);
    final before = _game;
    final next = validateOrdersAndResolveTurn(
      game: _game,
      topology: _topology,
      orders: orders,
      tileMapByRegion: _tileMapByRegion,
      defaultAssignments: const [],
    );
    _game = next;
    _recordTurnLog(before: before, after: next);
  }

  void _recordOrderHistory(Orders orders) {
    if (orders.moveOrdersByPlayerId.isEmpty &&
        orders.buildUnitOrdersByPlayerId.isEmpty &&
        orders.workOrdersByPlayerId.isEmpty &&
        orders.diplomaticOrdersByPlayerId.isEmpty &&
        orders.researchOrdersByPlayerId.isEmpty &&
        orders.navalMoveOrdersByPlayerId.isEmpty &&
        orders.navalMissionOrdersByPlayerId.isEmpty) {
      return;
    }

    final currentTurn = _game.worldState.turnState.turnNumber;

    final unitsById = <String, Unit>{};
    for (final u in _game.worldState.oldWorld.units) {
      unitsById[u.id] = u;
    }
    for (final u in _game.worldState.newWorld.units) {
      unitsById[u.id] = u;
    }

    final provinceNamesByRegionAndId = <String, String>{};
    for (final p in _game.worldState.oldWorld.provinces) {
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
    }
    for (final p in _game.worldState.newWorld.provinces) {
      provinceNamesByRegionAndId['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
    }
    String provinceLabelInRegion(String regionId, String id) =>
        provinceNamesByRegionAndId['$regionId|$id'] ?? id;

    for (final player in _game.players) {
      final playerId = player.id;
      final moves = orders.moveOrdersByPlayerId[playerId] ?? const [];
      final builds = orders.buildUnitOrdersByPlayerId[playerId] ?? const [];
      final works = orders.workOrdersByPlayerId[playerId] ?? const [];
      final diplo =
          orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];
      final research =
          orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[];
      final naval =
          orders.navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[];
      final mission =
          orders.navalMissionOrdersByPlayerId[playerId] ?? const <NavalMissionOrder>[];

      if (moves.isEmpty &&
          builds.isEmpty &&
          works.isEmpty &&
          diplo.isEmpty &&
          research.isEmpty &&
          naval.isEmpty &&
          mission.isEmpty) {
        continue;
      }

      final engine = OrderEngine(
        initialOrders: Orders(
          moveOrdersByPlayerId:
              moves.isEmpty ? const {} : {playerId: List.of(moves)},
          buildUnitOrdersByPlayerId:
              builds.isEmpty ? const {} : {playerId: List.of(builds)},
          workOrdersByPlayerId:
              works.isEmpty ? const {} : {playerId: List.of(works)},
          diplomaticOrdersByPlayerId:
              diplo.isEmpty ? const {} : {playerId: List.of(diplo)},
          researchOrdersByPlayerId:
              research.isEmpty ? const {} : {playerId: List.of(research)},
          navalMoveOrdersByPlayerId:
              naval.isEmpty ? const {} : {playerId: List.of(naval)},
          navalMissionOrdersByPlayerId:
              mission.isEmpty ? const {} : {playerId: List.of(mission)},
        ),
      );

      final results =
          engine.validatePlayerOrdersWithContext(_game, _topology, playerId);
      var resultIndex = 0;

      OrderValidationResult nextResult() {
        if (resultIndex >= results.length) {
          return const OrderValidationResult(
            status: OrderValidationStatus.accepted,
          );
        }
        final r = results[resultIndex];
        resultIndex++;
        return r;
      }

      for (final o in moves) {
        final unit = unitsById[o.unitId];
        final unitLabel = unit != null
            ? '${unit.id} (${unit.type})'
            : o.unitId;
        final regionId = unit != null
            ? (Unit.regionIdFromTileKey(unit.tileKey) ?? 'oldWorld')
            : 'oldWorld';
        final origin = unit != null
            ? provinceLabelInRegion(regionId, unit.locationProvinceId)
            : '?';
        final dest = provinceLabelInRegion(regionId, o.destinationProvinceId);
        final validation = nextResult();
        _orderHistory.add(
          _SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'move',
            summary: 'Move $unitLabel: $origin → $dest',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }

      for (final o in builds) {
        final location = provinceLabelInRegion('oldWorld', o.spawnProvinceId);
        final kind = o.isMilitary ? 'military' : 'civilian';
        final validation = nextResult();
        _orderHistory.add(
          _SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'build',
            summary: 'Build ${o.unitType} ($kind) at $location',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }

      for (final o in works) {
        final unit = unitsById[o.unitId];
        final unitLabel = unit != null
            ? '${unit.id} (${unit.type})'
            : o.unitId;
        final unitRegion = unit != null
            ? (Unit.regionIdFromTileKey(unit.tileKey) ?? 'oldWorld')
            : 'oldWorld';
        final targetRegion = Unit.regionIdFromTileKey(o.targetTileKey) ?? unitRegion;
        final currentProvince = unit != null
            ? provinceLabelInRegion(unitRegion, unit.locationProvinceId)
            : '?';
        final targetProvince = provinceLabelInRegion(
            targetRegion, Unit.provinceIdFromTileKey(o.targetTileKey) ?? '');
        final currentTile = (unit != null && unit.tileKey != null && unit.tileKey!.isNotEmpty)
            ? _formatTileKey(unit.tileKey!)
            : '?';
        final targetTile = o.targetTileKey.isNotEmpty ? _formatTileKey(o.targetTileKey) : '?';
        final validation = nextResult();
        _orderHistory.add(
          _SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'work',
            summary: 'Work $unitLabel at $currentTile ($currentProvince) → ${o.target} at $targetTile ($targetProvince)',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }

      for (final o in diplo) {
        final typeLabel = o.type.name;
        final target = o.targetFactionId;
        final extra = o.amount != null ? ' amount=${o.amount}' : '';
        final validation = nextResult();
        _orderHistory.add(
          _SimOrderHistoryEntry(
            turnNumber: currentTurn,
            playerId: playerId,
            playerName: player.displayName,
            orderType: 'diplomatic',
            summary: 'Diplomacy $typeLabel → $target$extra',
            status: validation.status,
            reason: validation.reason,
          ),
        );
      }
    }
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
      Logger().i('ctdev: Turn $turn ($year): no province ownership changes');
    } else {
      Logger().i(
        'ctdev: Turn $turn ($year): province ownership changes: ${flips.join(', ')}',
      );
    }
  }
}

