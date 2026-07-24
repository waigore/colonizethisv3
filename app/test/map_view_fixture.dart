// Loader for the committed seed-42 map-view fixture (Refs #3656 / #4117 slice F).
//
// Re-exports the lib implementation so tests keep `import 'map_view_fixture.dart'`.

export 'package:colonizethis_app_fixtures/test_support/seed42_fixture_loader.dart'
    show
        kSeed42MapViewFixtureRepoPath,
        loadSeed42MapViewData,
        readSeed42MapViewFixtureJson,
        seed42MapViewFixtureFile;
