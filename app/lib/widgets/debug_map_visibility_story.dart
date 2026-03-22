import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'ct_choice_chip.dart';
import 'ct_region_map.dart';
import 'debug_init_game.dart';

/// Builds InitGameMapViewData for the debug init game result, enriching it with
/// per-tile visibility derived from the first player's PlayerView. Used by map
/// Widgetbook stories to support full vs player-constrained visibility modes.
InitGameMapViewData debugMapViewDataWithVisibilityForFirstPlayer() {
  final result = getDebugInitGameResult();
  final game = result.game;
  if (game.players.isEmpty) {
    return result.mapViewData;
  }
  final playerId = game.players.first.id;
  final view = buildPlayerView(
    game,
    result.combinedTopology,
    playerId,
  );

  final visibilityByTile = <String, TileVisibility>{};
  view.visibilityByTile.forEach((tileKey, level) {
    late TileVisibility visibility;
    switch (level) {
      case VisibilityLevel.fullyVisible:
        visibility = TileVisibility.visible;
        break;
      case VisibilityLevel.fogged:
      case VisibilityLevel.revealed:
        visibility = TileVisibility.fogged;
        break;
      case VisibilityLevel.unknown:
        visibility = TileVisibility.unrevealed;
        break;
    }
    visibilityByTile[tileKey] = visibility;
  });

  final baseView = result.mapViewData;
  return buildInitGameMapViewData(
    game: game,
    tileMapByRegion: result.tileMapByRegion,
    topologyByRegion: result.topologyByRegion,
    cellSize: baseView.oldWorld.cellSize,
    seed: baseView.seed,
    configSummary: baseView.configSummary,
    greatPowerColorOverride: result.greatPowerColorOverride,
    visibilityByTile: visibilityByTile,
  );
}

/// Stateful Widgetbook story for the debug map with a visibility mode toggle.
class DebugMapVisibilityStory extends StatefulWidget {
  const DebugMapVisibilityStory({
    required this.showPoliticalOverlay,
  });

  final bool showPoliticalOverlay;

  @override
  State<DebugMapVisibilityStory> createState() =>
      _DebugMapVisibilityStoryState();
}

class _DebugMapVisibilityStoryState extends State<DebugMapVisibilityStory> {
  CtMapVisibilityMode _visibilityMode = CtMapVisibilityMode.full;
  bool _showProvinceNames = true;

  @override
  Widget build(BuildContext context) {
    final mapViewData = debugMapViewDataWithVisibilityForFirstPlayer();
    final region = mapViewData.oldWorld;

    return SizedBox(
      width: 400,
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CtChoiceChip(
                  label: const Text('Full visibility'),
                  selected: _visibilityMode == CtMapVisibilityMode.full,
                  onSelected: (_) {
                    setState(() {
                      _visibilityMode = CtMapVisibilityMode.full;
                    });
                  },
                ),
                const SizedBox(width: 8),
                CtChoiceChip(
                  label: const Text('Player-constrained'),
                  selected:
                      _visibilityMode == CtMapVisibilityMode.playerConstrained,
                  onSelected: (_) {
                    setState(() {
                      _visibilityMode = CtMapVisibilityMode.playerConstrained;
                    });
                  },
                ),
                CtChoiceChip(
                  label: const Text('Province names'),
                  selected: _showProvinceNames,
                  onSelected: (_) {
                    setState(() => _showProvinceNames = true);
                  },
                ),
                CtChoiceChip(
                  label: const Text('No province names'),
                  selected: !_showProvinceNames,
                  onSelected: (_) {
                    setState(() => _showProvinceNames = false);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: CtRegionMap(
              region: region,
              showPoliticalOverlay: widget.showPoliticalOverlay,
              cellSizePx: 28,
              visibilityMode: _visibilityMode,
              showProvinceNamesLayer: _showProvinceNames,
              onProvinceSelected: (id) {},
            ),
          ),
        ],
      ),
    );
  }
}

