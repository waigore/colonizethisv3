import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';

import '../save_service.dart';
import 'init_game_debug_map_screen.dart';

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
      await saveGameAndMapData(result.game, result);
      if (!mounted) return;
      final baseSeed = result.game.globalGameSeed ?? _seed;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InitGameDebugMapScreen(
            initResult: result,
            baseSeed: baseSeed,
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
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
