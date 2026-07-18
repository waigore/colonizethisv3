// SPEC/program/game-setup-pipeline.md. Builds Game from generated maps and config.
// Map generation is done by the caller (app/colonizethis_map); this module does
// province assignment, build state, and capital auto-choice.

export 'game_setup_create.dart';
export 'game_setup_helpers.dart';
export 'game_setup_plains_conversion.dart';
export 'gp_ow_terrain_count_restore.dart';
