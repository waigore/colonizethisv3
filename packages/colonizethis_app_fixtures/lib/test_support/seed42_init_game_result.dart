// Seed-42 [InitGameResult] loaders shared by Widgetbook and debug-init helpers.
//
// VM/desktop targets assemble the result from committed JSON fixtures. Web falls
// back to the procedural generator when fixtures are not on disk.

export 'seed42_init_game_result_vm.dart'
    if (dart.library.html) 'seed42_init_game_result_web.dart';
