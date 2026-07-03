// Seed-42 fixture loaders shared by tests, Widgetbook, and overlay demo data.
//
// VM/desktop targets read committed JSON from `app/test/support/fixtures/`.
// Web falls back to [getDebugInitGameResult] when fixtures are not on disk.

export 'seed42_fixture_loader_vm.dart'
    if (dart.library.html) 'seed42_fixture_loader_web.dart';

export 'seed42_fixture_paths.dart';
