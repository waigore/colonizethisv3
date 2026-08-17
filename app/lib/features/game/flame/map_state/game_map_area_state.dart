import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_map_area.dart';
import 'game_map_area_build.dart';
import 'game_map_area_build_map_stack.dart';
import 'game_map_area_build_map_stack_chrome.dart';
import 'game_map_area_build_overlays.dart';
import 'game_map_area_e2e.dart';
import 'game_map_area_events.dart';
import 'game_map_area_last_turn_playback.dart';
import 'game_map_area_lifecycle.dart';
import 'game_map_area_relocate_selection.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_turn_feed.dart';
import 'game_map_area_turn_feed_labels.dart';
import 'game_map_area_turn_feed_taps.dart';
import 'game_map_area_turn_resolution.dart';
import 'game_map_area_view.dart';

/// Stateful implementation for [GameMapArea] (Refs #4117 de-part).
class GameMapAreaState extends ConsumerState<GameMapArea>
    with
        GameMapAreaStateBase,
        GameMapAreaSelection,
        GameMapAreaRelocateSelection,
        GameMapAreaView,
        GameMapAreaTurnResolution,
        GameMapAreaTurnFeedLabels,
        GameMapAreaTurnFeedTaps,
        GameMapAreaTurnFeed,
        GameMapAreaLastTurnPlayback,
        GameMapAreaEvents,
        GameMapAreaE2e,
        GameMapAreaLifecycle,
        GameMapAreaBuildMapStackChrome,
        GameMapAreaBuildMapStack,
        GameMapAreaRelocateSelection,
        GameMapAreaBuildOverlays,
        GameMapAreaBuild {}
