import 'package:colonizethis_app/features/game/flame/map_state/last_turn_playback_chrome.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/widgets/ct_region_map.dart';

/// Tiny region with a fixed last-turn pulse tile (Refs #4486).
RegionMapViewData lastTurnPulseStoryRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
    height: 1,
    cellSize: 64,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainTypeId: 'plains',
        terrainType: TerrainType.plains,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'Pulse',
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p2',
        isSea: false,
        terrainTypeId: 'plains',
        terrainType: TerrainType.plains,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'Quiet',
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {'gp1': (160, 120, 80)},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
  );
}

/// Isolated MAP10001 last-turn pulse chrome for Widgetbook (Refs #4486).
class LastTurnPulseStory extends StatelessWidget {
  const LastTurnPulseStory({super.key, this.narrow = false});

  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final map = CtRegionMap(
      region: lastTurnPulseStoryRegion(),
      cellSizePx: 64,
      showPoliticalOverlay: false,
      lastTurnPulseTileKey: 'oldWorld|p1|0|0',
    );
    final body = Stack(
      children: [
        Positioned.fill(child: map),
        lastTurnPlaybackChromeOverlay(
          isNarrow: narrow,
          caption: 'Pulse province battle resolved!',
          skipLabel: 'Skip',
          onSkip: () {},
        ),
      ],
    );
    if (!narrow) {
      return SizedBox(width: 420, height: 280, child: body);
    }
    return SizedBox(width: 320, height: 480, child: body);
  }
}
