import 'package:colonizethis_map/colonizethis_map.dart' show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/ui_screen_ids.dart';
import 'game_map_area_state.dart';

/// Map area with region tabs and province/sea zone detail overlay.
/// SPEC/ui/province-sea-zone-detail-overlay.md.
class GameMapArea extends ConsumerStatefulWidget {
  const GameMapArea({required this.game, required this.mapViewData, super.key});

  /// SPEC/ui/empire-overview.md — [UiScreenIds.empireOverviewMapArea].
  static const screenId = UiScreenIds.empireOverviewMapArea;

  final ct_models.Game game;
  final InitGameMapViewData mapViewData;

  @override
  ConsumerState<GameMapArea> createState() => GameMapAreaState();
}
