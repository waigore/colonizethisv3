import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;

import '../widgets/province_sea_zone_detail_overlay.dart';

/// Narrow-layout (bottom sheet) province/sea zone detail overlay.
class GameMapNarrowDetailOverlay extends StatelessWidget {
  const GameMapNarrowDetailOverlay({
    required this.game,
    required this.region,
    required this.selectedId,
    required this.displayId,
    required this.humanPlayerId,
    required this.hoveredTileKey,
    required this.onHighlightTile,
    required this.onClose,
    super.key,
  });

  final ct_models.Game game;
  final RegionMapViewData region;
  final String selectedId;
  final String displayId;
  final String humanPlayerId;
  final String? hoveredTileKey;
  final void Function(String?) onHighlightTile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.33,
      child: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: region,
        selectedId: selectedId,
        displayId: displayId,
        humanPlayerId: humanPlayerId,
        hoveredTileKey: hoveredTileKey,
        onHighlightTile: onHighlightTile,
        onClose: onClose,
      ),
    );
  }
}

