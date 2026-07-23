import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_fixtures/runtime/map_terrain_config.dart';
import '../features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import '../features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

part 'map_view_provider_visibility.dart';
part 'map_view_provider_extraction.dart';
part 'map_view_provider_data.dart';
