import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import '../features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import '../l10n/l10n.dart';
import '../widgets/ct_choice_chip.dart';
import '../widgets/ct_region_map.dart';
import '../widgets/debug_init_game.dart';

/// Builds InitGameMapViewData for the debug init game result, enriching it with
/// per-tile visibility derived from the first player's PlayerView. Used by map
/// Widgetbook stories to support full vs player-constrained visibility modes.

/// [PlayerView] for the first great power in the debug init game; null if none.
PlayerView? debugPlayerViewForFirstPlayer() {
  final result = getDebugInitGameResult();
  final game = result.game;
  if (game.players.isEmpty) {
    return null;
  }
  final playerId = game.players.first.id;
  return buildPlayerView(game, result.combinedTopology, playerId);
}

InitGameMapViewData debugMapViewDataWithVisibilityForFirstPlayer() {
  final result = getDebugInitGameResult();
  final view = debugPlayerViewForFirstPlayer();
  if (view == null) {
    return result.mapViewData;
  }
  final game = result.game;

  final visibilityByTile = <String, TileVisibility>{};
  view.visibilityByTile.forEach((tileKey, level) {
    late TileVisibility visibility;
    switch (level) {
      case VisibilityLevel.fullyVisible:
        visibility = TileVisibility.visible;
        break;
      case VisibilityLevel.fogged:
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
    super.key,
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
    final l10n = appL10n(context);
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
                  label: Text(l10n.mapDebug_fullVisibility),
                  selected: _visibilityMode == CtMapVisibilityMode.full,
                  onSelected: (_) {
                    setState(() {
                      _visibilityMode = CtMapVisibilityMode.full;
                    });
                  },
                ),
                const SizedBox(width: 8),
                CtChoiceChip(
                  label: Text(l10n.mapDebug_playerConstrained),
                  selected:
                      _visibilityMode == CtMapVisibilityMode.playerConstrained,
                  onSelected: (_) {
                    setState(() {
                      _visibilityMode = CtMapVisibilityMode.playerConstrained;
                    });
                  },
                ),
                CtChoiceChip(
                  label: Text(l10n.map_displayOptions_showProvinceNames),
                  selected: _showProvinceNames,
                  onSelected: (_) {
                    setState(() => _showProvinceNames = true);
                  },
                ),
                CtChoiceChip(
                  label: Text(l10n.mapDebug_hideProvinceNames),
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
              playerViewForResources:
                  _visibilityMode == CtMapVisibilityMode.playerConstrained
                  ? debugPlayerViewForFirstPlayer()
                  : null,
              showProvinceNamesLayer: _showProvinceNames,
              onProvinceSelected: (id) {},
            ),
          ),
        ],
      ),
    );
  }
}
