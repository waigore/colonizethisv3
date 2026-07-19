// Load Savegame: list saved games, load and navigate to Init Game Map Debug with GP colours from save.
// SPEC/program/ctdev-app.md, SPEC/program/map-visualization.md (greatPowerColorOverride).

import 'dart:typed_data';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../save_service.dart';
import 'init_game_debug_map_screen.dart';

class LoadSavegameScreen extends StatefulWidget {
  const LoadSavegameScreen({super.key});

  @override
  State<LoadSavegameScreen> createState() => _LoadSavegameScreenState();
}

class _LoadSavegameScreenState extends State<LoadSavegameScreen> {
  List<String> _gameIds = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ids = await listGameIds();
      if (!mounted) return;
      setState(() {
        _gameIds = ids;
        _loading = false;
      });
    } catch (e, _) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onSelectGameId(String gameId) async {
    final game = await loadGame(gameId);
    if (!mounted || game == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load game')),
        );
      }
      return;
    }
    final mapData = await loadMapData(gameId);
    if (!mounted) return;
    if (mapData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Map view not available for this save (tile map data not stored).',
          ),
        ),
      );
      return;
    }
    final greatPowerColorOverride = greatPowerColorOverrideFromGame(game);
    final viewData = buildInitGameMapViewData(
      game: game,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      cellSize: 24,
      greatPowerColorOverride: greatPowerColorOverride,
    );
    final initResult = InitGameResult(
      game: game,
      mapPngBytes: Uint8List(0),
      markdown: '',
      mapViewData: viewData,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      combinedTopology: mapData.combinedTopology,
      greatPowerColorOverride: greatPowerColorOverride,
    );
    final baseSeed = game.globalGameSeed ?? 0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InitGameDebugMapScreen(
          initResult: initResult,
          baseSeed: baseSeed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Savegame'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadList,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _gameIds.isEmpty
                  ? const Center(
                      child: Text(
                        'No saved games. Run Init Game to create one (saved with map data for this app).',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _gameIds.length,
                      itemBuilder: (context, index) {
                        final id = _gameIds[index];
                        return ListTile(
                          title: Text(id),
                          onTap: () => _onSelectGameId(id),
                        );
                      },
                    ),
    );
  }
}
