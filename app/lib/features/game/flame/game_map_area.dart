import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData, RegionMapViewData;
import 'package:colonizethis_app/l10n/l10n.dart';

import '../../../config/ct_e2e.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/debug_console_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/observe_session_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../../../providers/region_minimap_provider.dart';
import '../../../../providers/treasury_summary_provider.dart';
import '../shell_player_context.dart';
import 'region_map_component.dart' show BaseLayerDisplayMode;
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../providers/turn_resolution_runner_provider.dart';
import '../../../core/services/subscription_tracker.dart';
import '../../../core/services/turn_resolution_blocking_service.dart';
import '../../../core/services/turn_resolution_runner.dart';
import 'region_map_viewport_snapshot.dart';
import '../../../../providers/home_fleet_cargo_provider.dart';
import '../../../../providers/human_draft_projected_region_provider.dart';

import '../../../config/constants.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import 'game_screen_shared.dart';
import 'game_side_menu.dart';
import 'game_map_controls.dart';
import 'game_map_corner_controls.dart';
import 'game_map_empire_left_rail.dart';
import 'game_map_canvas_stack.dart';
import 'game_region_minimap.dart';
import 'game_map_narrow_detail_overlay.dart';
import 'debug_console_overlay_panel.dart';
import 'game_map_area_state_logic.dart';
import 'per_player_work_target_selection_cache.dart';
import 'next_turn_confirmation_dialog.dart';
import 'turn_resolution_processing_dialog.dart';
import 'turn_resolution_progress_labels.dart';
import 'turn_resolution_result_applier.dart';
import '../utils/map_location_resolver.dart';
import '../widgets/game_map_options_dialog.dart';
import '../widgets/game_map_players_bar.dart';
import '../widgets/player_turn_event_feed.dart';

part 'game_map_area_part1.dart';
part 'game_map_area_part1b.dart';
part 'game_map_area_part2.dart';

final _gameMapNextTurnUiLog = packageLogger('logic');

/// Map area with region tabs and province/sea zone detail overlay. SPEC/ui/province-sea-zone-detail-overlay.md.
class GameMapArea extends ConsumerStatefulWidget {
  const GameMapArea({required this.game, required this.mapViewData, super.key});

  /// SPEC/ui/empire-overview.md — [UiScreenIds.empireOverviewMapArea].
  static const screenId = UiScreenIds.empireOverviewMapArea;

  final ct_models.Game game;
  final InitGameMapViewData mapViewData;

  @override
  ConsumerState<GameMapArea> createState() => _GameMapAreaState();
}

class _GameMapAreaState extends ConsumerState<GameMapArea>
    with _GameMapAreaStatePart1, _GameMapAreaStatePart2 {}
