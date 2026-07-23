import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/constants.dart';
import '../features/game/widgets/shell/shell_player_context.dart';
import 'game_service_provider.dart';

part 'games_provider_current_game.dart';
part 'games_provider_work_targets.dart';
part 'games_provider_diplomacy.dart';
